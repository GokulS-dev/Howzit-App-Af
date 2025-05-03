// import { Injectable, UnauthorizedException } from '@nestjs/common';
// import { PrismaService } from 'src/prisma/prisma.service';
// import { NotFoundException, ConflictException } from '@nestjs/common';
// import { CreateFanDto } from './dto/create-fan.dto';
// import { UpdateFanDto } from './dto/update-fan.dto';
// import { FollowCelebDto } from './dto/follow-celeb.dto';
// import * as bcrypt from 'bcrypt';
// import { GetObjectCommand, S3Client } from '@aws-sdk/client-s3';
// import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
// import { ConfigService } from '@nestjs/config';
//
// @Injectable()
// export class FanService {
//   private readonly s3Client: S3Client;
//   constructor(
//     private prisma: PrismaService,
//     private readonly configService: ConfigService,
//   ) {
//     this.s3Client = new S3Client({
//       credentials: {
//         accessKeyId: this.configService.getOrThrow('ACCESS_KEY'),
//         secretAccessKey: this.configService.getOrThrow('SECRET_ACCESS_KEY'),
//       },
//       region: this.configService.getOrThrow('BUCKET_REGION'),
//     });
//   }
//
//   checkUnique = async (
//     username?: string,
//     email?: string,
//   ): Promise<[Boolean, String]> => {
//     if (username) {
//       const checkUsername = await this.prisma.fan.findUnique({
//         where: {
//           username: username,
//         },
//       });
//       if (checkUsername) {
//         return [true, `username-${username}`];
//       }
//       const checkCelebUsername = await this.prisma.celeb.findUnique({
//         where: {
//           username: username,
//         },
//       });
//       if (checkCelebUsername) {
//         return [true, `username-${username}`];
//       }
//     }
//     if (email) {
//       const checkEmail = await this.prisma.fan.findUnique({
//         where: {
//           email: email,
//         },
//       });
//       if (checkEmail) {
//         return [true, `email-${email}`];
//       }
//     }
//     return [false, ''];
//   };
//
//   async findAll() {
//     try {
//       const fans = await this.prisma.fan.findMany();
//       return { message: 'Success', fans };
//     } catch (error) {
//       throw error;
//     }
//   }
//
//   async findOne(username: string) {
//     try {
//       const fan = await this.prisma.fan.findUnique({
//         where: {
//           username,
//         },
//         include: {
//           following: true,
//           orders: true,
//         },
//       });
//       if (fan === null) {
//         throw new NotFoundException(`Fan with username ${username} not found`);
//       }
//       return { message: 'Success', fan };
//     } catch (error) {
//       throw error;
//     }
//   }
//
//   async createOne(createFanDto: CreateFanDto) {
//     try {
//       const check = await this.checkUnique(
//         createFanDto.username,
//         createFanDto.email,
//       );
//       if (check[0]) {
//         throw new ConflictException(
//           `Fan with the ${check[1].split('-')[0]} ${check[1].split('-')[1]} already exists`,
//         );
//       }
//       const salt = await bcrypt.genSalt(10);
//       const fan = await this.prisma.fan.create({
//         data: {
//           username: createFanDto.username,
//           email: createFanDto.email,
//           phone: createFanDto.phone,
//           password: await bcrypt.hash(createFanDto.password, salt),
//           country: createFanDto.country,
//         },
//       });
//       return { message: 'Fan Created', fan };
//     } catch (error) {
//       throw error;
//     }
//   }
//
//   async followOne(followCelebDto: FollowCelebDto, request: any) {
//     try {
//       if (request.user.username != followCelebDto.fan_username) {
//         throw new UnauthorizedException(
//           'This user does not have permission to modify this resource',
//         );
//       }
//       const celeb = await this.prisma.celeb.findUnique({
//         where: { username: followCelebDto.celeb_username },
//       });
//       if (celeb === null) {
//         throw new NotFoundException(
//           `Celeb with username ${followCelebDto.celeb_username} is not found`,
//         );
//       }
//       const fan = await this.prisma.fan.findUnique({
//         where: {
//           username: followCelebDto.fan_username,
//         },
//       });
//       if (fan === null) {
//         throw new NotFoundException(
//           `Fan with username ${followCelebDto.fan_username} is not found`,
//         );
//       }
//       await this.prisma.fan.update({
//         where: {
//           username: followCelebDto.fan_username,
//         },
//         data: {
//           following: {
//             connect: { id: celeb.id },
//           },
//         },
//       });
//       return {
//         message: `${followCelebDto.fan_username} is now following ${followCelebDto.celeb_username}`,
//       };
//     } catch (error) {
//       throw error;
//     }
//   }
//
//   async unfollowOne(unfollowCelebDto: FollowCelebDto, request: any) {
//     try {
//       if (request.user.username != unfollowCelebDto.fan_username) {
//         throw new UnauthorizedException(
//           'This user is not allowed to access this resource',
//         );
//       }
//       const fan = await this.prisma.fan.findUnique({
//         where: {
//           username: unfollowCelebDto.fan_username,
//         },
//       });
//       if (fan === null) {
//         throw new NotFoundException(
//           `Fan with username ${unfollowCelebDto.fan_username} does not exist`,
//         );
//       }
//       const celeb = await this.prisma.celeb.findUnique({
//         where: {
//           username: unfollowCelebDto.celeb_username,
//         },
//       });
//       if (celeb === null) {
//         throw new NotFoundException(
//           `Celeb with username ${unfollowCelebDto.celeb_username} does not exist`,
//         );
//       }
//       await this.prisma.fan.update({
//         where: {
//           username: unfollowCelebDto.fan_username,
//         },
//         data: {
//           following: {
//             disconnect: { id: celeb.id },
//           },
//         },
//       });
//       return {
//         message: `${unfollowCelebDto.fan_username} is not following ${unfollowCelebDto.celeb_username} anymore`,
//       };
//     } catch (error) {
//       throw error;
//     }
//   }
//
//   async updateOne(username: string, updateFanDto: UpdateFanDto) {
//     try {
//       const fan = await this.prisma.fan.findUnique({
//         where: {
//           username: username,
//         },
//       });
//       if (fan === null) {
//         throw new NotFoundException(`Fan with username ${username} not found`);
//       } else {
//         const check = await this.checkUnique(
//           updateFanDto.username,
//           updateFanDto.email,
//         );
//         if (check[0]) {
//           throw new ConflictException(
//             `Celeb with the ${check[1].split('-')[0]} ${check[1].split('-')[1]} already exists`,
//           );
//         }
//         const updatedUser = await this.prisma.fan.update({
//           where: {
//             username: username,
//           },
//           data: {
//             username: updateFanDto.username || fan.username,
//             email: updateFanDto.email || fan.email,
//             phone: updateFanDto.phone || fan.phone,
//           },
//         });
//         return { message: 'Updated Successfully', updatedUser };
//       }
//     } catch (error) {
//       throw error;
//     }
//   }
//
//   async getFeed(username: string) {
//     try {
//       const fan = await this.findOne(username);
//       const feed = [];
//       for (const celeb of fan.fan.following) {
//         if (feed.length == 10) {
//           break;
//         }
//         const posts = await this.prisma.post.findMany({
//           where: {
//             celebid: celeb.id,
//           },
//           orderBy: {
//             created_at: 'desc',
//           },
//           take: 2,
//         });
//         for (const item of posts) {
//           const getObjectParams = {
//             Bucket: this.configService.getOrThrow('POSTS_BUCKET_NAME'),
//             Key: item.imagename,
//           };
//           const command = new GetObjectCommand(getObjectParams);
//           const url = await getSignedUrl(this.s3Client, command, {
//             expiresIn: 3600,
//           });
//           (item as any).imageURL = url;
//         }
//         posts.sort((a: any, b: any) => {
//           const dateA = new Date(a);
//           const dateB = new Date(b);
//           return dateA.getTime() - dateB.getTime();
//         });
//         feed.push(posts);
//       }
//       return { message: 'Success', feed };
//     } catch (error) {
//       throw error;
//     }
//   }
//
//   async deleteOne(username: string) {
//     try {
//       const fan = await this.prisma.fan.findUnique({
//         where: {
//           username: username,
//         },
//       });
//       if (fan === null) {
//         throw new NotFoundException(`Fan with username ${username} not found`);
//       } else {
//         const deletedUser = await this.prisma.fan.delete({
//           where: {
//             username: username,
//           },
//         });
//         return { message: 'Deleted Successfully', deletedUser };
//       }
//     } catch (error) {
//       throw error;
//     }
//   }
// }

import {
  Injectable,
  UnauthorizedException,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
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

  async checkUnique(username?: string, email?: string): Promise<[boolean, string]> {
    if (username) {
      const userExists = await this.prisma.fan.findUnique({ where: { username } });
      if (userExists) return [true, `username-${username}`];

      const celebExists = await this.prisma.celeb.findUnique({ where: { username } });
      if (celebExists) return [true, `username-${username}`];
    }

    if (email) {
      const emailExists = await this.prisma.fan.findUnique({ where: { email } });
      if (emailExists) return [true, `email-${email}`];
    }

    return [false, ''];
  }

  async findAll() {
    const fans = await this.prisma.fan.findMany();
    return { message: 'Success', fans };
  }

  async findOne(username: string) {
    const fan = await this.prisma.fan.findUnique({
      where: { username },
      include: {
        following: true,
        orders: true,
      },
    });

    if (!fan) {
      throw new NotFoundException(`Fan with username ${username} not found`);
    }

    return { message: 'Success', fan };
  }

  async createOne(createFanDto: CreateFanDto) {
    const [exists, conflictField] = await this.checkUnique(
      createFanDto.username,
      createFanDto.email,
    );

    if (exists) {
      throw new ConflictException(
        `Fan with the ${conflictField.split('-')[0]} ${conflictField.split('-')[1]} already exists`,
      );
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(createFanDto.password, salt);

    const fan = await this.prisma.fan.create({
      data: {
        username: createFanDto.username,
        email: createFanDto.email,
        phone: createFanDto.phone,
        password: hashedPassword,
        country: createFanDto.country,
      },
    });

    return { message: 'Fan Created', fan };
  }

  async followOne(followCelebDto: FollowCelebDto, request: any) {
    if (request.user.username !== followCelebDto.fan_username) {
      throw new UnauthorizedException('Not authorized to follow on behalf of another user');
    }

    const celeb = await this.prisma.celeb.findUnique({
      where: { username: followCelebDto.celeb_username },
    });
    if (!celeb) throw new NotFoundException('Celeb not found');

    const fan = await this.prisma.fan.findUnique({
      where: { username: followCelebDto.fan_username },
    });
    if (!fan) throw new NotFoundException('Fan not found');

    await this.prisma.fan.update({
      where: { username: followCelebDto.fan_username },
      data: {
        following: {
          connect: { id: celeb.id },
        },
      },
    });

    return {
      message: `${followCelebDto.fan_username} is now following ${followCelebDto.celeb_username}`,
    };
  }

  async unfollowOne(unfollowCelebDto: FollowCelebDto, request: any) {
    if (request.user.username !== unfollowCelebDto.fan_username) {
      throw new UnauthorizedException('Not authorized to unfollow on behalf of another user');
    }

    const fan = await this.prisma.fan.findUnique({
      where: { username: unfollowCelebDto.fan_username },
    });
    if (!fan) throw new NotFoundException('Fan not found');

    const celeb = await this.prisma.celeb.findUnique({
      where: { username: unfollowCelebDto.celeb_username },
    });
    if (!celeb) throw new NotFoundException('Celeb not found');

    await this.prisma.fan.update({
      where: { username: unfollowCelebDto.fan_username },
      data: {
        following: {
          disconnect: { id: celeb.id },
        },
      },
    });

    return {
      message: `${unfollowCelebDto.fan_username} has unfollowed ${unfollowCelebDto.celeb_username}`,
    };
  }

  async updateOne(username: string, updateFanDto: UpdateFanDto) {
    const existingFan = await this.prisma.fan.findUnique({ where: { username } });
    if (!existingFan) {
      throw new NotFoundException(`Fan with username ${username} not found`);
    }

    // Check only if new values differ
    if (
      (updateFanDto.username && updateFanDto.username !== existingFan.username) ||
      (updateFanDto.email && updateFanDto.email !== existingFan.email)
    ) {
      const [exists, conflictField] = await this.checkUnique(
        updateFanDto.username,
        updateFanDto.email,
      );

      if (exists) {
        throw new ConflictException(
          `Fan with the ${conflictField.split('-')[0]} ${conflictField.split('-')[1]} already exists`,
        );
      }
    }

    const updatedUser = await this.prisma.fan.update({
      where: { username },
      data: {
        username: updateFanDto.username ?? existingFan.username,
        email: updateFanDto.email ?? existingFan.email,
        phone: updateFanDto.phone ?? existingFan.phone,
      },
    });

    return { message: 'Updated Successfully', updatedUser };
  }

  async getFeed(username: string) {
    const result = await this.findOne(username);
    const fan = result.fan;

    const feed = [];

    for (const celeb of fan.following) {
      if (feed.length >= 10) break;

      const posts = await this.prisma.post.findMany({
        where: { celebid: celeb.id },
        orderBy: { created_at: 'desc' },
        take: 2,
      });

      for (const post of posts) {
        const getObjectParams = {
          Bucket: this.configService.getOrThrow('POSTS_BUCKET_NAME'),
          Key: post.imagename,
        };

        const command = new GetObjectCommand(getObjectParams);
        const url = await getSignedUrl(this.s3Client, command, {
          expiresIn: 3600,
        });

        (post as any).imageURL = url;
      }

      feed.push(...posts);
    }

    feed.sort((a: any, b: any) => {
      return new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
    });

    return { message: 'Success', feed };
  }

  async deleteOne(username: string) {
    const fan = await this.prisma.fan.findUnique({
      where: { username },
    });

    if (!fan) {
      throw new NotFoundException(`Fan with username ${username} not found`);
    }

    const deletedUser = await this.prisma.fan.delete({
      where: { username },
    });

    return { message: 'Deleted Successfully', deletedUser };
  }
}