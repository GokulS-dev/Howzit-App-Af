import {
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import {
  DeleteObjectCommand,
  GetObjectCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from 'src/prisma/prisma.service';
import { randomBytes } from 'crypto';
import * as sharp from 'sharp';
import { CreateMerchDto } from './dto/create-merch-dto';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

@Injectable()
export class MerchService {
  private readonly s3Client: S3Client;

  constructor(
    private prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {
    this.s3Client = new S3Client({
      credentials: {
        accessKeyId: this.configService.getOrThrow('ACCESS_KEY'),
        secretAccessKey: this.configService.getOrThrow('SECRET_ACCESS_KEY'),
      },
      region: this.configService.getOrThrow('BUCKET_REGION'),
    });
  }

  generateFileName(): string {
    const bytes = randomBytes(32);
    return bytes.toString('hex');
  }

  async resizeImage(file: Buffer): Promise<Buffer> {
    const newBuffer = await sharp(file)
      .rotate()
      .resize({ height: 1920, width: 1080, fit: 'contain' })
      .toBuffer();
    return newBuffer;
  }

  async checkIfExists(celeb_username: string): Promise<number> {
    try {
      const celeb = await this.prisma.celeb.findUnique({
        where: {
          username: celeb_username,
        },
      });
      if (celeb === null) {
        throw new NotFoundException(
          `Celeb with username ${celeb_username} not found`,
        );
      } else {
        return celeb.id;
      }
    } catch (error) {
      throw error;
    }
  }

  async savetoDB(saveObject: any) {
    try {
      return await this.prisma.merch.create({
        data: {
          description: saveObject.description,
          imagename: saveObject.imagename,
          price: parseInt(saveObject.price),
          status: saveObject.status,
          celeb_username: saveObject.celeb_username,
          celebid: saveObject.celebid,
        },
      });
    } catch (error) {
      throw error;
    }
  }

  async uploadMerch(
    createMerchDto: CreateMerchDto,
    file: Buffer,
    request: any,
  ) {
    try {
      if (request.user.username != createMerchDto.celeb_username) {
        throw new UnauthorizedException(
          'This user does not have permission to modify this resource',
        );
      }
      const celebid = await this.checkIfExists(createMerchDto.celeb_username);
      const imagename = this.generateFileName();
      const buffer = await this.resizeImage(file);
      await this.s3Client.send(
        new PutObjectCommand({
          Bucket: this.configService.getOrThrow('MERCH_BUCKET_NAME'),
          Key: imagename,
          Body: buffer,
          ContentType: 'image/jpeg',
        }),
      );
      const dbObject = {
        celebid: celebid,
        celeb_username: createMerchDto.celeb_username,
        imagename: imagename,
        description: createMerchDto.description,
        price: createMerchDto.price,
        status: createMerchDto.status,
      };
      const merch = await this.savetoDB(dbObject);
      return { message: 'Merch Created', merch };
    } catch (error) {
      throw error;
    }
  }

  async getCelebMerch(username: string) {
    try {
      await this.checkIfExists(username);
      const merch = await this.prisma.merch.findMany({
        where: {
          celeb_username: username,
        },
      });
      for (const item of merch) {
        const getObjectParams = {
          Bucket: this.configService.getOrThrow('MERCH_BUCKET_NAME'),
          Key: item.imagename,
        };
        const command = new GetObjectCommand(getObjectParams);
        const url = await getSignedUrl(this.s3Client, command, {
          expiresIn: 3600,
        });
        (item as any).imageURL = url;
      }
      merch.sort((a: any, b: any) => {
        const dateA = new Date(a);
        const dateB = new Date(b);
        return dateA.getTime() - dateB.getTime();
      });
      return { message: 'Success', merch };
    } catch (error) {
      throw error;
    }
  }

  async deleteMerch(merchid: number, request: any) {
    try {
      const merch = await this.prisma.merch.findUnique({
        where: {
          id: merchid,
        },
      });
      if (merch === null) {
        throw new NotFoundException(`Post with id ${merchid} not found`);
      }
      if (request.user.username != merch.celeb_username) {
        throw new UnauthorizedException(
          'This user does not have permission to modify this resource',
        );
      }
    } catch (error) {
      throw error;
    }
    try {
      const check = await this.prisma.merch.findUnique({
        where: {
          id: merchid,
        },
      });
      if (check === null) {
        throw new NotFoundException(`Post with id ${merchid} not found`);
      }
      const params = {
        Bucket: this.configService.getOrThrow('MERCH_BUCKET_NAME'),
        Key: check.imagename,
      };
      const command = new DeleteObjectCommand(params);
      await this.s3Client.send(command);
      await this.prisma.merch.delete({
        where: {
          id: merchid,
        },
      });
      return { message: 'Post Deleted' };
    } catch (error) {
      throw error;
    }
  }
}
