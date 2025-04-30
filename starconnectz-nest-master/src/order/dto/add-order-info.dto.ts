import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class AddOrderDetailsDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  occasion: string;
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  wishes_to: string;
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  additional_info: string;
}
