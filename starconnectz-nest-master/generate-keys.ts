import { generateKeyPair } from 'crypto';
import * as fs from 'fs/promises';

// generate Ed25519 key pair
generateKeyPair(
  'ed25519',
  {
    publicKeyEncoding: { type: 'spki', format: 'pem' },
    privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
  },
  async (err, publicKey, privateKey) => {
    if (err) throw err;

    await fs.writeFile('public-key.pem', publicKey);
    await fs.writeFile('private-key.pem', privateKey);

    console.log('✅ Ed25519 key pair generated and saved');
  }
);
