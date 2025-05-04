import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class ExampleService {
    constructor(private readonly configService: ConfigService) {
      const privateKey = fs.readFileSync(this.privateKeyPath, 'utf8');

  }
}