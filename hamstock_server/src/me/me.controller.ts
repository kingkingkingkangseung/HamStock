import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Patch,
  Query,
} from '@nestjs/common';
import { MeService } from './me.service';

@Controller('me')
export class MeController {
  constructor(private readonly meService: MeService) {}

  @Get('dashboard')
  getDashboard(@Query('userId') userId?: string) {
    const parsedUserId = Number(userId);

    if (!userId || Number.isNaN(parsedUserId) || parsedUserId <= 0) {
      throw new BadRequestException('userId must be a positive number');
    }

    return this.meService.getDashboard(parsedUserId);
  }

  @Get('ranking')
  getRanking(@Query('userId') userId?: string, @Query('limit') limit?: string) {
    const parsedUserId = userId ? Number(userId) : undefined;
    const parsedLimit = limit ? Number(limit) : undefined;

    if (
      userId &&
      (Number.isNaN(parsedUserId) || parsedUserId === undefined || parsedUserId <= 0)
    ) {
      throw new BadRequestException('userId must be a positive number');
    }

    if (
      limit &&
      (Number.isNaN(parsedLimit) || parsedLimit === undefined || parsedLimit <= 0)
    ) {
      throw new BadRequestException('limit must be a positive number');
    }

    return this.meService.getRanking(parsedUserId, parsedLimit);
  }

  @Patch('nickname')
  updateNickname(@Body() body: unknown) {
    return this.meService.updateNickname(body);
  }
}
