import { Module } from '@nestjs/common';
import { MeetingController } from './meeting.controller';
import { MeetingService } from './meeting.service';
import { PrismaModule } from 'src/prisma/prisma.module';

@Module({
  controllers: [MeetingController],
  providers: [MeetingService],
  imports: [PrismaModule],
})
export class MeetingModule {}
