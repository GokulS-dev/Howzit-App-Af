import { Injectable, OnModuleInit } from '@nestjs/common';
import { PasetoService } from './paseto.service';

@Injectable()
export class AppService implements OnModuleInit {
  constructor(private readonly pasetoService: PasetoService) {}

  // This method is automatically called when the module is initialized
  async onModuleInit() {
    // Generate and save PASETO keys when the app starts
    await this.pasetoService.generateAndSaveKeys();
  }

  getHello(): string {
    return 'Hello World!';
  }
}