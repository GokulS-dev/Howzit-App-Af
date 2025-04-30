import {
  Body,
  Controller,
  Delete,
  FileTypeValidator,
  Get,
  MaxFileSizeValidator,
  Param,
  ParseFilePipe,
  Post,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
  ValidationPipe,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CreatePostDto } from './dto/create-post.dto';
import { PostService } from './post.service';
import { DeletePostDto } from './dto/delete-post.dto';
import { AuthGuard } from 'src/auth/auth.guard';
import { Request } from 'express';
import { ApiTags, ApiOperation, ApiConsumes } from '@nestjs/swagger';

@Controller('post')
@ApiTags('Post')
export class PostController {
  constructor(private readonly postService: PostService) {}

  @UseGuards(AuthGuard)
  @Post()
  @UseInterceptors(FileInterceptor('image'))
  @ApiOperation({ summary: 'Upload a new post with an image' }) // Added summary
  @ApiConsumes('multipart/form-data')
  async uploadPost(
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 15000000 }),
          new FileTypeValidator({ fileType: 'image/jpeg' }),
        ],
      }),
    )
    file: Express.Multer.File,
    @Body(ValidationPipe) createPostDto: CreatePostDto,
    @Req() request: Request,
  ) {
    return await this.postService.upload(createPostDto, file.buffer, request);
  }

  @UseGuards(AuthGuard)
  @Get(':username')
  @ApiOperation({ summary: 'Get posts for a specific celebrity' }) // Added summary
  async getCelebPosts(@Param('username') username: string) {
    return await this.postService.getCelebPosts(username);
  }

  @UseGuards(AuthGuard)
  @Delete()
  @ApiOperation({ summary: 'Delete a post' }) // Added summary
  async deleteOnePost(
    @Body(ValidationPipe) deletePostDto: DeletePostDto,
    @Req() request: Request,
  ) {
    return await this.postService.deleteOnePost(deletePostDto, request);
  }
}
