import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import * as paseto from 'paseto';
import * as fs from 'fs';
import { Request } from 'express';

@Injectable()
export class AuthGuard implements CanActivate {
  private readonly publicKeyPath = 'public-key.pem'; // or read from env if you want

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

      const publicKey = fs.readFileSync(this.publicKeyPath, 'utf8');
      const payload = await verify(token, publicKey);

      // If needed, you can add more checks here
      request['user'] = payload;
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