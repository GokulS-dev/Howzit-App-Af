import { Controller, Req, UseGuards } from '@nestjs/common';
import { FanService } from './fan.service';
import { Get, Post, Patch, Delete, Param, Body } from '@nestjs/common';
import { ValidationPipe } from '@nestjs/common';
import { CreateFanDto } from './dto/create-fan.dto';
import { UpdateFanDto } from './dto/update-fan.dto';
import { FollowCelebDto } from './dto/follow-celeb.dto';
import { AuthGuard } from 'src/auth/auth.guard';
import { ValidationGuard } from 'src/auth/validation.guard';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

@Controller('fan')
@ApiTags('Fan')
export class FanController {
  constructor(private readonly fanService: FanService) {}

  @UseGuards(AuthGuard)
  @Get()
  @ApiOperation({ summary: 'Retrieve a list of all fans' }) // Added summary
  async findAll() {
    return await this.fanService.findAll();
  }

  @UseGuards(AuthGuard, ValidationGuard)
  @Get(':username/feed')
  @ApiOperation({ summary: 'Retrieve the feed for a specific fan by username' }) // Added summary
  async getFeed(@Param('username') username: string) {
    return await this.fanService.getFeed(username);
  }

  @UseGuards(AuthGuard)
  @Get(':username')
  @ApiOperation({ summary: 'Retrieve a specific fan by username' }) // Added summary
  async findOne(@Param('username') username: string) {
    return await this.fanService.findOne(username);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new fan profile' }) // Added summary
  async createOne(@Body(ValidationPipe) createFanDto: CreateFanDto) {
    return await this.fanService.createOne(createFanDto);
  }

  @UseGuards(AuthGuard)
  @Post('follow')
  @ApiOperation({ summary: 'Follow a celebrity' }) // Added summary
  async followOne(
    @Body(ValidationPipe) followCelebDto: FollowCelebDto,
    @Req() request: Request,
  ) {
    return await this.fanService.followOne(followCelebDto, request);
  }

  @UseGuards(AuthGuard)
  @Post('unfollow')
  @ApiOperation({ summary: 'Unfollow a celebrity' }) // Added summary
  async unfollowOne(
    @Body(ValidationPipe) unfollowCelebDto: FollowCelebDto,
    @Req() request: Request,
  ) {
    return await this.fanService.unfollowOne(unfollowCelebDto, request);
  }

  @UseGuards(AuthGuard, ValidationGuard)
  @Patch(':username')
  @ApiOperation({ summary: 'Update a fan profile by username' }) // Added summary
  async updateOne(
    @Param('username') username: string,
    @Body(ValidationPipe) updateFanDto: UpdateFanDto,
  ) {
    return await this.fanService.updateOne(username, updateFanDto);
  }

  @UseGuards(AuthGuard, ValidationGuard)
  @Delete(':username')
  @ApiOperation({ summary: 'Delete a fan profile by username' }) // Added summary
  async deleteOne(@Param('username') username: string) {
    return await this.fanService.deleteOne(username);
  }
}
