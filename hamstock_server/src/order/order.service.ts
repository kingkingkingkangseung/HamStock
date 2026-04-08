import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma.service';

const INITIAL_BALANCE = 10_000_000;

type OrderRequest = {
  userId: number;
  stockId: number;
  quantity: number;
};

type OrderSide = 'BUY' | 'SELL';

type PreviewRequest = {
  userId: number;
  stockId: number;
  quantity: number;
  side: OrderSide;
  priceType?: 'MARKET' | 'LIMIT';
  limitPrice?: number;
};

const BUY_FEE_RATE = 0.0035;
const SELL_FEE_RATE = 0.0035;
const SELL_TAX_RATE = 0;

@Injectable()
export class OrderService {
  constructor(private readonly prisma: PrismaService) {}

  async preview(request: PreviewRequest) {
    const { userId, stockId, quantity } = this.validateOrderRequest(request);
    const side = request.side;
    const priceType = request.priceType ?? 'MARKET';
    const limitPrice = request.limitPrice;

    if (!['BUY', 'SELL'].includes(side)) {
      throw new BadRequestException('side must be BUY or SELL');
    }

    if (!['MARKET', 'LIMIT'].includes(priceType)) {
      throw new BadRequestException('priceType must be MARKET or LIMIT');
    }

    if (priceType === 'LIMIT') {
      if (typeof limitPrice !== 'number' || !Number.isFinite(limitPrice) || limitPrice <= 0) {
        throw new BadRequestException('limitPrice must be a positive number for LIMIT orders');
      }
    }

    const stock = await this.prisma.stock.findUnique({ where: { id: stockId } });
    if (!stock) {
      throw new NotFoundException('stock not found');
    }

    const asset = await this.ensureAsset(this.prisma, userId);
    const executionPrice = priceType === 'LIMIT' ? (limitPrice as number) : stock.price;
    const grossAmount = executionPrice * quantity;
    const feeRate = side === 'BUY' ? BUY_FEE_RATE : SELL_FEE_RATE;
    const fee = grossAmount * feeRate;
    const tax = side === 'SELL' ? grossAmount * SELL_TAX_RATE : 0;

    if (side === 'BUY') {
      const totalOrderAmount = grossAmount + fee;
      const canExecute = asset.balance >= totalOrderAmount;

      return {
        side,
        stockId,
        stockName: stock.name,
        marketPrice: stock.price,
        executionPrice,
        priceType,
        limitPrice: priceType === 'LIMIT' ? limitPrice : null,
        quantity,
        grossAmount,
        feeRate,
        fee,
        taxRate: 0,
        tax,
        totalOrderAmount,
        estimatedReceiveAmount: 0,
        canExecute,
        reason: canExecute ? null : 'insufficient balance',
      };
    }

    const holding = await this.prisma.portfolio.findFirst({
      where: { userId, stockId },
    });
    const heldQuantity = holding?.quantity ?? 0;
    const canExecute = heldQuantity >= quantity;
    const estimatedReceiveAmount = grossAmount - fee - tax;
    const avgPrice = holding?.avgPrice ?? 0;
    const expectedPnL = (executionPrice - avgPrice) * quantity - fee - tax;
    const expectedReturnRate =
      avgPrice <= 0 ? 0 : (expectedPnL / (avgPrice * quantity)) * 100;

    return {
      side,
      stockId,
      stockName: stock.name,
      marketPrice: stock.price,
      executionPrice,
      priceType,
      limitPrice: priceType === 'LIMIT' ? limitPrice : null,
      quantity,
      grossAmount,
      feeRate,
      fee,
      taxRate: SELL_TAX_RATE,
      tax,
      totalOrderAmount: grossAmount,
      estimatedReceiveAmount,
      heldQuantity,
      canExecute,
      reason: canExecute ? null : 'insufficient holdings',
      expectedPnL,
      expectedReturnRate,
    };
  }

  async buy(request: OrderRequest) {
    const { userId, stockId, quantity } = this.validateOrderRequest(request);

    return this.prisma.$transaction(async (tx) => {
      const stock = await tx.stock.findUnique({ where: { id: stockId } });
      if (!stock) {
        throw new NotFoundException('stock not found');
      }

      const asset = await this.ensureAsset(tx, userId);
      const totalPrice = stock.price * quantity;

      if (asset.balance < totalPrice) {
        throw new BadRequestException('insufficient balance');
      }

      const existing = await tx.portfolio.findFirst({
        where: { userId, stockId },
      });

      if (existing) {
        const newQuantity = existing.quantity + quantity;
        const newAvgPrice =
          (existing.avgPrice * existing.quantity + stock.price * quantity) /
          newQuantity;

        await tx.portfolio.update({
          where: { id: existing.id },
          data: {
            quantity: newQuantity,
            avgPrice: newAvgPrice,
          },
        });
      } else {
        await tx.portfolio.create({
          data: {
            userId,
            stockId,
            quantity,
            avgPrice: stock.price,
          },
        });
      }

      const order = await tx.order.create({
        data: {
          userId,
          stockId,
          type: 'BUY',
          price: stock.price,
          quantity,
          totalPrice,
          status: 'FILLED',
        },
      });

      const balance = asset.balance - totalPrice;
      const totalValue = await this.calculateTotalValue(tx, userId, balance);

      await tx.asset.update({
        where: { userId },
        data: {
          balance,
          totalValue,
        },
      });

      return {
        order,
        balance,
        totalValue,
      };
    });
  }

  async sell(request: OrderRequest) {
    const { userId, stockId, quantity } = this.validateOrderRequest(request);

    return this.prisma.$transaction(async (tx) => {
      const stock = await tx.stock.findUnique({ where: { id: stockId } });
      if (!stock) {
        throw new NotFoundException('stock not found');
      }

      const asset = await this.ensureAsset(tx, userId);
      const holding = await tx.portfolio.findFirst({
        where: { userId, stockId },
      });

      if (!holding || holding.quantity < quantity) {
        throw new BadRequestException('insufficient holdings');
      }

      const totalPrice = stock.price * quantity;
      const remain = holding.quantity - quantity;

      if (remain === 0) {
        await tx.portfolio.delete({ where: { id: holding.id } });
      } else {
        await tx.portfolio.update({
          where: { id: holding.id },
          data: { quantity: remain },
        });
      }

      const order = await tx.order.create({
        data: {
          userId,
          stockId,
          type: 'SELL',
          price: stock.price,
          quantity,
          totalPrice,
          status: 'FILLED',
        },
      });

      const balance = asset.balance + totalPrice;
      const totalValue = await this.calculateTotalValue(tx, userId, balance);

      await tx.asset.update({
        where: { userId },
        data: {
          balance,
          totalValue,
        },
      });

      return {
        order,
        balance,
        totalValue,
      };
    });
  }

  async getHistory(params: {
    userId: number;
    type?: 'BUY' | 'SELL';
    from?: string;
    to?: string;
  }) {
    const { userId, type, from, to } = params;

    if (!Number.isInteger(userId) || userId <= 0) {
      throw new BadRequestException('userId must be a positive integer');
    }

    const createdAt: Prisma.DateTimeFilter = {};

    if (from) {
      const fromDate = new Date(from);
      if (Number.isNaN(fromDate.getTime())) {
        throw new BadRequestException('from must be a valid ISO date');
      }
      createdAt.gte = fromDate;
    }

    if (to) {
      const toDate = new Date(to);
      if (Number.isNaN(toDate.getTime())) {
        throw new BadRequestException('to must be a valid ISO date');
      }
      createdAt.lte = toDate;
    }

    return this.prisma.order.findMany({
      where: {
        userId,
        ...(type ? { type } : {}),
        ...(from || to ? { createdAt } : {}),
      },
      include: {
        stock: true,
      },
      orderBy: [{ createdAt: 'desc' }],
    });
  }

  private validateOrderRequest(request: OrderRequest) {
    const { userId, stockId, quantity } = request;

    if (!Number.isInteger(userId) || userId <= 0) {
      throw new BadRequestException('userId must be a positive integer');
    }

    if (!Number.isInteger(stockId) || stockId <= 0) {
      throw new BadRequestException('stockId must be a positive integer');
    }

    if (!Number.isInteger(quantity) || quantity <= 0) {
      throw new BadRequestException('quantity must be a positive integer');
    }

    return { userId, stockId, quantity };
  }

  private async ensureAsset(
    tx: Prisma.TransactionClient | PrismaService,
    userId: number,
  ) {
    const user = await tx.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('user not found');
    }

    const existing = await tx.asset.findUnique({ where: { userId } });
    if (existing) {
      return existing;
    }

    return tx.asset.create({
      data: {
        userId,
        balance: INITIAL_BALANCE,
        totalValue: INITIAL_BALANCE,
        seed: 0,
      },
    });
  }

  private async calculateTotalValue(
    tx: Prisma.TransactionClient,
    userId: number,
    balance: number,
  ) {
    const portfolios = await tx.portfolio.findMany({
      where: { userId },
      include: { stock: true },
    });

    const holdingsValue = portfolios.reduce((sum, item) => {
      return sum + item.quantity * item.stock.price;
    }, 0);

    return balance + holdingsValue;
  }
}
