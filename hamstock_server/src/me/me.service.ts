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
      const volatility = this.calculateVolatility(holdings);
      const mdd = returnRate < 0 ? returnRate : 0;
      const volatilityLabel = this.getVolatilityLabel(volatility);
      const stabilityLabel = this.getStabilityLabel(returnRate, volatility);
      const hamsterMessage = this.getHamsterMessage({
        holdingsCount,
        returnRate,
        volatility,
      });

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
        mdd,
        volatility,
        volatilityLabel,
        stabilityLabel,
        hamsterMessage,
      };
    });
  }

  private calculateVolatility(
    holdings: Array<{ quantity: number; stock: { price: number; changeRate: number } }>,
  ) {
    const totalValue = holdings.reduce((sum, item) => {
      return sum + item.quantity * item.stock.price;
    }, 0);

    if (totalValue <= 0) {
      return 0;
    }

    return holdings.reduce((sum, item) => {
      const weight = (item.quantity * item.stock.price) / totalValue;
      return sum + Math.abs(item.stock.changeRate) * weight;
    }, 0);
  }

  private getVolatilityLabel(volatility: number) {
    if (volatility < 2) return '낮음';
    if (volatility < 5) return '보통';
    return '높음';
  }

  private getStabilityLabel(returnRate: number, volatility: number) {
    if (returnRate >= 0 && volatility < 5) return '양호';
    if (returnRate < -10 || volatility >= 7) return '주의';
    return '보통';
  }

  private getHamsterMessage(params: {
    holdingsCount: number;
    returnRate: number;
    volatility: number;
  }) {
    if (params.holdingsCount === 0) {
      return '아직 보유 종목이 없어. 첫 종목을 골라보자.';
    }

    if (params.returnRate > 3) {
      return '수익이 커지고 있어. 분산은 계속 챙기자.';
    }

    if (params.returnRate < -3) {
      return '손실 구간이야. 무리한 추격매수는 조심하자.';
    }

    if (params.volatility >= 5) {
      return '변동성이 커. 주문 전 리스크를 확인하자.';
    }

    return '포트폴리오가 안정적으로 유지 중이야.';
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
