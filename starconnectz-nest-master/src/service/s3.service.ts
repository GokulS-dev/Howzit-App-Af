import { Injectable } from '@nestjs/common';
import * as AWS from 'aws-sdk';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class S3Service {
  private s3: AWS.S3;
  private bucket: string;

  constructor(private readonly configService: ConfigService) {
    this.s3 = new AWS.S3({
      accessKeyId: this.configService.get<string>('ACCESS_KEY'),
      secretAccessKey: this.configService.get<string>('SECRET_ACCESS_KEY'),
      region: this.configService.get<string>('BUCKET_REGION'),
    });

    this.bucket = this.configService.get<string>('BUCKET_NAME');
  }

  async uploadFile(file: Express.Multer.File): Promise<string> {
    const uploadResult = await this.s3
      .upload({
        Bucket: this.bucket,
        Key: Date.now() + '-' + file.originalname,
        Body: file.buffer,
        ContentType: file.mimetype,
        ACL: 'public-read',
      })
      .promise();

    return uploadResult.Location;
  }
}