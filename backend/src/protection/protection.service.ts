import { Inject, Injectable } from '@nestjs/common';
import { AppError, tooManyRequests } from '../common/app-error';
import { APP_CONFIG, AppConfig } from '../common/config';
import { ATTESTATION, AttestationVerifier } from './attestation';
import { RateLimiter } from './rate-limiter';

export const PROTECTION_NOW = 'PROTECTION_NOW';

/**
 * Admission control for the chat and report endpoints (SPEC 7.5), in this order:
 * per-IP limit (cheap, before any parsing or Google call) -> [caller parses and
 * bounds the body] -> attestation -> per-installation limit. A client-supplied
 * installation id is NOT authentication, so the IP limit always applies too.
 */
@Injectable()
export class ProtectionService {
  private readonly ip: RateLimiter;
  private readonly installation: RateLimiter;

  constructor(
    @Inject(APP_CONFIG) config: AppConfig,
    @Inject(ATTESTATION) private readonly attestation: AttestationVerifier,
  ) {
    this.ip = new RateLimiter(config.protection.ipLimit);
    this.installation = new RateLimiter(config.protection.installationLimit);
  }

  admitIp(ip: string | undefined): void {
    const wait = this.ip.hit(`ip:${ip ?? 'unknown'}`);
    if (wait !== null) throw tooManyRequests(wait);
  }

  async admitClient(c: { installationId?: string; attestationToken?: string; requestId?: string }): Promise<void> {
    const a = await this.attestation.verify(c.attestationToken, c.requestId);
    if (!a.ok) {
      if (a.reason === 'unavailable') throw new AppError(503, 'attestation_unavailable', 'Could not verify the app. Try again later.');
      throw new AppError(
        403,
        a.reason === 'missing' ? 'attestation_required' : 'attestation_failed',
        'This request could not be verified.',
      );
    }
    if (c.installationId) {
      const wait = this.installation.hit(`inst:${c.installationId}`);
      if (wait !== null) throw tooManyRequests(wait);
    }
  }
}
