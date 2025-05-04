import { Injectable } from '@nestjs/common';
import { writeFileSync } from 'fs';
import { generateKeyPair } from 'crypto';
import { promisify } from 'util';

const generateKeyPairAsync = promisify(generateKeyPair);

@Injectable()
export class PasetoService {
  async generateAndSaveKeys(): Promise<void> {
    const { publicKey, privateKey } = await generateKeyPairAsync('ed25519');

    writeFileSync('private-key.pem', privateKey.export({ type: 'pkcs8', format: 'pem' }));
    writeFileSync('public-key.pem', publicKey.export({ type: 'spki', format: 'pem' }));
  }
}