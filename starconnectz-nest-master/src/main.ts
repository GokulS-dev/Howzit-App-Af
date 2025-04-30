// // import { NestFactory } from '@nestjs/core';
// // import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
// // import { AppModule } from './app.module';
// // import { ValidationPipe } from '@nestjs/common';
// //
// // async function bootstrap() {
// //   const app = await NestFactory.create(AppModule);
// //
// //   // Swagger Configuration
// //   const config = new DocumentBuilder()
// //     .setTitle('Howzit API')
// //     .setDescription('Backend API for Howzit/Starconnectz')
// //     .setVersion('1.0')
// //     .build();
// //
// //   const document = SwaggerModule.createDocument(app, config);
// //   SwaggerModule.setup('api', app, document);
// //
// //   // Global validation
// //   app.useGlobalPipes(
// //     new ValidationPipe({
// //       whitelist: true, // Removes non-decorated properties
// //       forbidNonWhitelisted: true, // Throws if unexpected fields are sent
// //     }),
// //   );
// //
// //   // Listen on all network interfaces (for public access)
// //   await app.listen(3000, '0.0.0.0');
// // }
// // bootstrap();
//
// // src/main.ts
// import { NestFactory } from '@nestjs/core';
// import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
// import { AppModule } from './app.module';
// import { ValidationPipe } from '@nestjs/common';
//
// async function bootstrap() {
//   const app = await NestFactory.create(AppModule);
//
//   const config = new DocumentBuilder()
//     .setTitle('Howzit API')
//     .setDescription('Backend API for Howzit/Starconnectz')
//     .setVersion('1.0')
//     .build();
//
//   const document = SwaggerModule.createDocument(app, config);
//   SwaggerModule.setup('api', app, document);
//
//   app.useGlobalPipes(
//     new ValidationPipe({
//       whitelist: true,
//       forbidNonWhitelisted: true,
//     }),
//   );
//
//   const port = process.env.PORT || 3000;
//   await app.listen(port);
//   console.log(`Server running on http://localhost:${port}`);
// }
// bootstrap();

import * as dotenv from 'dotenv';
dotenv.config();

import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  const config = new DocumentBuilder()
    .setTitle('Howzit API')
    .setDescription('Backend API for Howzit/Starconnectz')
    .setVersion('1.0')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document);

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
    }),
  );

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`Server running on http://localhost:${port}`);
}
bootstrap();