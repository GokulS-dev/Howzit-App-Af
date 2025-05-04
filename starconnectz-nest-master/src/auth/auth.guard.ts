import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import * as paseto from 'paseto';
import * as fs from 'fs';
import { Request } from 'express';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AuthGuard implements CanActivate {
  private readonly pasetoKey: string;

  constructor(private configService: ConfigService) {
    // Get PASETO_KEY from config
    this.pasetoKey = this.configService.getOrThrow('PASETO_KEY');
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const token = this.extractTokenFromHeader(request);
    if (!token) {
      throw new UnauthorizedException();
    }
    try {
      const {
        V4: { verify },
      } = paseto;

      // Load the public key for verification
      const publicKey = fs.readFileSync(this.pasetoKey, 'utf8');

      // Verify the token
      const payload = await verify(token, publicKey);
      if (payload['secret_key'] === this.pasetoKey) {
        request['user'] = payload;
      }
    } catch (error) {
      throw new UnauthorizedException(
        'Token invalid or expired. Please login again',
      );
    }
    return true;
  }

  private extractTokenFromHeader(request: Request): string | undefined {
    if (!request.headers.authorization) {
      throw new UnauthorizedException();
    }
    const [type, token] = request.headers.authorization.split(' ') ?? [];
    return type === 'Bearer' ? token : undefined;
  }
}