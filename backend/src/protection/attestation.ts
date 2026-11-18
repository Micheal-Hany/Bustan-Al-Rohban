import { createHash, createSign } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { ProtectionConfig } from '../common/config';
import { FetchFn } from '../providers/http';

export type AttestationResult =
  | { ok: true }
  | { ok: false; reason: 'missing' | 'invalid' | 'unavailable' };

/** Contract: the client's nonce is base64url(sha256(requestId)), no padding. */
export const nonceFor = (requestId: string): string =>
  createHash('sha256').update(requestId).digest('base64url');

export interface AttestationVerifier {
  verify(token: string | undefined, requestId: string | undefined): Promise<AttestationResult>;
}
export const ATTESTATION = 'ATTESTATION';

/** mode=off: dev only. createApp refuses it in production. */
export class NoAttestation implements AttestationVerifier {
  verify(): Promise<AttestationResult> {
    return Promise.resolve({ ok: true });
  }
}

/** mode=test: accepts exactly the configured token. For dev/CI/emulators. */
export class TestAttestation implements AttestationVerifier {
  constructor(private readonly token: string) {}
  verify(token: string | undefined, _requestId?: string): Promise<AttestationResult> {
    if (!token) return Promise.resolve({ ok: false, reason: 'missing' });
    return Promise.resolve(token === this.token ? { ok: true } : { ok: false, reason: 'invalid' });
  }
}

export interface PlayIntegrityOptions {
  packageName: string;
  certDigests: string[];
  maxTokenAgeSeconds: number;
  /** Returns a Google OAuth access token for the playintegrity scope. */
  accessToken: () => Promise<string>;
  fetchFn?: FetchFn;
  now?: () => number;
  timeoutMs?: number;
}

interface DecodedPayload {
  requestDetails?: { requestPackageName?: string; nonce?: string; timestampMillis?: string };
  appIntegrity?: { appRecognitionVerdict?: string; packageName?: string; certificateSha256Digest?: string[] };
  deviceIntegrity?: { deviceRecognitionVerdict?: string[] };
}

/**
 * Google Play Integrity verdict check, done server-side by Google's
 * decodeIntegrityToken. Fails closed: if Google cannot be reached the request
 * is refused (503), never waved through.
 * NOT yet exercised against the real Google service: tested with mocks only.
 */
export class PlayIntegrityVerifier implements AttestationVerifier {
  constructor(private readonly o: PlayIntegrityOptions) {}

  async verify(token: string | undefined, requestId: string | undefined): Promise<AttestationResult> {
    if (!token) return { ok: false, reason: 'missing' };
    if (!requestId) return { ok: false, reason: 'invalid' }; // nonce is bound to the requestId
    let payload: DecodedPayload;
    try {
      const ctrl = new AbortController();
      const timer = setTimeout(() => ctrl.abort(), this.o.timeoutMs ?? 5000);
      try {
        const res = await (this.o.fetchFn ?? fetch)(
          `https://playintegrity.googleapis.com/v1/${encodeURIComponent(this.o.packageName)}:decodeIntegrityToken`,
          {
            method: 'POST',
            headers: { 'content-type': 'application/json', authorization: `Bearer ${await this.o.accessToken()}` },
            body: JSON.stringify({ integrity_token: token }),
            signal: ctrl.signal,
          },
        );
        // 400 = Google says the token itself is malformed/expired: that is "invalid".
        if (res.status === 400) return { ok: false, reason: 'invalid' };
        if (!res.ok) return { ok: false, reason: 'unavailable' };
        payload = ((await res.json()) as { tokenPayloadExternal?: DecodedPayload }).tokenPayloadExternal ?? {};
      } finally {
        clearTimeout(timer);
      }
    } catch {
      return { ok: false, reason: 'unavailable' };
    }
    const rd = payload.requestDetails;
    const ts = Number(rd?.timestampMillis);
    const now = (this.o.now ?? Date.now)();
    const fresh = Number.isFinite(ts) && Math.abs(now - ts) <= this.o.maxTokenAgeSeconds * 1000;
    const digests = payload.appIntegrity?.certificateSha256Digest ?? [];
    const certOk = this.o.certDigests.length === 0 || digests.some((d) => this.o.certDigests.includes(d));
    const ok =
      rd?.requestPackageName === this.o.packageName &&
      rd?.nonce === nonceFor(requestId) &&
      fresh &&
      payload.appIntegrity?.appRecognitionVerdict === 'PLAY_RECOGNIZED' &&
      payload.appIntegrity?.packageName === this.o.packageName &&
      certOk &&
      (payload.deviceIntegrity?.deviceRecognitionVerdict ?? []).includes('MEETS_DEVICE_INTEGRITY');
    return ok ? { ok: true } : { ok: false, reason: 'invalid' };
  }
}

/** OAuth access token from a Google service-account key file (JWT bearer flow). */
export function serviceAccountTokenProvider(
  file: string,
  fetchFn: FetchFn = fetch,
  now: () => number = Date.now,
): () => Promise<string> {
  const key = JSON.parse(readFileSync(file, 'utf8')) as { client_email: string; private_key: string };
  let cached: { token: string; expires: number } | undefined;
  const b64 = (o: unknown) => Buffer.from(JSON.stringify(o)).toString('base64url');
  return async () => {
    if (cached && cached.expires - 60_000 > now()) return cached.token;
    const iat = Math.floor(now() / 1000);
    const unsigned = `${b64({ alg: 'RS256', typ: 'JWT' })}.${b64({
      iss: key.client_email,
      scope: 'https://www.googleapis.com/auth/playintegrity',
      aud: 'https://oauth2.googleapis.com/token',
      iat,
      exp: iat + 3600,
    })}`;
    const sig = createSign('RSA-SHA256').update(unsigned).sign(key.private_key, 'base64url');
    const res = await fetchFn('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: `${unsigned}.${sig}` }),
    });
    if (!res.ok) throw new Error('token_unavailable');
    const j = (await res.json()) as { access_token?: string; expires_in?: number };
    if (!j.access_token) throw new Error('token_unavailable');
    cached = { token: j.access_token, expires: now() + (j.expires_in ?? 3600) * 1000 };
    return cached.token;
  };
}

export function createAttestationVerifier(cfg: ProtectionConfig['attestation'], fetchFn?: FetchFn): AttestationVerifier {
  if (cfg.mode === 'off') return new NoAttestation();
  if (cfg.mode === 'test') return new TestAttestation(cfg.testToken ?? '');
  return new PlayIntegrityVerifier({
    packageName: cfg.packageName ?? '',
    certDigests: cfg.certDigests,
    maxTokenAgeSeconds: cfg.maxTokenAgeSeconds,
    accessToken: serviceAccountTokenProvider(cfg.serviceAccountFile ?? '', fetchFn),
    fetchFn,
  });
}
