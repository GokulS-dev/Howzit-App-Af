import { IsNotEmpty, IsNumber, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
export class CreateAudioDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  celeb_username: string;
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  fan_username: string;
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  description: string;
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  orderid: string;
}
