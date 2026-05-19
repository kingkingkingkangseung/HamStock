import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { MeModule } from './me/me.module';
import { OrderModule } from './order/order.module';
import { QuizModule } from './quiz/quiz.module';
import { StockModule } from './stock/stock.module';

@Module({
  imports: [AuthModule, StockModule, OrderModule, MeModule, QuizModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
