import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { NotFoundException, ConflictException } from '@nestjs/common';
import { CreateFanDto } from './dto/create-fan.dto';
import { UpdateFanDto } from './dto/update-fan.dto';
import { FollowCelebDto } from './dto/follow-celeb.dto';
import * as bcrypt from 'bcrypt';
import { GetObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class FanService {
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

  checkUnique = async (
    username?: string,
    email?: string,
  ): Promise<[Boolean, String]> => {
    if (username) {
      const checkUsername = await this.prisma.fan.findUnique({
        where: {
          username: username,
        },
      });
      if (checkUsername) {
        return [true, `username-${username}`];
      }
      const checkCelebUsername = await this.prisma.celeb.findUnique({
        where: {
          username: username,
        },
      });
      if (checkCelebUsername) {
        return [true, `username-${username}`];
      }
    }
    if (email) {
      const checkEmail = await this.prisma.fan.findUnique({
        where: {
          email: email,
        },
      });
      if (checkEmail) {
        return [true, `email-${email}`];
      }
    }
    return [false, ''];
  };

  async findAll() {
    try {
      const fans = await this.prisma.fan.findMany();
      return { message: 'Success', fans };
    } catch (error) {
      throw error;
    }
  }

  async findOne(username: string) {
    try {
      const fan = await this.prisma.fan.findUnique({
        where: {
          username,
        },
        include: {
          following: true,
          orders: true,
        },
      });
      if (fan === null) {
        throw new NotFoundException(`Fan with username ${username} not found`);
      }
      return { message: 'Success', fan };
    } catch (error) {
      throw error;
    }
  }

  async createOne(createFanDto: CreateFanDto) {
    try {
      const check = await this.checkUnique(
        createFanDto.username,
        createFanDto.email,
      );
      if (check[0]) {
        throw new ConflictException(
          `Fan with the ${check[1].split('-')[0]} ${check[1].split('-')[1]} already exists`,
        );
      }
      const salt = await bcrypt.genSalt(10);
      const fan = await this.prisma.fan.create({
        data: {
          username: createFanDto.username,
          email: createFanDto.email,
          phone: createFanDto.phone,
          password: await bcrypt.hash(createFanDto.password, salt),
          country: createFanDto.country,
        },
      });
      return { message: 'Fan Created', fan };
    } catch (error) {
      throw error;
    }
  }

  async followOne(followCelebDto: FollowCelebDto, request: any) {
    try {
      if (request.user.username != followCelebDto.fan_username) {
        throw new UnauthorizedException(
          'This user does not have permission to modify this resource',
        );
      }
      const celeb = await this.prisma.celeb.findUnique({
        where: { username: followCelebDto.celeb_username },
      });
      if (celeb === null) {
        throw new NotFoundException(
          `Celeb with username ${followCelebDto.celeb_username} is not found`,
        );
      }
      const fan = await this.prisma.fan.findUnique({
        where: {
          username: followCelebDto.fan_username,
        },
      });
      if (fan === null) {
        throw new NotFoundException(
          `Fan with username ${followCelebDto.fan_username} is not found`,
        );
      }
      await this.prisma.fan.update({
        where: {
          username: followCelebDto.fan_username,
        },
        data: {
          following: {
            connect: { id: celeb.id },
          },
        },
      });
      return {
        message: `${followCelebDto.fan_username} is now following ${followCelebDto.celeb_username}`,
      };
    } catch (error) {
      throw error;
    }
  }

  async unfollowOne(unfollowCelebDto: FollowCelebDto, request: any) {
    try {
      if (request.user.username != unfollowCelebDto.fan_username) {
        throw new UnauthorizedException(
          'This user is not allowed to access this resource',
        );
      }
      const fan = await this.prisma.fan.findUnique({
        where: {
          username: unfollowCelebDto.fan_username,
        },
      });
      if (fan === null) {
        throw new NotFoundException(
          `Fan with username ${unfollowCelebDto.fan_username} does not exist`,
        );
      }
      const celeb = await this.prisma.celeb.findUnique({
        where: {
          username: unfollowCelebDto.celeb_username,
        },
      });
      if (celeb === null) {
        throw new NotFoundException(
          `Celeb with username ${unfollowCelebDto.celeb_username} does not exist`,
        );
      }
      await this.prisma.fan.update({
        where: {
          username: unfollowCelebDto.fan_username,
        },
        data: {
          following: {
            disconnect: { id: celeb.id },
          },
        },
      });
      return {
        message: `${unfollowCelebDto.fan_username} is not following ${unfollowCelebDto.celeb_username} anymore`,
      };
    } catch (error) {
      throw error;
    }
  }

  async updateOne(username: string, updateFanDto: UpdateFanDto) {
    try {
      const fan = await this.prisma.fan.findUnique({
        where: {
          username: username,
        },
      });
      if (fan === null) {
        throw new NotFoundException(`Fan with username ${username} not found`);
      } else {
        const check = await this.checkUnique(
          updateFanDto.username,
          updateFanDto.email,
        );
        if (check[0]) {
          throw new ConflictException(
            `Celeb with the ${check[1].split('-')[0]} ${check[1].split('-')[1]} already exists`,
          );
        }
        const updatedUser = await this.prisma.fan.update({
          where: {
            username: username,
          },
          data: {
            username: updateFanDto.username || fan.username,
            email: updateFanDto.email || fan.email,
            phone: updateFanDto.phone || fan.phone,
          },
        });
        return { message: 'Updated Successfully', updatedUser };
      }
    } catch (error) {
      throw error;
    }
  }

  async getFeed(username: string) {
    try {
      const fan = await this.findOne(username);
      const feed = [];
      for (const celeb of fan.fan.following) {
        if (feed.length == 10) {
          break;
        }
        const posts = await this.prisma.post.findMany({
          where: {
            celebid: celeb.id,
          },
          orderBy: {
            created_at: 'desc',
          },
          take: 2,
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
        feed.push(posts);
      }
      return { message: 'Success', feed };
    } catch (error) {
      throw error;
    }
  }

  async deleteOne(username: string) {
    try {
      const fan = await this.prisma.fan.findUnique({
        where: {
          username: username,
        },
      });
      if (fan === null) {
        throw new NotFoundException(`Fan with username ${username} not found`);
      } else {
        const deletedUser = await this.prisma.fan.delete({
          where: {
            username: username,
          },
        });
        return { message: 'Deleted Successfully', deletedUser };
      }
    } catch (error) {
      throw error;
    }
  }
}
