import {
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { CreateVideoDto } from './dto/create-video.dto';
import { PrismaService } from 'src/prisma/prisma.service';
import { ConfigService } from '@nestjs/config';
import {
  DeleteObjectCommand,
  GetObjectCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { randomBytes } from 'crypto';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

@Injectable()
export class VideosService {
  private readonly s3Client: S3Client;
  constructor(
    private prisma: PrismaService,
    private configService: ConfigService,
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

  async uploadVideo(
    createVideoDto: CreateVideoDto,
    file: Buffer,
    request: any,
  ) {
    if (createVideoDto.celeb_username != request.user.username) {
      throw new UnauthorizedException(
        'This user is not permitted to access this resource',
      );
    }
    const celeb = await this.prisma.celeb.findUnique({
      where: {
        username: createVideoDto.celeb_username,
      },
    });
    if (celeb === null) {
      throw new NotFoundException(
        `Celeb with username ${createVideoDto.celeb_username} not found`,
      );
    }
    const fan = await this.prisma.fan.findUnique({
      where: {
        username: createVideoDto.fan_username,
      },
    });
    if (fan === null) {
      throw new NotFoundException(
        `Fan with username ${createVideoDto.fan_username} not found`,
      );
    }
    const order = await this.prisma.order.findUnique({
      where: {
        id: parseInt(createVideoDto.orderid),
      },
    });
    if (order === null) {
      return new NotFoundException(
        `Order with id ${createVideoDto.orderid} not found`,
      );
    }
    const videoName = this.generateFileName();
    await this.s3Client.send(
      new PutObjectCommand({
        Bucket: this.configService.getOrThrow('VIDEOS_BUCKET_NAME'),
        Key: videoName,
        Body: file,
        ContentType: 'video/mp4',
      }),
    );
    const postObject = {
      filename: videoName,
      celebid: celeb.id,
      celeb_username: celeb.username,
      fanid: fan.id,
      fan_username: fan.username,
      status: 'notseen',
      description: createVideoDto.description,
    };
    try {
      await this.prisma.video.create({
        data: postObject,
      });
      await this.prisma.order.update({
        where: {
          id: parseInt(createVideoDto.orderid),
        },
        data: {
          status: 'completed',
          video_name: videoName,
        },
      });
    } catch (error) {
      console.log(error);
      throw error;
    }
    return { message: 'Video Uploaded' };
  }

  async getCelebVideos(username: string, request: any) {
    try {
      const celeb = await this.prisma.celeb.findUnique({
        where: {
          username: username,
        },
      });
      if (celeb === null) {
        throw new NotFoundException(
          `Celeb with username ${username} not found`,
        );
      }
      if (celeb.username != request.user.username) {
        throw new UnauthorizedException(
          'This user does not have permission to access this resource',
        );
      }
      const videos = await this.prisma.video.findMany({
        where: {
          celebid: celeb.id,
        },
        orderBy: {
          created_at: 'desc',
        },
      });
      for (const item of videos) {
        const getObjectParams = {
          Bucket: this.configService.getOrThrow('VIDEOS_BUCKET_NAME'),
          Key: item.filename,
        };
        const command = new GetObjectCommand(getObjectParams);
        const url = await getSignedUrl(this.s3Client, command, {
          expiresIn: 3600,
        });
        (item as any).videoURL = url;
      }
      return { message: 'Success', videos };
    } catch (error) {
      throw error;
    }
  }

  async getFanVideos(username: string, request: any) {
    try {
      const fan = await this.prisma.fan.findUnique({
        where: {
          username: username,
        },
      });
      if (fan === null) {
        throw new NotFoundException(`Fan with username ${username} not found`);
      }
      if (fan.username != request.user.username) {
        throw new UnauthorizedException(
          'This user does not have permission to access this resource',
        );
      }
      const videos = await this.prisma.video.findMany({
        where: {
          fanid: fan.id,
        },
        orderBy: {
          created_at: 'desc',
        },
      });
      for (const item of videos) {
        const getObjectParams = {
          Bucket: this.configService.getOrThrow('VIDEOS_BUCKET_NAME'),
          Key: item.filename,
        };
        const command = new GetObjectCommand(getObjectParams);
        const url = await getSignedUrl(this.s3Client, command, {
          expiresIn: 3600,
        });
        (item as any).videoURL = url;
      }
      return { message: 'Success', videos };
    } catch (error) {
      throw error;
    }
  }

  async deleteVideo(id: number, request: any) {
    try {
      const video = await this.prisma.video.findUnique({
        where: {
          id: id,
        },
      });
      if (video === null) {
        throw new NotFoundException(`Video with id ${id} not found`);
      }
      if (request.user.username != video.celeb_username) {
        throw new UnauthorizedException(
          'This user does not have permission to modify this resource',
        );
      }
      const params = {
        Bucket: this.configService.getOrThrow('VIDEOS_BUCKET_NAME'),
        Key: video.filename,
      };
      const command = new DeleteObjectCommand(params);
      await this.s3Client.send(command);
      await this.prisma.video.delete({
        where: {
          id: id,
        },
      });
    } catch (error) {
      throw error;
    }
  }
}
