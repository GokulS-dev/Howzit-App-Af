import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty } from 'class-validator';

export class DeletePostDto {
  @ApiProperty()
  @IsNotEmpty()
  postid: number;
}
