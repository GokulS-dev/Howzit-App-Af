import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsNumber } from 'class-validator';

export class CreateMerchDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  celeb_username: string;
  @ApiProperty()
  @IsString()
  description: string;
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  price: string;
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  status: string;
}
