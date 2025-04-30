import { IsString, IsNotEmpty, ValidateNested, IsArray } from 'class-validator';
import { ServiceDto } from './service.dto';
import { Type } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

export class CreateServicesDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  username: string;
  @ApiProperty()
  @IsString()
  bio: string;
  @ApiProperty()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ServiceDto)
  services: ServiceDto[];
}
