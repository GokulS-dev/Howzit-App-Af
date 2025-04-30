// import { Module } from '@nestjs/common';
import { Module, Injectable } from '@nestjs/common';
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
import { ConfigService } from '@nestjs/config';

@Module({
  imports: [
    CelebModule,
    FanModule,
    PrismaModule,
    PostModule,
    ServiceModule,
    OrderModule,
    ConfigModule.forRoot({ isGlobal: true }),
    MulterModule.register({ storage: memoryStorage() }),
    AuthModule,
    VideosModule,
    AudiosModule,
    MeetingModule,
    MerchModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}

@Injectable()
export class ExampleService {
  constructor(private configService: ConfigService) {
    const accessKey = this.configService.get<string>('ACCESS_KEY');
    console.log('Access Key:', accessKey);
  }
}