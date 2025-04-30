import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsString } from 'class-validator';

export class CreateMeetingDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  celeb_username: string;
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  fan_username: string;
  @ApiProperty()
  @IsNumber()
  @IsNotEmpty()
  orderid: number;
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  callid: string;
}
