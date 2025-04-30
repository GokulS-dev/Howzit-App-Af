import {
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { LoginUserDto } from './dto/login-user.dto';
import { PrismaService } from 'src/prisma/prisma.service';
import * as brcypt from 'bcrypt';
import * as paseto from 'paseto';
import * as fs from 'fs';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {}

  async checkIfExists(username: string, type: string): Promise<any> {
    try {
      const user = await this.prisma[type].findUnique({
        where: {
          username: username,
        },
      });
      if (user === null) {
        throw new NotFoundException(
          `This username does not exist in our records for type ${type}`,
        );
      } else {
        return user;
      }
    } catch (error) {
      throw error;
    }
  }

  async generateToken(user: any) {
    const {
      V4: { sign },
    } = paseto;
    user.secret_key = this.configService.getOrThrow('PASETO_KEY');
    const private_key = fs.readFileSync('private-key.pem');
    const token = await sign(user, private_key, { expiresIn: '300m' });
    return token;
  }

  async loginUser(loginUserDto: LoginUserDto) {
    const user = await this.checkIfExists(
      loginUserDto.username,
      loginUserDto.type,
    );
    const isMatch = await brcypt.compare(loginUserDto.password, user.password);
    if (isMatch) {
      const data = {
        username: user.username,
        id: user.id,
        type: loginUserDto.type,
        country: user.country,
      };
      const token = await this.generateToken(data);
      return {
        message: 'Success',
        accessToken: token,
        userId: data.id,
        username: data.username,
        country: data.country,
      };
    } else {
      throw new UnauthorizedException('Incorrect Password');
    }
  }
}
