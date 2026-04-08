import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma.service';

const INITIAL_BALANCE = 10_000_000;

@Injectable()
export class MeService {
  constructor(private readonly prisma: PrismaService) {}

  async getDashboard(userId: number) {
    return this.prisma.$transaction(async (tx) => {
      const user = await tx.user.findUnique({ where: { id: userId } });
      if (!user) {
        throw new NotFoundException('user not found');
      }

      const asset = await this.ensureAsset(tx, userId);
      const holdings = await tx.portfolio.findMany({
        where: {
          userId,
          quantity: { gt: 0 },
        },
        include: { stock: true },
      });

      const holdingsCount = holdings.length;

      const totalPurchaseAmount = holdings.reduce((sum, item) => {
        return sum + item.quantity * item.avgPrice;
      }, 0);

      const holdingsValue = holdings.reduce((sum, item) => {
        return sum + item.quantity * item.stock.price;
      }, 0);

      const totalAsset = asset.balance + holdingsValue;
      const evaluationProfitLoss = holdingsValue - totalPurchaseAmount;
      const totalProfitLoss = totalAsset - INITIAL_BALANCE;
      const returnRate = (totalProfitLoss / INITIAL_BALANCE) * 100;

      if (asset.totalValue !== totalAsset) {
        await tx.asset.update({
          where: { userId },
          data: { totalValue: totalAsset },
        });
      }

      return {
        userId,
        totalAsset,
        evaluationProfitLoss,
        returnRate,
        holdingsCount,
        cashBalance: asset.balance,
        seed: asset.seed,
        holdingsValue,
        totalPurchaseAmount,
        totalProfitLoss,
      };
    });
  }

  private async ensureAsset(tx: Prisma.TransactionClient, userId: number) {
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
}
