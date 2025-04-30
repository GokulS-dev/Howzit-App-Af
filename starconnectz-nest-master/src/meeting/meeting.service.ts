import {
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateMeetingDto } from './dto/create-meeting.dto';
import * as StreamChat from 'stream-chat';
import { ConfigService } from '@nestjs/config';
import { UpdateMeetingDto } from './dto/update-meeting.dto';

@Injectable()
export class MeetingService {
  constructor(
    private prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {}

  async createMeeting(createMeetingDto: CreateMeetingDto, request: any) {
    try {
      if (request.user.username != createMeetingDto.celeb_username) {
        throw new UnauthorizedException(
          `This user does not have permission to access this resource`,
        );
      }
      const celeb = await this.prisma.celeb.findUnique({
        where: {
          username: createMeetingDto.celeb_username,
        },
      });
      if (celeb === null) {
        throw new NotFoundException(
          `Celeb with username ${createMeetingDto.celeb_username} not found`,
        );
      }
      const fan = await this.prisma.fan.findUnique({
        where: {
          username: createMeetingDto.fan_username,
        },
      });
      if (fan === null) {
        throw new NotFoundException(
          `Fan with username ${createMeetingDto.fan_username} not found`,
        );
      }
      const order = await this.prisma.order.findUnique({
        where: {
          id: createMeetingDto.orderid,
        },
      });
      if (order === null) {
        throw new NotFoundException(
          `Order with id ${createMeetingDto.orderid} does not exist`,
        );
      }
      const checkUniqueCallId = await this.prisma.order.findFirst({
        where: {
          call_id: createMeetingDto.callid,
        },
      });
      if (checkUniqueCallId != null) {
        throw new ConflictException(`Order with this call id already exists`);
      }
      const stream_api_key = this.configService.getOrThrow('STREAM_API_KEY');
      const stream_api_secret =
        this.configService.getOrThrow('STREAM_API_SECRET');
      const serverClient = StreamChat.StreamChat.getInstance(
        stream_api_key,
        stream_api_secret,
      );
      const token = serverClient.createToken(createMeetingDto.celeb_username);
      const updatedOrder = await this.prisma.order.update({
        where: {
          id: createMeetingDto.orderid,
        },
        data: {
          celeb_username: celeb.username,
          celebid: celeb.id,
          fan_username: fan.username,
          fanid: fan.id,
          call_id: createMeetingDto.callid,
          celeb_token: token,
        },
      });
      return { message: 'Meeting created', meeting: updatedOrder };
    } catch (error) {
      throw error;
    }
  }

  async getMeeting(orderid: number, request: any) {
    try {
      const order = await this.prisma.order.findUnique({
        where: {
          id: orderid,
        },
      });
      if (order === null) {
        throw new NotFoundException(`Order with id ${orderid} not found`);
      }
      if (order.fan_username != request.user.username) {
        throw new UnauthorizedException(
          'This user is not permitted to access this resource',
        );
      }
      return { message: 'Success', order };
    } catch (error) {
      throw error;
    }
  }
}
