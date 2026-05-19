import { BadRequestException, Body, Controller, Get, Post, Query } from '@nestjs/common';
import { OrderService } from './order.service';

@Controller('orders')
export class OrderController {
  constructor(private readonly orderService: OrderService) {}

  @Post('preview')
  preview(
    @Body()
    body: {
      userId: number;
      stockId: number;
      quantity: number;
      side: 'BUY' | 'SELL';
      priceType?: 'MARKET' | 'LIMIT';
      limitPrice?: number;
    },
  ) {
    return this.orderService.preview(body);
  }

  @Post('buy')
  buy(
    @Body()
    body: {
      userId: number;
      stockId: number;
      quantity: number;
      priceType?: 'MARKET' | 'LIMIT';
      limitPrice?: number;
    },
  ) {
    return this.orderService.buy(body);
  }

  @Post('sell')
  sell(
    @Body()
    body: {
      userId: number;
      stockId: number;
      quantity: number;
      priceType?: 'MARKET' | 'LIMIT';
      limitPrice?: number;
    },
  ) {
    return this.orderService.sell(body);
  }

  @Get('history')
  getHistory(
    @Query('userId') userId?: string,
    @Query('type') type?: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    if (type && !['BUY', 'SELL'].includes(type)) {
      throw new BadRequestException('type must be BUY or SELL');
    }

    return this.orderService.getHistory({
      userId: Number(userId),
      type: type as 'BUY' | 'SELL' | undefined,
      from,
      to,
    });
  }
}
