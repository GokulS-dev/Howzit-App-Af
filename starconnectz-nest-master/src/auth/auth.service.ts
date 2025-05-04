import {
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { LoginUserDto } from './dto/login-user.dto';
import { PrismaService } from 'src/prisma/prisma.service';
import * as bcrypt from 'bcrypt';
import { V4 as paseto } from 'paseto';
import * as fs from 'fs';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AuthService {
  private readonly privateKeyPath: string;

  constructor(
    private prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {
    this.privateKeyPath =
      this.configService.get('PRIVATE_KEY_PATH') || 'private-key.pem';
    console.log('🔐 Using PASETO private key at:', this.privateKeyPath);
  }

  async checkIfExists(username: string, type: string): Promise<any> {
    const user = await this.prisma[type].findUnique({
      where: { username },
    });

    if (!user) {
      throw new NotFoundException(
        `This username does not exist for type ${type}`,
      );
    }

    return user;
  }

  async generateToken(payload: Record<string, any>): Promise<string> {
    const privateKey = fs.readFileSync(this.privateKeyPath, 'utf8');
    const token = await paseto.sign(payload, privateKey, {
      expiresIn: '5h',
    });
    return token;
  }

  async loginUser(loginUserDto: LoginUserDto): Promise<any> {
    const user = await this.checkIfExists(
      loginUserDto.username,
      loginUserDto.type,
    );

    const isMatch = await bcrypt.compare(
      loginUserDto.password,
      user.password,
    );

    if (!isMatch) {
      throw new UnauthorizedException('Incorrect Password');
    }

    const payload = {
      username: user.username,
      id: user.id,
      type: loginUserDto.type,
      country: user.country,
    };

    const token = await this.generateToken(payload);

    return {
      message: 'Success',
      accessToken: token,
      userId: user.id,
      username: user.username,
      country: user.country,
    };
  }
}