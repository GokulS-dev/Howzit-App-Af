import { Body, Controller, Post, ValidationPipe } from '@nestjs/common';
import { LoginUserDto } from './dto/login-user.dto';
import { AuthService } from './auth.service';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

@Controller('auth')
@ApiTags('Auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('login')
  @ApiOperation({ summary: 'User login' }) // Adding the summary for Swagger
  async loginUser(@Body(ValidationPipe) loginUserDto: LoginUserDto) {
    return await this.authService.loginUser(loginUserDto);
  }
}
