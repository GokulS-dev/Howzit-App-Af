import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';

@Injectable()
export class ValidationGuard implements CanActivate {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    if (JSON.stringify(request.params) != '{}') {
      if (request.params.username) {
        const check = request.params.username === request.user.username;
        if (!check) {
          throw new UnauthorizedException(
            'This user does not have the permission to access this resource',
          );
        } else return true;
      }
      if (request.params.id) {
        const check = request.params.id === request.user.id;
        if (!check) {
          throw new UnauthorizedException(
            'This user does not have the permission to access this resource',
          );
        } else return true;
      }
    }
    if (JSON.stringify(request.body) != '{}') {
      if (request.body.username) {
        const check = request.body.username === request.user.username;
        if (!check) {
          throw new UnauthorizedException(
            'This user does not have the permission to access this resource',
          );
        } else return true;
      }
      if (request.body.id) {
        const check = request.body.id === request.user.id;
        if (!check) {
          throw new UnauthorizedException(
            'This user does not have the permission to access this resource',
          );
        } else return true;
      }
    }
    return true;
  }
}
