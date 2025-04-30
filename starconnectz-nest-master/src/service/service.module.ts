import { Module } from '@nestjs/common';
import { ServiceController } from './service.controller';
import { ServiceService } from './service.service';
import { PrismaModule } from 'src/prisma/prisma.module';
import { S3Service } from './s3.service'; // ✅ import new S3 service
import { S3Controller } from './s3.controller'; // ✅ import new S3 controller

@Module({
  controllers: [ServiceController, S3Controller], // ✅ add S3 controller
  providers: [ServiceService, S3Service], // ✅ add S3 service
  imports: [PrismaModule],
})
export class ServiceModule {}