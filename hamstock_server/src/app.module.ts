import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { MeModule } from './me/me.module';
import { OrderModule } from './order/order.module';
import { StockModule } from './stock/stock.module';

@Module({
  imports: [StockModule, OrderModule, MeModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
