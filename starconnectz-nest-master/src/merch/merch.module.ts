import { Module } from '@nestjs/common';
import { MerchController } from './merch.controller';
import { MerchService } from './merch.service';
import { PrismaModule } from 'src/prisma/prisma.module';

@Module({
  controllers: [MerchController],
  providers: [MerchService],
  imports: [PrismaModule],
})
export class MerchModule {}
