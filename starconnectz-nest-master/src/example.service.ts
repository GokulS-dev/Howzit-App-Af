import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class ExampleService {
  constructor(private readonly configService: ConfigService) {
    const pasetoKey = this.configService.get<string>('PASETO_KEY');

    if (!pasetoKey) {
      throw new Error('❌ PASETO_KEY is not defined in .env');
    }

    console.log('✅ Loaded PASETO_KEY from .env:', pasetoKey);
  }
}