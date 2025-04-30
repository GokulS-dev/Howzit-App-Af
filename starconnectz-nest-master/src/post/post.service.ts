import {
  DeleteObjectCommand,
  GetObjectCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import {
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CreatePostDto } from './dto/create-post.dto';
import { PrismaService } from 'src/prisma/prisma.service';
import { randomBytes } from 'crypto';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import * as sharp from 'sharp';
import { DeletePostDto } from './dto/delete-post.dto';

@Injectable()
export class PostService {
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

  async createPost(postObeject: {
    celebid: number;
    celeb_username: string;
    imagename: string;
    caption: string;
  }) {
    try {
      return await this.prisma.post.create({
        data: {
          celebid: postObeject.celebid,
          celeb_username: postObeject.celeb_username,
          imagename: postObeject.imagename,
          caption: postObeject.caption,
        },
      });
    } catch (error) {
      throw error;
    }
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

  async upload(createPostDto: CreatePostDto, file: Buffer, request: any) {
    try {
      if (request.user.username != createPostDto.celeb_username) {
        throw new UnauthorizedException(
          'This user does not have permission to access this resource',
        );
      }
      const celebid = await this.checkIfExists(createPostDto.celeb_username);
      const imageName = this.generateFileName();
      const buffer = await this.resizeImage(file);
      await this.s3Client.send(
        new PutObjectCommand({
          Bucket: this.configService.getOrThrow('POSTS_BUCKET_NAME'),
          Key: imageName,
          Body: buffer,
          ContentType: 'image/jpeg',
        }),
      );
      const postObject = {
        celebid: celebid,
        celeb_username: createPostDto.celeb_username,
        imagename: imageName,
        caption: createPostDto.caption,
      };
      const post = await this.createPost(postObject);
      return { message: 'Post created', post };
    } catch (error) {
      throw error;
    }
  }

  async getCelebPosts(username: string) {
    try {
      await this.checkIfExists(username);
      const posts = await this.prisma.post.findMany({
        where: {
          celeb_username: username,
        },
      });
      for (const item of posts) {
        const getObjectParams = {
          Bucket: this.configService.getOrThrow('POSTS_BUCKET_NAME'),
          Key: item.imagename,
        };
        const command = new GetObjectCommand(getObjectParams);
        const url = await getSignedUrl(this.s3Client, command, {
          expiresIn: 3600,
        });
        (item as any).imageURL = url;
      }
      posts.sort((a: any, b: any) => {
        const dateA = new Date(a);
        const dateB = new Date(b);
        return dateA.getTime() - dateB.getTime();
      });
      return { message: 'Success', posts };
    } catch (error) {
      throw error;
    }
  }

  async deleteOnePost(deletePostDto: DeletePostDto, request: any) {
    try {
      const post = await this.prisma.post.findUnique({
        where: {
          id: deletePostDto.postid,
        },
      });
      if (request.user.username != post.celeb_username) {
        throw new UnauthorizedException(
          'This user does not have permission to modify this resource',
        );
      }
    } catch (error) {
      throw error;
    }
    try {
      const check = await this.prisma.post.findUnique({
        where: {
          id: deletePostDto.postid,
        },
      });
      if (check === null) {
        throw new NotFoundException(
          `Post with ID ${deletePostDto.postid} not found`,
        );
      }
      const params = {
        Bucket: this.configService.getOrThrow('POSTS_BUCKET_NAME'),
        Key: check.imagename,
      };
      const command = new DeleteObjectCommand(params);
      await this.s3Client.send(command);
      await this.prisma.post.delete({
        where: {
          id: deletePostDto.postid,
        },
      });
      return { message: 'Post deleted' };
    } catch (error) {
      throw error;
    }
  }
}
