import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Req,
  UseGuards,
  ValidationPipe,
} from '@nestjs/common';
import { MeetingService } from './meeting.service';
import { CreateMeetingDto } from './dto/create-meeting.dto';
import { AuthGuard } from 'src/auth/auth.guard';
import { Request } from 'express';
import { UpdateMeetingDto } from './dto/update-meeting.dto';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

@Controller('meeting')
@ApiTags('Meeting')
export class MeetingController {
  constructor(private meetingService: MeetingService) {}

  @UseGuards(AuthGuard)
  @Post()
  @ApiOperation({ summary: 'Create a new meeting' }) // Added summary
  async createMeeting(
    @Body(ValidationPipe) createMeetingDto: CreateMeetingDto,
    @Req() request: Request,
  ) {
    return await this.meetingService.createMeeting(createMeetingDto, request);
  }

  @UseGuards(AuthGuard)
  @Get('getMeeting/:orderid')
  @ApiOperation({ summary: 'Get meeting details by order ID' }) // Added summary
  async getPending(
    @Param('orderid', ParseIntPipe) orderid: number,
    @Req() request: Request,
  ) {
    return await this.meetingService.getMeeting(orderid, request);
  }
}
