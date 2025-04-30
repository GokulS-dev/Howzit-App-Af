import { Module } from '@nestjs/common';
import { FanController } from './fan.controller';
import { FanService } from './fan.service';
import { PrismaModule } from 'src/prisma/prisma.module';

@Module({
  controllers: [FanController],
  providers: [FanService],
  imports: [PrismaModule],
})
export class FanModule {}
