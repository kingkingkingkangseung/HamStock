import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import YahooFinance from 'yahoo-finance2';
import { PrismaService } from '../prisma.service';

const yahooFinance = new YahooFinance();

type StockSortField = 'marketCap' | 'volume' | 'changeRate';
type SortOrder = 'asc' | 'desc';
type CoreMarket = 'KOSPI' | 'US';

@Injectable()
export class StockService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(StockService.name);
  private readonly updateIntervalMs = 60_000;
  private readonly perSymbolDelayMs = 1_500;
  private readonly rateLimitCooldownMs = 15 * 60_000;
  private intervalId?: NodeJS.Timeout;
  private isUpdating = false;
  private nextAllowedUpdateAt = 0;

  constructor(private readonly prisma: PrismaService) {}

  async getStocks(params?: {
    q?: string;
    sort?: StockSortField;
    order?: SortOrder;
  }) {
    const q = params?.q?.trim();
    const sort = params?.sort;
    const order: SortOrder = params?.order ?? 'desc';

    const where: Prisma.StockWhereInput | undefined = q
      ? {
          OR: [
            { name: { contains: q, mode: 'insensitive' } },
            { code: { contains: q, mode: 'insensitive' } },
          ],
        }
      : undefined;

    const orderBy: Prisma.StockOrderByWithRelationInput[] = sort
      ? [{ [sort]: order }]
      : [{ market: 'asc' }, { code: 'asc' }];

    return this.prisma.stock.findMany({
      where,
      orderBy,
    });
  }

  async getCoreStocks(params?: { market?: CoreMarket; limit?: number }) {
    const market = params?.market;
    const limit = params?.limit ?? 50;

    const universe = await this.prisma.watchUniverse.findMany({
      where: {
        enabled: true,
        ...(market ? { market } : {}),
      },
      orderBy: [{ priority: 'asc' }, { id: 'asc' }],
      take: limit,
    });

    if (universe.length === 0) {
      return [];
    }

    const stockRows = await this.prisma.stock.findMany({
      where: {
        OR: universe.map((u) => ({ code: u.code, market: u.market })),
      },
    });

    const stockMap = new Map(
      stockRows.map((s) => [`${s.market}:${s.code}`, s] as const),
    );

    return universe.map((u) => {
      const stock = stockMap.get(`${u.market}:${u.code}`);
      return {
        id: stock?.id ?? null,
        name: u.name,
        code: u.code,
        market: u.market,
        price: stock?.price ?? 0,
        changeRate: stock?.changeRate ?? 0,
        marketCap: stock?.marketCap ?? 0,
        volume: stock?.volume ?? 0,
        updatedAt: stock?.updatedAt ?? null,
        enabled: u.enabled,
        priority: u.priority,
      };
    });
  }

  async searchCoreStocks(params: {
    q: string;
    market?: CoreMarket;
    limit?: number;
  }) {
    const q = params.q.trim();
    const market = params.market;
    const limit = params.limit ?? 30;

    const universe = await this.prisma.watchUniverse.findMany({
      where: {
        enabled: true,
        ...(market ? { market } : {}),
        OR: [
          { name: { contains: q, mode: 'insensitive' } },
          { code: { contains: q, mode: 'insensitive' } },
        ],
      },
      orderBy: [{ priority: 'asc' }, { id: 'asc' }],
      take: limit,
    });

    if (universe.length === 0) {
      return [];
    }

    const stockRows = await this.prisma.stock.findMany({
      where: {
        OR: universe.map((u) => ({ code: u.code, market: u.market })),
      },
    });

    const stockMap = new Map(
      stockRows.map((s) => [`${s.market}:${s.code}`, s] as const),
    );

    return universe.map((u) => {
      const stock = stockMap.get(`${u.market}:${u.code}`);
      return {
        id: stock?.id ?? null,
        name: u.name,
        code: u.code,
        market: u.market,
        price: stock?.price ?? 0,
        changeRate: stock?.changeRate ?? 0,
        marketCap: stock?.marketCap ?? 0,
        volume: stock?.volume ?? 0,
        updatedAt: stock?.updatedAt ?? null,
        enabled: u.enabled,
        priority: u.priority,
      };
    });
  }

  async getHoldings(userId: number) {
    return this.prisma.portfolio.findMany({
      where: {
        userId,
        quantity: { gt: 0 },
      },
      include: {
        stock: true,
      },
      orderBy: [{ updatedAt: 'desc' }],
    });
  }

  async updateStocks() {
    const now = Date.now();
    if (now < this.nextAllowedUpdateAt) {
      return;
    }

    if (this.isUpdating) {
      return;
    }

    this.isUpdating = true;

    const watchList = await this.prisma.watchUniverse.findMany({
      where: { enabled: true },
      orderBy: [{ priority: 'asc' }, { id: 'asc' }],
    });

    try {
      for (const item of watchList) {
        try {
          let stock = await this.prisma.stock.findFirst({
            where: { code: item.code, market: item.market },
          });

          if (!stock) {
            stock = await this.prisma.stock.create({
              data: {
                name: item.name,
                code: item.code,
                market: item.market,
                price: 0,
                changeRate: 0,
                marketCap: 0,
                volume: 0,
              },
            });
          }

          const symbol =
            item.market === 'KOSPI' ? `${item.code}.KS` : item.code;
          const data = (await yahooFinance.quote(symbol)) as {
            regularMarketPrice?: number;
            regularMarketChangePercent?: number;
            regularMarketVolume?: number;
            marketCap?: number;
          };

          await this.prisma.stock.update({
            where: { id: stock.id },
            data: {
              name: item.name,
              price: data.regularMarketPrice ?? stock.price,
              changeRate: data.regularMarketChangePercent ?? stock.changeRate,
              volume: data.regularMarketVolume ?? stock.volume,
              marketCap: data.marketCap ?? stock.marketCap,
              updatedAt: new Date(),
            },
          });

          await this.sleep(this.perSymbolDelayMs);
        } catch (e) {
          const message = e instanceof Error ? e.message : String(e);
          this.logger.warn(`${item.name}(${item.code}) price update failed: ${message}`);

          if (
            message.toLowerCase().includes('too many requests') ||
            message.includes('429')
          ) {
            this.nextAllowedUpdateAt = Date.now() + this.rateLimitCooldownMs;
            this.logger.warn(
              `Rate limit detected. Cooling down until ${new Date(this.nextAllowedUpdateAt).toISOString()}`,
            );
            break;
          }
        }
      }
    } finally {
      this.isUpdating = false;
    }
  }

  async onModuleInit() {
    await this.updateStocks();

    this.intervalId = setInterval(() => {
      void this.updateStocks();
    }, this.updateIntervalMs);
  }

  onModuleDestroy() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }
  }

  private sleep(ms: number) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}
