import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
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

  async getRanking(userId?: number, limit = 10) {
    const safeLimit = Math.min(Math.max(Math.floor(limit), 3), 50);
    const users = await this.prisma.user.findMany({
      include: {
        asset: true,
        portfolios: {
          where: { quantity: { gt: 0 } },
          include: { stock: true },
        },
      },
    });

    const ranked = users
      .map((user) => {
        const cashBalance = user.asset?.balance ?? INITIAL_BALANCE;
        const holdingsValue = user.portfolios.reduce((sum, item) => {
          return sum + item.quantity * item.stock.price;
        }, 0);
        const totalAsset = cashBalance + holdingsValue;
        const profitLoss = totalAsset - INITIAL_BALANCE;
        const returnRate = (profitLoss / INITIAL_BALANCE) * 100;

        return {
          userId: user.id,
          nickname: user.nickname,
          totalAsset,
          cashBalance,
          holdingsValue,
          holdingsCount: user.portfolios.length,
          profitLoss,
          returnRate,
          hamsterStage: this.getHamsterStage(totalAsset),
        };
      })
      .sort((a, b) => {
        if (b.returnRate !== a.returnRate) return b.returnRate - a.returnRate;
        return a.userId - b.userId;
      })
      .map((entry, index) => ({
        ...entry,
        rank: index + 1,
        isMe: userId ? entry.userId === userId : false,
      }));

    return {
      updatedAt: new Date(),
      top3: ranked.slice(0, 3),
      ranking: ranked.slice(0, safeLimit),
      myRanking: userId
        ? ranked.find((entry) => entry.userId === userId) ?? null
        : null,
    };
  }

  async updateNickname(body: unknown) {
    const payload = this.parseNicknameBody(body);
    const userId = Number(payload.userId);
    const nickname = this.validateNickname(payload.nickname);

    if (!Number.isInteger(userId) || userId <= 0) {
      throw new BadRequestException('userId must be a positive number');
    }

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('user not found');
    }

    const duplicated = await this.prisma.user.findFirst({
      where: {
        nickname,
        NOT: { id: userId },
      },
    });
    if (duplicated) {
      throw new ConflictException('already registered nickname');
    }

    try {
      const updated = await this.prisma.user.update({
        where: { id: userId },
        data: { nickname },
      });

      return {
        user: {
          id: updated.id,
          email: updated.email,
          nickname: updated.nickname,
          createdAt: updated.createdAt,
        },
      };
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException('already registered nickname');
      }
      throw error;
    }
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

  private getHamsterStage(totalAsset: number) {
    if (totalAsset < 6_000_000) return '위기';
    if (totalAsset < 9_000_000) return '노력';
    if (totalAsset < 12_000_000) return '보통';
    if (totalAsset < 16_000_000) return '여유';
    return '재벌';
  }

  private parseNicknameBody(body: unknown): { userId?: unknown; nickname?: unknown } {
    if (typeof body === 'object' && body !== null) {
      return body as { userId?: unknown; nickname?: unknown };
    }
    return {};
  }

  private validateNickname(nickname: unknown) {
    if (typeof nickname !== 'string') {
      throw new BadRequestException('nickname is required');
    }

    const normalized = nickname.trim();
    if (normalized.length < 2 || normalized.length > 12) {
      throw new BadRequestException('nickname must be 2-12 characters');
    }

    if (/[{}"'\\]/.test(normalized)) {
      throw new BadRequestException('nickname contains invalid characters');
    }

    return normalized;
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
