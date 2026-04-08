import { BadRequestException, Controller, Get, Query } from '@nestjs/common';
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
}

