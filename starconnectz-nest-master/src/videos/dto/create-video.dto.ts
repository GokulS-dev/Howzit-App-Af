import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsString } from 'class-validator';
export class CreateVideoDto {
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
