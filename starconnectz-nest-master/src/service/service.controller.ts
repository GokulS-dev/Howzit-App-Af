import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Req,
  UseGuards,
  ValidationPipe,
} from '@nestjs/common';
import { ServiceService } from './service.service';
import { CreateServicesDto } from './dto/create-service.dto';
import { AuthGuard } from 'src/auth/auth.guard';
import { Request } from 'express';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@Controller('service')
@ApiTags('Service')
export class ServiceController {
  constructor(private serviceService: ServiceService) {}

  @UseGuards(AuthGuard)
  @Get(':username')
  @ApiOperation({ summary: 'Get services for a specific user' }) // Added summary
  async getServices(@Param('username') username: string) {
    return await this.serviceService.getServices(username);
  }

  @UseGuards(AuthGuard)
  @Post()
  @ApiOperation({ summary: 'Create a new service' }) // Added summary
  async createServices(
    @Body(ValidationPipe) createServicesDto: CreateServicesDto,
    @Req() request: Request,
  ) {
    return await this.serviceService.createServices(createServicesDto, request);
  }

  @UseGuards(AuthGuard)
  @Delete(':serviceid')
  @ApiOperation({ summary: 'Delete a service by ID' }) // Added summary
  async deleteService(
    @Param('serviceid', ParseIntPipe) serviceid: number,
    @Req() request: Request,
  ) {
    return await this.serviceService.deleteService(serviceid, request);
  }
}
