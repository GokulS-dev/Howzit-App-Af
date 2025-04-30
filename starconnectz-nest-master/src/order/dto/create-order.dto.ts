import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsNotEmpty } from 'class-validator';
export class CreateOrderDto {
  @ApiProperty()
  @IsNumber()
  @IsNotEmpty()
  celebid: number;
  @ApiProperty()
  @IsNumber()
  @IsNotEmpty()
  fanid: number;
  @ApiProperty()
  @IsNumber()
  @IsNotEmpty()
  serviceid: number;
}
