import { Module } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { StockController } from './stock.controller';
import { StockService } from './service';

@Module({
  controllers: [StockController],
  providers: [StockService, PrismaService],
})
export class StockModule {}
