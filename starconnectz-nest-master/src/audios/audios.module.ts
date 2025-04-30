import { Module } from '@nestjs/common';
import { AudiosController } from './audios.controller';
import { AudiosService } from './audios.service';
import { PrismaModule } from 'src/prisma/prisma.module';
@Module({
  controllers: [AudiosController],
  providers: [AudiosService],
  imports: [PrismaModule],
})
export class AudiosModule {}
