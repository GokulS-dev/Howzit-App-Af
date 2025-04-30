import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsBoolean } from 'class-validator';

export class UpdateProfilePicDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  username: string;
}
