import { Controller, Get, Inject } from '@nestjs/common';
import { CorpusService } from '../sources/corpus.service';

@Controller()
export class HealthController {
  constructor(@Inject(CorpusService) private readonly corpus: CorpusService) {}

  /** Liveness plus corpus facts. Never returns book or user text. */
  @Get('health')
  health() {
    const c = this.corpus.corpus;
    return {
      status: 'ok',
      corpus: {
        bookId: c.bookId,
        contentVersion: c.contentVersion,
        fixture: c.fixture,
        saints: c.saints.length,
        passages: c.passages.length,
      },
    };
  }
}
