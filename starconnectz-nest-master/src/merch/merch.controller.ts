import {
  Body,
  Controller,
  Req,
  FileTypeValidator,
  MaxFileSizeValidator,
  ParseFilePipe,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
  ValidationPipe,
  Get,
  Param,
  ParseIntPipe,
  Delete,
} from '@nestjs/common';
import { MerchService } from './merch.service';
import { AuthGuard } from 'src/auth/auth.guard';
import { FileInterceptor } from '@nestjs/platform-express';
import { CreateMerchDto } from './dto/create-merch-dto';
import { ApiConsumes, ApiOperation, ApiTags } from '@nestjs/swagger';

@Controller('merch')
@ApiTags('Merch')
export class MerchController {
  constructor(private readonly merchService: MerchService) {}

  @UseGuards(AuthGuard)
  @Post()
  @UseInterceptors(FileInterceptor('image'))
  @ApiOperation({ summary: 'Upload new merchandise' }) // Added summary
  @ApiConsumes('multipart/form-data')
  async uploadMerch(
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 15000000 }),
          new FileTypeValidator({ fileType: /\/(jpeg|png)$/ }),
        ],
      }),
    )
    file: Express.Multer.File,
    @Body(ValidationPipe) createMerchDto: CreateMerchDto,
    @Req() request: Request,
  ) {
    return await this.merchService.uploadMerch(
      createMerchDto,
      file.buffer,
      request,
    );
  }

  @UseGuards(AuthGuard)
  @Get(':username')
  @ApiOperation({ summary: 'Get merchandise for a celebrity by username' }) // Added summary
  async getCelebMerch(@Param('username') username: string) {
    return await this.merchService.getCelebMerch(username);
  }

  @UseGuards(AuthGuard)
  @Delete(':merchid')
  @ApiOperation({ summary: 'Delete merchandise by ID' }) // Added summary
  async deleteOneMerch(
    @Param('merchid', ParseIntPipe) merchid: number,
    @Req() request: Request,
  ) {
    return await this.merchService.deleteMerch(merchid, request);
  }
}
