import {
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { AddOrderDetailsDto } from './dto/add-order-info.dto';
import { RejectReasonDto } from './dto/reject-reason.dto';
import { ConfigService } from '@nestjs/config';
import { GetObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

@Injectable()
export class OrderService {
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

  async checkIfOrderExists(createOrderDto: CreateOrderDto): Promise<Boolean> {
    try {
      const orders = await this.prisma.order.findMany({
        where: {
          celebid: createOrderDto.celebid,
          serviceid: createOrderDto.serviceid,
          fanid: createOrderDto.fanid,
        },
      });
      if (orders === null) {
        return true;
      } else {
        for (const order of orders) {
          if (order.status != 'completed') {
            throw new ConflictException(
              'This order already exists and has not been completed',
            );
          }
        }
      }
      return true;
    } catch (error) {
      throw error;
    }
  }

  async getData(celebid: number, fanid: number, serviceid: number) {
    try {
      const celeb = await this.prisma.celeb.findUnique({
        where: {
          id: celebid,
        },
      });
      if (celeb === null) {
        throw new NotFoundException(`Celeb with id ${celebid} is not found`);
      }
      const fan = await this.prisma.fan.findUnique({
        where: {
          id: fanid,
        },
      });
      if (fan === null) {
        throw new NotFoundException(`Fan with id ${fanid} is not found`);
      }
      const service = await this.prisma.service.findUnique({
        where: {
          id: serviceid,
        },
      });
      if (service === null) {
        throw new NotFoundException(
          `Service with id ${serviceid} is not found`,
        );
      }
      return { celeb, fan, service };
    } catch (error) {
      throw error;
    }
  }

  async checkIfExists(username: string): Promise<number> {
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
      return celeb.id;
    } catch (error) {
      throw error;
    }
  }

  async getOrderDetails(orderid: number, request: any) {
    try {
      const order = await this.prisma.order.findUnique({
        where: {
          id: orderid,
        },
      });
      if (order === null) {
        throw new NotFoundException(`Order with id ${orderid} not found`);
      }
      if (request.user.type === 'fan') {
        if (request.user.username != order.fan_username) {
          throw new UnauthorizedException(
            `This user does not have access to this resource`,
          );
        }
      }
      if (request.user.type === 'celeb') {
        if (request.user.username != order.celeb_username) {
          throw new UnauthorizedException(
            `This user does not have access to this resource`,
          );
        }
      }
      if (order.status === 'rejected') {
        return { message: 'Success', order };
      }
      if (order.audio_name === '') {
        const getObjectParams = {
          Bucket: this.configService.getOrThrow('VIDEOS_BUCKET_NAME'),
          Key: order.video_name,
        };
        const command = new GetObjectCommand(getObjectParams);
        const url = await getSignedUrl(this.s3Client, command, {
          expiresIn: 3600,
        });
        (order as any).videoURL = url;
      }
      if (order.video_name === '') {
        const getObjectParams = {
          Bucket: this.configService.getOrThrow('AUDIOS_BUCKET_NAME'),
          Key: order.audio_name,
        };
        const command = new GetObjectCommand(getObjectParams);
        const url = await getSignedUrl(this.s3Client, command, {
          expiresIn: 3600,
        });
        (order as any).audioURL = url;
      }
      return { message: 'Success', order };
    } catch (error) {
      throw error;
    }
  }

  async getCelebOrders(username: string, request: any) {
    if (request.user.username != username) {
      throw new UnauthorizedException(
        'This user does not have permission to access this resource',
      );
    }
    try {
      const celebid = await this.checkIfExists(username);
      const orders = await this.prisma.order.findMany({
        where: {
          celebid: celebid,
        },
      });
      orders.sort((a, b) => {
        const dateA = new Date(a.created_at);
        const dateB = new Date(b.created_at);
        return dateB.getTime() - dateA.getTime();
      });
      return { message: 'Success', orders };
    } catch (error) {
      throw error;
    }
  }

  async getFanOrders(username: string, request: any) {
    if (request.user.username != username) {
      throw new UnauthorizedException(
        'This user does not have permission to access this resource',
      );
    }
    try {
      const fan = await this.prisma.fan.findUnique({
        where: {
          username: username,
        },
      });
      if (fan === null) {
        throw new NotFoundException(`Fan with username ${username} not found`);
      }
      const orders = await this.prisma.order.findMany({
        where: {
          fanid: fan.id,
        },
      });
      return { message: 'Successs', orders };
    } catch (error) {
      throw error;
    }
  }

  async createOrder(createOrderDto: CreateOrderDto, request: any) {
    if (request.user.id != createOrderDto.fanid) {
      throw new UnauthorizedException(
        'This user does not have permission to access this resource',
      );
    }
    try {
      await this.checkIfOrderExists(createOrderDto);
      const { celeb, fan, service } = await this.getData(
        createOrderDto.celebid,
        createOrderDto.fanid,
        createOrderDto.serviceid,
      );
      const celebServices = await this.prisma.service.findMany({
        where: {
          celebid: createOrderDto.celebid,
          id: createOrderDto.serviceid,
        },
      });
      if (celebServices.length === 0) {
        throw new NotFoundException(
          `The celeb with id ${createOrderDto.celebid} does not have a service of id ${createOrderDto.serviceid}`,
        );
      }
      const order = await this.prisma.order.create({
        data: {
          celebid: celeb.id,
          fanid: fan.id,
          serviceid: service.id,
          celeb_username: celeb.username,
          fan_username: fan.username,
          service_details: service.description,
          price: service.price,
        },
      });
      return { message: 'Order Created', order };
    } catch (error) {
      throw error;
    }
  }

  async addOrderDetails(
    orderid: number,
    addOrderDetailsDto: AddOrderDetailsDto,
    request: any,
  ) {
    try {
      const order = await this.prisma.order.findUnique({
        where: {
          id: orderid,
        },
      });
      if (order === null) {
        throw new NotFoundException(`Order with id ${orderid} not found`);
      }
      if (request.user.username != order.fan_username) {
        throw new UnauthorizedException(
          `This user is not allowed to access this resource`,
        );
      }
      await this.prisma.order.update({
        where: {
          id: orderid,
        },
        data: {
          occassion: addOrderDetailsDto.occasion,
          wishes_to: addOrderDetailsDto.wishes_to,
          additional_info: addOrderDetailsDto.additional_info,
        },
      });
      return { message: 'Order Details Added Successfully' };
    } catch (error) {
      throw error;
    }
  }

  async deleteOrder(orderid: number, request: any) {
    const order = await this.prisma.order.findUnique({
      where: {
        id: orderid,
      },
    });
    if (order === null) {
      throw new NotFoundException(`Order with ${orderid} not found`);
    }
    if (
      order.fan_username != request.user.username &&
      order.celeb_username != request.user.username
    ) {
      throw new UnauthorizedException(
        'This user does not have permission to access this resource',
      );
    }
    await this.prisma.order.delete({
      where: {
        id: orderid,
      },
    });
    return { message: 'Order deleted Sucessfully' };
  }

  async addRejectReason(orderid: number, rejectReasonDto: RejectReasonDto) {
    try {
      const order = await this.prisma.order.findUnique({
        where: {
          id: orderid,
        },
      });
      if (order === null) {
        throw new NotFoundException(`Order with id ${orderid} not found`);
      }
      await this.prisma.order.update({
        where: {
          id: orderid,
        },
        data: {
          reject_reason: rejectReasonDto.reason,
        },
      });
      return { message: 'Reject reason added', reason: rejectReasonDto.reason };
    } catch (error) {
      throw error;
    }
  }

  async updateStatus(
    orderid: number,
    updateOrderStatusDto: UpdateOrderStatusDto,
    request: any,
  ) {
    const order = await this.prisma.order.findUnique({
      where: {
        id: orderid,
      },
    });
    if (order === null) {
      throw new NotFoundException(`Order with id ${orderid} not found`);
    }
    if (order.celeb_username != request.user.username) {
      throw new UnauthorizedException(
        'This user does not have permission to access this resource',
      );
    }
    await this.prisma.order.update({
      where: {
        id: orderid,
      },
      data: {
        status: updateOrderStatusDto.status,
      },
    });
    return {
      message: `Successfully updated order status of order id ${orderid} to ${updateOrderStatusDto.status}`,
    };
  }
}
