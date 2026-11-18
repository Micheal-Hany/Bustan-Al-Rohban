import { ProviderError } from './llm.port';

export type FetchFn = typeof fetch;

/** Maps an HTTP status to a provider error kind (no body is ever kept). */
export function kindForStatus(status: number): ProviderError {
  if (status === 401 || status === 403) return new ProviderError('auth');
  if (status === 429) return new ProviderError('rate_limited');
  if (status === 408 || status === 504) return new ProviderError('timeout');
  if (status >= 500) return new ProviderError('server');
  return new ProviderError('bad_request');
}

/** POSTs JSON with a hard timeout; returns the parsed JSON body. */
export async function postJson(
  fetchFn: FetchFn,
  url: string,
  headers: Record<string, string>,
  body: unknown,
  timeoutMs: number,
): Promise<unknown> {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetchFn(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json', ...headers },
      body: JSON.stringify(body),
      signal: ctrl.signal,
    });
    if (!res.ok) throw kindForStatus(res.status);
    try {
      return await res.json();
    } catch {
      if (ctrl.signal.aborted) throw new ProviderError('timeout');
      throw new ProviderError('bad_response');
    }
  } catch (e) {
    if (e instanceof ProviderError) throw e;
    if (ctrl.signal.aborted) throw new ProviderError('timeout');
    throw new ProviderError('network');
  } finally {
    clearTimeout(timer);
  }
}

export const num = (v: unknown): number | undefined =>
  typeof v === 'number' && Number.isFinite(v) && v >= 0 ? v : undefined;
