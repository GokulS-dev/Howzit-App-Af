import { Test, TestingModule } from '@nestjs/testing';
import { PasetoService } from './paseto.service';

describe('PasetoService', () => {
  let service: PasetoService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [PasetoService],
    }).compile();

    service = module.get<PasetoService>(PasetoService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
