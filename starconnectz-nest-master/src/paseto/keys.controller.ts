import { Controller, Get } from '@nestjs/common';
import { PasetoService } from '../paseto/paseto.service';

@Controller('keys')
export class KeysController {
  constructor(private readonly pasetoService: PasetoService) {}

  @Get('generate')
  async generateKeys(): Promise<string> {
    await this.pasetoService.generateAndSaveKeys();
    return 'Keys generated and saved successfully!';
  }
}