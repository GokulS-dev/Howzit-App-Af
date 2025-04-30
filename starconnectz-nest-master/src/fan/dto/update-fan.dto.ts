import { CreateFanDto } from './create-fan.dto';
import { OmitType, PartialType } from '@nestjs/mapped-types';

export class UpdateFanDto extends PartialType(
  OmitType(CreateFanDto, ['password'] as const),
) {}
