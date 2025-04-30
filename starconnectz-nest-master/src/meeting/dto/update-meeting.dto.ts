import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty } from 'class-validator';

enum categories {
  PENDING = 'pending',
  COMPLETED = 'completed',
}

export class UpdateMeetingDto {
  @ApiProperty()
  @IsEnum(categories)
  @IsNotEmpty()
  status: categories;
}
