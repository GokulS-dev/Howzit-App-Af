import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsNumber, IsEnum } from 'class-validator';

enum categories {
  PERSONAL = 'personal',
  BUSINESS = 'business',
}

export class ServiceDto {
  @ApiProperty()
  @IsNumber()
  @IsNotEmpty()
  price: number;
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  description: string;
  @ApiProperty()
  @IsNumber()
  @IsNotEmpty()
  time_needed: number;
  @ApiProperty()
  @IsEnum(categories)
  @IsNotEmpty()
  category: categories;
}
