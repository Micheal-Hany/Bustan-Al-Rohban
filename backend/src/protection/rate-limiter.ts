import { RateLimitConfig } from '../common/config';

/**
 * Fixed-window counter per key, in memory (single instance; see
 * docs/ABUSE_PROTECTION.md for the residual risk). Keys are opaque ids
 * (an IP address or an installation id); no chat content is ever stored.
 */
export class RateLimiter {
  private readonly hits = new Map<string, { start: number; count: number }>();
  private calls = 0;

  constructor(
    private readonly cfg: RateLimitConfig,
    private readonly now: () => number = Date.now,
  ) {}

  /** Counts one request. Returns null when allowed, else seconds to wait. */
  hit(key: string): number | null {
    const t = this.now();
    const windowMs = this.cfg.windowSeconds * 1000;
    if (++this.calls % 500 === 0) this.sweep(t, windowMs);
    const cur = this.hits.get(key);
    if (!cur || t - cur.start >= windowMs) {
      this.hits.set(key, { start: t, count: 1 });
      return null;
    }
    if (cur.count >= this.cfg.max) return Math.max(1, Math.ceil((cur.start + windowMs - t) / 1000));
    cur.count++;
    return null;
  }

  private sweep(t: number, windowMs: number): void {
    for (const [k, v] of this.hits) if (t - v.start >= windowMs) this.hits.delete(k);
  }

  get size(): number {
    return this.hits.size;
  }
}
