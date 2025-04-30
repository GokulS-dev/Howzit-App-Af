import {
  Body,
  Controller,
  Delete,
  Get,
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
import { AudiosService } from './audios.service';
import { AuthGuard } from 'src/auth/auth.guard';
import { FileInterceptor } from '@nestjs/platform-express';
import { CreateAudioDto } from './dto/create-audio.dto';
import { ApiConsumes, ApiOperation, ApiTags } from '@nestjs/swagger';
import { MaxFileSizeValidator } from '@nestjs/common/pipes';

@Controller('audios')
@ApiTags('Audios')
export class AudiosController {
  constructor(private audiosService: AudiosService) {}

  @UseGuards(AuthGuard)
  @Post()
  @ApiOperation({ summary: 'Upload a new audio file' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('audio'))
  async uploadAudio(
    @UploadedFile(
      new ParseFilePipe({
        validators: [new MaxFileSizeValidator({ maxSize: 50000000 })],
      }),
    )
    file: Express.Multer.File,
    @Body(ValidationPipe) createAudioDto: CreateAudioDto,
    @Req() request: Request,
  ) {
    return await this.audiosService.uploadAudio(
      createAudioDto,
      file.buffer,
      request,
      file,
    );
  }

  @UseGuards(AuthGuard)
  @Get('celeb/:username')
  @ApiOperation({ summary: 'Retrieve all audios for a specific celebrity' })
  async getCelebAudios(@Param('username') username: string, request: Request) {
    return await this.audiosService.getCelebAudios(username, request);
  }

  @UseGuards(AuthGuard)
  @Get('fan/:username')
  @ApiOperation({ summary: 'Retrieve all audios for a specific fan' })
  async getFanAudios(@Param('username') username: string, request: Request) {
    return await this.audiosService.getFanAudios(username, request);
  }

  @UseGuards(AuthGuard)
  @Delete(':id')
  @ApiOperation({ summary: 'Delete an audio file by ID' })
  async deleteAudio(@Param('id', ParseIntPipe) id: number, request: Request) {
    return await this.audiosService.deleteAudio(id, request);
  }
}
