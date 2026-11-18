import { Inject, Injectable } from '@nestjs/common';
import { APP_CONFIG, AppConfig } from '../common/config';
import { assertDeployable, loadCorpus } from './corpus.loader';
import { Corpus } from './corpus.types';

/** Holds the immutable, in-memory book corpus (loaded once at startup). */
@Injectable()
export class CorpusService {
  readonly corpus: Corpus;

  constructor(@Inject(APP_CONFIG) config: AppConfig) {
    this.corpus = loadCorpus(config.corpusDir);
    assertDeployable(this.corpus, config.nodeEnv);
    Object.freeze(this.corpus.passages);
  }
}
