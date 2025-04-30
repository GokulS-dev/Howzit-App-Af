import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  ValidationPipe,
  UseGuards,
  Req,
} from '@nestjs/common';
import { OrderService } from './order.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { AuthGuard } from 'src/auth/auth.guard';
import { Request } from 'express';
import { AddOrderDetailsDto } from './dto/add-order-info.dto';
import { RejectReasonDto } from './dto/reject-reason.dto';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@Controller('order')
@ApiTags('Order')
export class OrderController {
  constructor(private orderService: OrderService) {}

  @UseGuards(AuthGuard)
  @Get('getDetails/:orderid')
  @ApiOperation({ summary: 'Get order details by order ID' }) // Added summary
  async getOrderDetails(
    @Param('orderid', ParseIntPipe) orderid: number,
    @Req() request: Request,
  ) {
    return await this.orderService.getOrderDetails(orderid, request);
  }

  @UseGuards(AuthGuard)
  @Get('fan/:username')
  @ApiOperation({ summary: 'Get orders for a specific fan' }) // Added summary
  async getFanOrders(
    @Param('username') username: string,
    @Req() request: Request,
  ) {
    return await this.orderService.getFanOrders(username, request);
  }

  @UseGuards(AuthGuard)
  @Get('celeb/:username')
  @ApiOperation({ summary: 'Get orders for a specific celebrity' }) // Added summary
  async getCelebOrders(
    @Param('username') username: string,
    @Req() request: Request,
  ) {
    return await this.orderService.getCelebOrders(username, request);
  }

  @UseGuards(AuthGuard)
  @Post()
  @ApiOperation({ summary: 'Create a new order' }) // Added summary
  async createOrder(
    @Body(ValidationPipe) createOrderDto: CreateOrderDto,
    @Req() request: Request,
  ) {
    return await this.orderService.createOrder(createOrderDto, request);
  }

  @UseGuards(AuthGuard)
  @Delete(':orderid')
  @ApiOperation({ summary: 'Delete an order by order ID' }) // Added summary
  async deleteOrder(
    @Param('orderid', ParseIntPipe) orderid: number,
    @Req() request: Request,
  ) {
    return await this.orderService.deleteOrder(orderid, request);
  }

  @UseGuards(AuthGuard)
  @Post('addDetails/:orderid')
  @ApiOperation({ summary: 'Add details to an existing order' }) // Added summary
  async addOrderDetails(
    @Param('orderid', ParseIntPipe) orderid: number,
    @Body(ValidationPipe) addOrderDetailsDto: AddOrderDetailsDto,
    @Req() request: Request,
  ) {
    return await this.orderService.addOrderDetails(
      orderid,
      addOrderDetailsDto,
      request,
    );
  }

  @UseGuards(AuthGuard)
  @Patch('rejectReason/:orderid')
  @ApiOperation({ summary: 'Add a rejection reason for an order' }) // Added summary
  async addRejectReason(
    @Param('orderid', ParseIntPipe) orderid: number,
    @Body(ValidationPipe) rejectReasonDto: RejectReasonDto,
  ) {
    return await this.orderService.addRejectReason(orderid, rejectReasonDto);
  }

  @UseGuards(AuthGuard)
  @Patch(':orderid')
  @ApiOperation({ summary: 'Update the status of an order' }) // Added summary
  async updateStatus(
    @Param('orderid', ParseIntPipe) orderid: number,
    @Body(ValidationPipe) updateOrderStatusDto: UpdateOrderStatusDto,
    @Req() request: Request,
  ) {
    return await this.orderService.updateStatus(
      orderid,
      updateOrderStatusDto,
      request,
    );
  }
}
