import {
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { CreateServicesDto } from './dto/create-service.dto';
import { PrismaService } from 'src/prisma/prisma.service';

@Injectable()
export class ServiceService {
  constructor(private prisma: PrismaService) {}

  async checkIfExists(username: string): Promise<number> {
    try {
      const celeb = await this.prisma.celeb.findUnique({
        where: {
          username: username,
        },
      });
      if (celeb === null) {
        throw new NotFoundException(
          `Celeb with username ${username} is not found`,
        );
      }
      return celeb.id;
    } catch (error) {
      throw error;
    }
  }

  async getServices(username: string) {
    try {
      const celebid = await this.checkIfExists(username);
      const services = await this.prisma.service.findMany({
        where: {
          celebid: celebid,
        },
      });
      return { message: 'Success', services };
    } catch (error) {
      throw error;
    }
  }

  async createServices(createServicesDto: CreateServicesDto, request: any) {
    try {
      if (request.user.username != createServicesDto.username) {
        throw new UnauthorizedException(
          'This user does not have permission to access this resource',
        );
      }
      const celebid = await this.checkIfExists(createServicesDto.username);
      await this.prisma.celeb.update({
        where: {
          id: celebid,
        },
        data: {
          bio: createServicesDto.bio,
        },
      });
      for (const item of createServicesDto.services) {
        await this.prisma.service.create({
          data: {
            price: item.price,
            category: item.category,
            description: item.description,
            celeb_username: createServicesDto.username,
            time_needed: item.time_needed,
            celebid: celebid,
          },
        });
      }
      return {
        message: `Services created for user : ${createServicesDto.username}`,
      };
    } catch (error) {
      throw error;
    }
  }

  async deleteService(serviceid: number, request: any) {
    try {
      const checkUsername = await this.prisma.service.findUnique({
        where: {
          id: serviceid,
        },
      });
      if (checkUsername.celeb_username != request.user.username) {
        throw new UnauthorizedException(
          'This user does not have permission to modify this resource',
        );
      }
    } catch (error) {
      throw error;
    }
    const service = await this.prisma.service.findUnique({
      where: {
        id: serviceid,
      },
    });
    if (service === null) {
      throw new NotFoundException(`Service with id ${serviceid} not found`);
    }
    await this.prisma.service.delete({
      where: {
        id: serviceid,
      },
    });
    return { message: `Service with id ${serviceid} deleted successfully` };
  }
}
