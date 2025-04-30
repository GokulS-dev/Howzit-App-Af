import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty } from 'class-validator';

export class FollowCelebDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  fan_username: string;
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  celeb_username: string;
}
