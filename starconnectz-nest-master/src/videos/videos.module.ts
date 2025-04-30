import { Module } from '@nestjs/common';
import { VideosController } from './videos.controller';
import { VideosService } from './videos.service';
import { PrismaModule } from 'src/prisma/prisma.module';

@Module({
  controllers: [VideosController],
  providers: [VideosService],
  imports: [PrismaModule],
})
export class VideosModule {}
