import {
  Body,
  Controller,
  Delete,
  FileTypeValidator,
  Get,
  MaxFileSizeValidator,
  Param,
  ParseFilePipe,
  Patch,
  Post,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { CelebService } from './celeb.service';
import { CreateCelebDto } from './dto/create-celeb.dto';
import { UpdateCelebDto } from './dto/update-celeb.dto';
import { ValidationPipe } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { UpdateProfilePicDto } from './dto/update-profile-pic.dto';
import { AuthGuard } from 'src/auth/auth.guard';
import { ValidationGuard } from 'src/auth/validation.guard';
import { Request } from 'express';
import { ApiConsumes, ApiOperation, ApiTags } from '@nestjs/swagger';

@Controller('celeb')
@ApiTags('Celeb')
export class CelebController {
  constructor(private readonly celebService: CelebService) {}

  @UseGuards(AuthGuard)
  @Get()
  @ApiOperation({ summary: 'Retrieve a list of all celebrities' }) // Added summary
  async findAll() {
    return await this.celebService.findAll();
  }

  @UseGuards(AuthGuard)
  @Get('/country/:country')
  @ApiOperation({ summary: 'Retrieve celebrities by country' }) // Added summary
  async findByCountry(@Param('country') country: string) {
    return await this.celebService.findByCountry(country);
  }

  @UseGuards(AuthGuard)
  @Get(':username')
  @ApiOperation({ summary: 'Retrieve a specific celebrity by username' }) // Added summary
  async findOne(@Param('username') username: string, @Req() request: Request) {
    return await this.celebService.findOne(username, request);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new celebrity profile' }) // Added summary
  async createOne(@Body(ValidationPipe) createCelebDto: CreateCelebDto) {
    return await this.celebService.createOne(createCelebDto);
  }

  @UseGuards(AuthGuard)
  @Post('updateProfilePic')
  @ApiOperation({ summary: 'Update celebrity profile picture' }) // Added summary
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('image'))
  async updateProfilePic(
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 15000000 }),
          new FileTypeValidator({ fileType: 'image/jpeg' }),
        ],
      }),
    )
    file: Express.Multer.File,
    @Body(ValidationPipe) updateProfilePicDto: UpdateProfilePicDto,
    @Req() request: Request,
  ) {
    return await this.celebService.updateProfilePic(
      updateProfilePicDto,
      file.buffer,
      request,
    );
  }

  @UseGuards(AuthGuard, ValidationGuard)
  @Patch(':username')
  @ApiOperation({ summary: 'Update a celebrity profile by username' }) // Added summary
  async updateOne(
    @Param('username') username: string,
    @Body(ValidationPipe) updateCelebDto: UpdateCelebDto,
  ) {
    return await this.celebService.updateOne(username, updateCelebDto);
  }

  @UseGuards(AuthGuard, ValidationGuard)
  @Delete(':username')
  @ApiOperation({ summary: 'Delete a celebrity profile by username' }) // Added summary
  async deleteOne(@Param('username') username: string) {
    return await this.celebService.deleteOne(username);
  }
}
