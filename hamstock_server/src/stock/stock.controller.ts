import { BadRequestException, Controller, Get, Query } from '@nestjs/common';
import { StockService } from './service';

type StockSortField = 'marketCap' | 'volume' | 'changeRate';
type SortOrder = 'asc' | 'desc';
type CoreMarket = 'KOSPI' | 'US';

@Controller('stocks')
export class StockController {
  constructor(private readonly stockService: StockService) {}

  @Get('core')
  getCoreStocks(
    @Query('market') market?: string,
    @Query('limit') limit?: string,
  ) {
    if (market && !['KOSPI', 'US'].includes(market)) {
      throw new BadRequestException('market must be one of: KOSPI, US');
    }

    const parsedLimit = limit ? Number(limit) : undefined;
    if (parsedLimit !== undefined && (!Number.isInteger(parsedLimit) || parsedLimit <= 0)) {
      throw new BadRequestException('limit must be a positive integer');
    }

    return this.stockService.getCoreStocks({
      market: market as CoreMarket | undefined,
      limit: parsedLimit,
    });
  }

  @Get('search')
  searchCoreStocks(
    @Query('q') q?: string,
    @Query('market') market?: string,
    @Query('limit') limit?: string,
  ) {
    if (!q || q.trim() === '') {
      throw new BadRequestException('q is required');
    }

    if (market && !['KOSPI', 'US'].includes(market)) {
      throw new BadRequestException('market must be one of: KOSPI, US');
    }

    const parsedLimit = limit ? Number(limit) : undefined;
    if (parsedLimit !== undefined && (!Number.isInteger(parsedLimit) || parsedLimit <= 0)) {
      throw new BadRequestException('limit must be a positive integer');
    }

    return this.stockService.searchCoreStocks({
      q,
      market: market as CoreMarket | undefined,
      limit: parsedLimit,
    });
  }

  @Get()
  getStocks(
    @Query('q') q?: string,
    @Query('sort') sort?: string,
    @Query('order') order?: string,
  ) {
    if (sort && !['marketCap', 'volume', 'changeRate'].includes(sort)) {
      throw new BadRequestException(
        'sort must be one of: marketCap, volume, changeRate',
      );
    }

    if (order && !['asc', 'desc'].includes(order)) {
      throw new BadRequestException('order must be one of: asc, desc');
    }

    return this.stockService.getStocks({
      q,
      sort: sort as StockSortField | undefined,
      order: order as SortOrder | undefined,
    });
  }

  @Get('holdings')
  getHoldings(@Query('userId') userId?: string) {
    const parsedUserId = Number(userId);

    if (!userId || Number.isNaN(parsedUserId) || parsedUserId <= 0) {
      throw new BadRequestException('userId must be a positive number');
    }

    return this.stockService.getHoldings(parsedUserId);
  }
}
