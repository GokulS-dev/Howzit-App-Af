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
  constructor(private configService: ConfigService) {}

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
      const publicKey = fs.readFileSync('public-key.pem');
      const payload = await verify(token, publicKey);
      if (
        payload['secret_key'] === this.configService.getOrThrow('PASETO_KEY')
      ) {
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
