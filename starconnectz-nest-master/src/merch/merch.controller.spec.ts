import { Test, TestingModule } from '@nestjs/testing';
import { MerchController } from './merch.controller';

describe('MerchController', () => {
  let controller: MerchController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [MerchController],
    }).compile();

    controller = module.get<MerchController>(MerchController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
