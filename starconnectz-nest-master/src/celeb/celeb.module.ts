import { Module } from '@nestjs/common';
import { CelebController } from './celeb.controller';
import { CelebService } from './celeb.service';
import { PrismaModule } from 'src/prisma/prisma.module';

@Module({
  controllers: [CelebController],
  providers: [CelebService],
  imports: [PrismaModule],
})
export class CelebModule {}
