import { Test, TestingModule } from '@nestjs/testing';
import { MerchService } from './merch.service';

describe('MerchService', () => {
  let service: MerchService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [MerchService],
    }).compile();

    service = module.get<MerchService>(MerchService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
