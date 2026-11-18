import { readFileSync } from 'node:fs';
import { z } from 'zod';
import { LlmUsage } from './llm.port';

const pricingSchema = z
  .object({
    version: z.string().min(1),
    currency: z.literal('USD'),
    note: z.string().optional(),
    models: z.record(
      z.string(),
      z.object({ inputPerMTok: z.number().min(0), outputPerMTok: z.number().min(0) }).strict(),
    ),
  })
  .strict();

export type PricingTable = z.infer<typeof pricingSchema>;

export function loadPricing(file: string): PricingTable {
  const r = pricingSchema.safeParse(JSON.parse(readFileSync(file, 'utf8')));
  if (!r.success) throw new Error('Invalid pricing file.');
  return r.data;
}

export interface Cost {
  /** Always an estimate: provider invoices are the truth. */
  status: 'estimated' | 'unavailable';
  amountUsd: number | null;
  pricingVersion: string;
  reason?: 'usage_missing' | 'no_pricing';
}

/** Estimated USD cost of one request from its token usage and the price table. */
export function estimateCost(
  table: PricingTable,
  provider: string,
  model: string,
  usage: LlmUsage | undefined,
): Cost {
  const base = { pricingVersion: table.version };
  if (usage?.inputTokens === undefined || usage.outputTokens === undefined) {
    return { ...base, status: 'unavailable', amountUsd: null, reason: 'usage_missing' };
  }
  const price = table.models[`${provider}:${model}`];
  if (!price) return { ...base, status: 'unavailable', amountUsd: null, reason: 'no_pricing' };
  const usd = (usage.inputTokens * price.inputPerMTok + usage.outputTokens * price.outputPerMTok) / 1_000_000;
  return { ...base, status: 'estimated', amountUsd: Math.round(usd * 1e8) / 1e8 };
}
