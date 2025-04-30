import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsString } from 'class-validator';

enum categories {
  CELEB = 'celeb',
  FAN = 'fan',
}

export class LoginUserDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  username: string;
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  password: string;
  @ApiProperty()
  @IsEnum(categories)
  @IsNotEmpty()
  type: categories;
}
