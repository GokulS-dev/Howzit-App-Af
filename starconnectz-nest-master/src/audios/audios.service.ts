import {
  Injectable,
  NotFoundException,
  UnauthorizedException,
  UnsupportedMediaTypeException,
} from '@nestjs/common';
import { CreateAudioDto } from './dto/create-audio.dto';
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
export class AudiosService {
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

  verifyFileType(type: string): Boolean {
    if (type === 'audio/mp4' || type === 'audio/mpeg') {
      return true;
    }
    return false;
  }

  async uploadAudio(
    createAudioDto: CreateAudioDto,
    file: Buffer,
    request: any,
    Mainfile: any,
  ) {
    if (createAudioDto.celeb_username != request.user.username) {
      throw new UnauthorizedException(
        'This user is not permitted to access this resource',
      );
    }
    const checkFileType = this.verifyFileType(Mainfile.mimetype);
    if (!checkFileType) {
      throw new UnsupportedMediaTypeException(
        `File type ${Mainfile.mimetype} is not supported. Only mp3 and m4a files are allowed`,
      );
    }
    const celeb = await this.prisma.celeb.findUnique({
      where: {
        username: createAudioDto.celeb_username,
      },
    });
    if (celeb === null) {
      throw new NotFoundException(
        `Celeb with username ${createAudioDto.celeb_username} not found`,
      );
    }
    const fan = await this.prisma.fan.findUnique({
      where: {
        username: createAudioDto.fan_username,
      },
    });
    if (fan === null) {
      throw new NotFoundException(
        `Fan with username ${createAudioDto.fan_username} not found`,
      );
    }
    const order = await this.prisma.order.findUnique({
      where: {
        id: parseInt(createAudioDto.orderid),
      },
    });
    if (order === null) {
      throw new NotFoundException(
        `Order with id ${createAudioDto.orderid} not found`,
      );
    }
    const audioName = this.generateFileName();
    await this.s3Client.send(
      new PutObjectCommand({
        Bucket: this.configService.getOrThrow('AUDIOS_BUCKET_NAME'),
        Key: audioName,
        Body: file,
        ContentType: 'video/mp4',
      }),
    );
    const postObject = {
      filename: audioName,
      celebid: celeb.id,
      celeb_username: celeb.username,
      fanid: fan.id,
      fan_username: fan.username,
      status: 'notseen',
      description: createAudioDto.description,
    };
    try {
      await this.prisma.audio.create({
        data: postObject,
      });
      await this.prisma.order.update({
        where: {
          id: parseInt(createAudioDto.orderid),
        },
        data: {
          audio_name: audioName,
          status: 'completed',
        },
      });
    } catch (error) {
      console.log(error);
      throw error;
    }
    return { message: 'Audio Uploaded' };
  }

  async getCelebAudios(username: string, request: any) {
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
      const audios = await this.prisma.audio.findMany({
        where: {
          celebid: celeb.id,
        },
        orderBy: {
          created_at: 'desc',
        },
      });
      for (const item of audios) {
        const getObjectParams = {
          Bucket: this.configService.getOrThrow('AUDIOS_BUCKET_NAME'),
          Key: item.filename,
        };
        const command = new GetObjectCommand(getObjectParams);
        const url = await getSignedUrl(this.s3Client, command, {
          expiresIn: 3600,
        });
        (item as any).audioURL = url;
      }
      return { message: 'Success', audios };
    } catch (error) {
      throw error;
    }
  }

  async getFanAudios(username: string, request: any) {
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
      const audios = await this.prisma.audio.findMany({
        where: {
          fanid: fan.id,
        },
        orderBy: {
          created_at: 'desc',
        },
      });
      for (const item of audios) {
        const getObjectParams = {
          Bucket: this.configService.getOrThrow('AUDIOS_BUCKET_NAME'),
          Key: item.filename,
        };
        const command = new GetObjectCommand(getObjectParams);
        const url = await getSignedUrl(this.s3Client, command, {
          expiresIn: 3600,
        });
        (item as any).audioURL = url;
      }
      return { message: 'Success', audios };
    } catch (error) {
      throw error;
    }
  }

  async deleteAudio(id: number, request: any) {
    try {
      const audio = await this.prisma.audio.findUnique({
        where: {
          id: id,
        },
      });
      if (audio === null) {
        throw new NotFoundException(`Audio with id ${id} not found`);
      }
      if (request.user.username != audio.celeb_username) {
        throw new UnauthorizedException(
          'This user does not have access to modify this resource',
        );
      }
      const params = {
        Bucket: this.configService.getOrThrow('AUDIOS_BUCKET_NAME'),
        Key: audio.filename,
      };
      const command = new DeleteObjectCommand(params);
      await this.s3Client.send(command);
      await this.prisma.audio.delete({
        where: {
          id: id,
        },
      });
      return { message: 'Deleted Successfully' };
    } catch (error) {
      throw error;
    }
  }
}
