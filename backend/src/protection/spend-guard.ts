import { ProtectionConfig } from '../common/config';
import { temporarilyUnavailable } from '../common/app-error';
import { Cost } from '../providers/pricing';

export interface SpendSnapshot {
  day: string;
  spentUsd: number;
  capUsd: number;
  killSwitch: boolean;
  inFlight: number;
}

/**
 * Global daily spend cap + kill switch + concurrency bound for MODEL calls
 * (SPEC 7.5). Counted per UTC day, in memory. A call whose cost is unknown is
 * charged `unknownCostUsd` so missing usage can never bypass the cap.
 * Free paths (safety replies, retrieval refusals) never touch this guard.
 */
export class SpendGuard {
  private day = '';
  private spent = 0;
  private inFlight = 0;

  constructor(
    private readonly cfg: Pick<ProtectionConfig, 'dailyCapUsd' | 'unknownCostUsd' | 'killSwitch' | 'maxConcurrentModelCalls'>,
    private readonly now: () => number = Date.now,
  ) {}

  private roll(): void {
    const d = new Date(this.now()).toISOString().slice(0, 10);
    if (d !== this.day) {
      this.day = d;
      this.spent = 0;
    }
  }

  /** Reserves a model-call slot or throws 503. Call release() when done. */
  acquire(): void {
    this.roll();
    if (this.cfg.killSwitch || this.spent >= this.cfg.dailyCapUsd) throw temporarilyUnavailable();
    if (this.inFlight >= this.cfg.maxConcurrentModelCalls) throw temporarilyUnavailable('busy');
    this.inFlight++;
  }

  release(): void {
    this.inFlight = Math.max(0, this.inFlight - 1);
  }

  /** Adds the cost of a finished call (or the unknown-cost charge). */
  record(cost: Cost | undefined): void {
    this.roll();
    this.spent += cost?.status === 'estimated' && cost.amountUsd !== null ? cost.amountUsd : this.cfg.unknownCostUsd;
  }

  snapshot(): SpendSnapshot {
    this.roll();
    return {
      day: this.day,
      spentUsd: Math.round(this.spent * 1e6) / 1e6,
      capUsd: this.cfg.dailyCapUsd,
      killSwitch: this.cfg.killSwitch,
      inFlight: this.inFlight,
    };
  }
}
