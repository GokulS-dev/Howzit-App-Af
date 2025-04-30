import {
  Body,
  Controller,
  Delete,
  FileTypeValidator,
  Get,
  MaxFileSizeValidator,
  Param,
  ParseFilePipe,
  ParseIntPipe,
  Post,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
  ValidationPipe,
} from '@nestjs/common';
import { VideosService } from './videos.service';
import { FileInterceptor } from '@nestjs/platform-express';
import { CreateVideoDto } from './dto/create-video.dto';
import { Request } from 'express';
import { AuthGuard } from 'src/auth/auth.guard';
import { ApiConsumes, ApiOperation, ApiTags } from '@nestjs/swagger';

@Controller('videos')
@ApiTags('Video')
export class VideosController {
  constructor(private videosService: VideosService) {}

  @UseGuards(AuthGuard)
  @Post()
  @UseInterceptors(FileInterceptor('video'))
  @ApiOperation({ summary: 'Upload a new video' }) // Added summary
  @ApiConsumes('multipart/form-data')
  async uploadVideo(
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 200000000 }),
          new FileTypeValidator({ fileType: 'video/mp4' }),
        ],
      }),
    )
    file: Express.Multer.File,
    @Body(ValidationPipe) createVideoDto: CreateVideoDto,
    @Req() request: Request,
  ) {
    return await this.videosService.uploadVideo(
      createVideoDto,
      file.buffer,
      request,
    );
  }

  @UseGuards(AuthGuard)
  @Get('celeb/:username')
  @ApiOperation({ summary: 'Get videos uploaded by a celebrity' }) // Added summary
  async getCelebVideos(@Param('username') username: string, request: Request) {
    return await this.videosService.getCelebVideos(username, request);
  }

  @UseGuards(AuthGuard)
  @Get('fan/:username')
  @ApiOperation({ summary: 'Get videos uploaded by a fan' }) // Added summary
  async getFanVideos(@Param('username') username: string, request: Request) {
    return await this.videosService.getFanVideos(username, request);
  }

  @UseGuards(AuthGuard)
  @Delete(':id')
  @ApiOperation({ summary: 'Delete a video by ID' }) // Added summary
  async deleteVideo(@Param('id', ParseIntPipe) id: number, request: Request) {
    return await this.videosService.deleteVideo(id, request);
  }
}
