import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { CelebModule } from './celeb/celeb.module';
import { FanModule } from './fan/fan.module';
import { PrismaModule } from './prisma/prisma.module';
import { PostModule } from './post/post.module';
import { ServiceModule } from './service/service.module';
import { OrderModule } from './order/order.module';
import { ConfigModule } from '@nestjs/config';
import { MulterModule } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { AuthModule } from './auth/auth.module';
import { VideosModule } from './videos/videos.module';
import { AudiosModule } from './audios/audios.module';
import { MeetingModule } from './meeting/meeting.module';
import { MerchModule } from './merch/merch.module';

import { PasetoService } from './paseto/paseto.service';
import { KeysController } from './paseto/keys.controller';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    MulterModule.register({
      storage: memoryStorage(),
    }),
    CelebModule,
    FanModule,
    PrismaModule,
    PostModule,
    ServiceModule,
    OrderModule,
    AuthModule,
    VideosModule,
    AudiosModule,
    MeetingModule,
    MerchModule,
  ],
  controllers: [AppController, KeysController],
  providers: [AppService, PasetoService],
})
export class AppModule {}