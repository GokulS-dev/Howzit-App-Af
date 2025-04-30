import { CreateCelebDto } from './create-celeb.dto';
import { PartialType, OmitType } from '@nestjs/mapped-types';

export class UpdateCelebDto extends PartialType(
  OmitType(CreateCelebDto, ['password'] as const),
) {}
