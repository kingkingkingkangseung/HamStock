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
type ChartRange = '1D' | '1W' | '3M' | '1Y';

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
    const holdings = await this.prisma.portfolio.findMany({
      where: {
        userId,
        quantity: { gt: 0 },
      },
      include: {
        stock: true,
      },
      orderBy: [{ updatedAt: 'desc' }],
    });

    return holdings.map((holding) => {
      const evaluationAmount = holding.quantity * holding.stock.price;
      const purchaseAmount = holding.quantity * holding.avgPrice;
      const profitLoss = evaluationAmount - purchaseAmount;
      const returnRate =
        purchaseAmount === 0 ? 0 : (profitLoss / purchaseAmount) * 100;

      return {
        id: holding.stock.id,
        portfolioId: holding.id,
        name: holding.stock.name,
        code: holding.stock.code,
        market: holding.stock.market,
        price: holding.stock.price,
        changeRate: holding.stock.changeRate,
        marketCap: holding.stock.marketCap,
        volume: holding.stock.volume,
        updatedAt: holding.stock.updatedAt,
        quantity: holding.quantity,
        avgPrice: holding.avgPrice,
        purchaseAmount,
        evaluationAmount,
        profitLoss,
        returnRate,
      };
    });
  }

  async getChart(params: {
    code: string;
    market: string;
    range: ChartRange;
  }) {
    const code = params.code.trim();
    const market = params.market.trim().toUpperCase();
    const symbol = this.toYahooSymbol(code, market);
    const now = new Date();

    const config = this.getChartRangeConfig(params.range, now);
    const result = (await yahooFinance.chart(symbol, {
      period1: config.period1,
      period2: now,
      interval: config.interval,
      return: 'array',
      includePrePost: false,
    })) as {
      meta?: {
        regularMarketPrice?: number;
        previousClose?: number;
        currency?: string;
      };
      quotes?: Array<{
        date?: Date;
        close?: number | null;
        high?: number | null;
        low?: number | null;
        open?: number | null;
        volume?: number | null;
      }>;
    };

    const rawQuotes = (result.quotes ?? [])
      .filter((quote) => quote.date && typeof quote.close === 'number')
      .map((quote) => ({
        timestamp: quote.date!.toISOString(),
        close: Number(quote.close),
        open: quote.open ?? null,
        high: quote.high ?? null,
        low: quote.low ?? null,
        volume: quote.volume ?? null,
      }));

    let quotes = rawQuotes;

    if (params.range === '1D' && rawQuotes.length > 0) {
      const latestDay = rawQuotes[rawQuotes.length - 1].timestamp.slice(0, 10);
      const filtered = rawQuotes.filter((quote) =>
        quote.timestamp.startsWith(latestDay),
      );
      if (filtered.length > 0) {
        quotes = filtered;
      }
    }

    const closes = quotes.map((quote) => quote.close);
    const currentPrice =
      typeof result.meta?.regularMarketPrice === 'number'
        ? result.meta.regularMarketPrice
        : closes.length > 0
          ? closes[closes.length - 1]
          : 0;
    const previousClose =
      typeof result.meta?.previousClose === 'number'
        ? result.meta.previousClose
        : closes.length > 0
          ? closes[0]
          : 0;

    return {
      symbol,
      code,
      market,
      range: params.range,
      interval: config.interval,
      currency: result.meta?.currency ?? (market === 'US' ? 'USD' : 'KRW'),
      currentPrice,
      previousClose,
      minClose: closes.length === 0 ? 0 : closes.reduce((a, b) => a < b ? a : b),
      maxClose: closes.length === 0 ? 0 : closes.reduce((a, b) => a > b ? a : b),
      points: quotes,
    };
  }

  async getStockDetail(params: { code: string; market: CoreMarket }) {
    const code = params.code.trim();
    const market = params.market.trim().toUpperCase() as CoreMarket;
    const symbol = this.toYahooSymbol(code, market);
    const stock = await this.prisma.stock.findFirst({
      where: { code, market },
    });

    let summary: any = {};
    try {
      summary = (await yahooFinance.quoteSummary(symbol, {
        modules: [
          'assetProfile',
          'summaryDetail',
          'defaultKeyStatistics',
          'financialData',
          'price',
        ],
      })) as any;
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      this.logger.warn(`${symbol} detail summary failed: ${message}`);
    }

    const searchQuery = stock?.name?.trim() || code;
    let search: any = {};
    try {
      search = (await yahooFinance.search(searchQuery, {
        newsCount: 6,
        quotesCount: 0,
        enableFuzzyQuery: false,
      })) as any;
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      this.logger.warn(`${symbol} news search failed: ${message}`);
    }

    const assetProfile = summary?.assetProfile ?? {};
    const summaryDetail = summary?.summaryDetail ?? {};
    const defaultKeyStatistics = summary?.defaultKeyStatistics ?? {};
    const financialData = summary?.financialData ?? {};
    const price = summary?.price ?? {};

    let chart3m: Awaited<ReturnType<StockService['getChart']>>;
    try {
      chart3m = await this.getChart({ code, market, range: '3M' });
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      this.logger.warn(`${symbol} detail chart failed: ${message}`);
      chart3m = {
        symbol,
        code,
        market,
        range: '3M',
        interval: '1d',
        currency: market === 'US' ? 'USD' : 'KRW',
        currentPrice: stock?.price ?? 0,
        previousClose: stock?.price ?? 0,
        minClose: stock?.price ?? 0,
        maxClose: stock?.price ?? 0,
        points: [],
      };
    }
    const currentPrice =
      this.pickNumber(
        price?.regularMarketPrice,
        stock?.price,
        chart3m.currentPrice,
      ) ?? 0;
    const previousClose =
      this.pickNumber(
        price?.regularMarketPreviousClose,
        chart3m.previousClose,
      ) ?? 0;
    const priceDiff = currentPrice - previousClose;
    const changeRate =
      previousClose === 0
        ? (this.pickNumber(stock?.changeRate) ?? 0)
        : (priceDiff / previousClose) * 100;
    const chartPoints = Array.isArray(chart3m.points) ? chart3m.points : [];
    const first3mClose =
      chartPoints.length > 0
        ? this.pickNumber(chartPoints[0]?.close) ?? currentPrice
        : currentPrice;
    const change3mAmount = currentPrice - first3mClose;
    const change3mRate =
      first3mClose === 0 ? 0 : (change3mAmount / first3mClose) * 100;

    const news = Array.isArray(search?.news)
      ? search.news.slice(0, 6).map((item: any) => ({
          title: item?.title ?? '',
          publisher:
            item?.publisher ??
            item?.providerPublishTime ??
            item?.publisherName ??
            'Yahoo Finance',
          publishedAt: this.toIsoString(
            item?.providerPublishTime ??
              item?.pubDate ??
              item?.publishedAt ??
              item?.displayTime,
          ),
          link:
            item?.link ??
            item?.canonicalUrl?.url ??
            item?.clickThroughUrl?.url ??
            null,
        }))
      : [];

    return {
      company: {
        name: stock?.name ?? code,
        code,
        market,
        symbol,
        currency: chart3m.currency,
        exchange:
          price?.exchangeName ??
          price?.fullExchangeName ??
          (market === 'US' ? 'NASDAQ/NYSE' : 'KOSPI'),
        website: assetProfile?.website ?? null,
        sector: assetProfile?.sector ?? null,
        industry: assetProfile?.industry ?? null,
        employees: this.pickNumber(assetProfile?.fullTimeEmployees) ?? null,
        longBusinessSummary: assetProfile?.longBusinessSummary ?? null,
      },
      metrics: {
        currentPrice,
        previousClose,
        priceDiff,
        changeRate,
        marketCap:
          this.pickNumber(
            summaryDetail?.marketCap,
            price?.marketCap,
            stock?.marketCap,
          ) ?? 0,
        trailingPE:
          this.pickNumber(
            summaryDetail?.trailingPE,
            defaultKeyStatistics?.trailingPE,
          ) ?? null,
        priceToBook:
          this.pickNumber(
            defaultKeyStatistics?.priceToBook,
            summaryDetail?.priceToBook,
          ) ?? null,
        eps:
          this.pickNumber(
            defaultKeyStatistics?.trailingEps,
            defaultKeyStatistics?.forwardEps,
          ) ?? null,
        dividendYield:
          this.pickNumber(summaryDetail?.dividendYield) ?? null,
        dayHigh:
          this.pickNumber(
            summaryDetail?.dayHigh,
            price?.regularMarketDayHigh,
          ) ?? null,
        dayLow:
          this.pickNumber(
            summaryDetail?.dayLow,
            price?.regularMarketDayLow,
          ) ?? null,
        fiftyTwoWeekHigh:
          this.pickNumber(summaryDetail?.fiftyTwoWeekHigh) ?? null,
        fiftyTwoWeekLow:
          this.pickNumber(summaryDetail?.fiftyTwoWeekLow) ?? null,
        volume:
          this.pickNumber(
            summaryDetail?.volume,
            price?.regularMarketVolume,
            stock?.volume,
          ) ?? 0,
      },
      detail: {
        overview: this.buildOverviewText({
          market,
          name: stock?.name ?? code,
          sector: assetProfile?.sector,
          industry: assetProfile?.industry,
          summary: assetProfile?.longBusinessSummary,
        }),
        recentMoveTitle:
          changeRate >= 0 ? '최근 주가 상승 배경' : '최근 주가 조정 배경',
        recentMoveBullets: this.buildRecentMoveBullets({
          currentPrice,
          previousClose,
          changeRate,
          min3m: chart3m.minClose,
          max3m: chart3m.maxClose,
          change3mRate,
          volume:
            this.pickNumber(
              summaryDetail?.volume,
              price?.regularMarketVolume,
              stock?.volume,
            ) ?? 0,
          market,
        }),
        news,
      },
    };
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

  private toYahooSymbol(code: string, market: string) {
    return market === 'KOSPI' ? `${code}.KS` : code;
  }

  private pickNumber(...values: unknown[]) {
    for (const value of values) {
      if (typeof value === 'number' && Number.isFinite(value)) {
        return value;
      }

      if (
        value &&
        typeof value === 'object' &&
        'raw' in value &&
        typeof (value as { raw?: unknown }).raw === 'number'
      ) {
        const raw = (value as { raw: number }).raw;
        if (Number.isFinite(raw)) {
          return raw;
        }
      }
    }

    return null;
  }

  private toIsoString(value: unknown) {
    if (!value) return null;

    if (typeof value === 'number') {
      return new Date(value * 1000).toISOString();
    }

    if (typeof value === 'string') {
      const date = new Date(value);
      return Number.isNaN(date.getTime()) ? null : date.toISOString();
    }

    return null;
  }

  private buildOverviewText(params: {
    market: CoreMarket;
    name: string;
    sector?: string | null;
    industry?: string | null;
    summary?: string | null;
  }) {
    if (params.summary && params.summary.trim() !== '') {
      return params.summary.trim();
    }

    const marketLabel = params.market === 'US' ? '미국' : '국내';
    const sector = params.sector ? `${params.sector} 섹터` : marketLabel;
    const industry = params.industry ? `${params.industry} 기업` : '상장 기업';

    return `${params.name}는 ${sector}에 속한 ${industry}입니다. 현재 서비스에서는 Yahoo Finance 기반 시세와 핵심 지표를 제공하며, 추가 기업 설명은 추후 보강할 예정입니다.`;
  }

  private buildRecentMoveBullets(params: {
    currentPrice: number;
    previousClose: number;
    changeRate: number;
    min3m: number;
    max3m: number;
    change3mRate: number;
    volume: number;
    market: CoreMarket;
  }) {
    const bullets: string[] = [];
    const nearHigh =
      params.max3m > 0 && params.currentPrice >= params.max3m * 0.94;
    const nearLow =
      params.min3m > 0 && params.currentPrice <= params.min3m * 1.06;

    bullets.push(
      `전일 대비 ${params.changeRate >= 0 ? '상승' : '하락'} 폭은 ${params.changeRate.toFixed(2)}%입니다.`,
    );

    bullets.push(
      `최근 3개월 기준 누적 수익률은 ${params.change3mRate >= 0 ? '+' : ''}${params.change3mRate.toFixed(2)}%입니다.`,
    );

    if (nearHigh) {
      bullets.push('현재 가격이 최근 3개월 고점권에 근접해 있습니다.');
    } else if (nearLow) {
      bullets.push('현재 가격이 최근 3개월 저점권 부근에서 움직이고 있습니다.');
    } else {
      bullets.push('최근 3개월 밴드 중간 구간에서 등락을 반복하고 있습니다.');
    }

    if (params.volume > 0) {
      const unit = params.market === 'US' ? '주' : '주';
      bullets.push(`최근 거래량은 약 ${Math.round(params.volume).toLocaleString()}${unit} 수준입니다.`);
    }

    return bullets.slice(0, 4);
  }

  private getChartRangeConfig(range: ChartRange, now: Date) {
    switch (range) {
      case '1D':
        return {
          period1: new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000),
          interval: '15m' as const,
        };
      case '1W':
        return {
          period1: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000),
          interval: '1h' as const,
        };
      case '1Y':
        return {
          period1: new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000),
          interval: '1wk' as const,
        };
      case '3M':
      default:
        return {
          period1: new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000),
          interval: '1d' as const,
        };
    }
  }
}
