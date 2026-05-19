import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { QuizService } from './quiz.service';

@Controller('quiz')
export class QuizController {
  constructor(private readonly quizService: QuizService) {}

  @Get('random')
  getRandom(@Query('userId') userId?: string) {
    return this.quizService.getRandom(userId);
  }

  @Post('answer')
  answer(@Body() body: unknown) {
    return this.quizService.answer(body);
  }

  @Post('exchange')
  exchange(@Body() body: unknown) {
    return this.quizService.exchange(body);
  }
}
