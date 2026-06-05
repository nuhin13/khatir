import { z } from "zod";
import { apiFetch } from "./client";

/**
 * AI-provider data layer — EPIC-14.T-011.
 *
 * Consumes the admin AI-provider endpoints committed by EPIC-14.T-009
 * (mounted under `/admin/api/`, super/ops only):
 *
 * - `GET   /admin/api/ai-providers`                    — list every provider config.
 * - `POST  /admin/api/ai-providers`                    — create a provider (DPA-validated).
 * - `PATCH /admin/api/ai-providers/{id}`               — edit a provider (DPA-validated).
 * - `POST  /admin/api/ai-providers/{id}/test-connection` — verify creds via the gateway.
 *
 * The backend returns the resource body directly (`core.responses.success`),
 * so the list endpoint is a bare array. The plaintext `api_key` is write-only:
 * it is encrypted at rest and never returned — the read projection exposes only
 * a boolean `has_api_key`, so the UI shows a masked placeholder once a key is
 * configured and never the secret itself (task §15). Every payload is
 * zod-validated at the boundary (coding standards §5).
 */

/** AI capability category — one per tab (AICategory, enums.md). */
export const AI_CATEGORIES = ["chat", "voice", "ocr", "lease"] as const;
export type AICategory = (typeof AI_CATEGORIES)[number];

/**
 * Mirror of the backend `endpoint_is_bangladesh` rule (T-009 serializer): an
 * endpoint is BD-hosted only when its host is an explicit `.bd` domain. An empty
 * endpoint (the vendor SDK default, a foreign cloud) is treated as non-BD, so a
 * default-endpoint OCR provider still needs a DPA reference. Used purely to
 * decide whether to surface the DPA warning in the UI; the server re-validates.
 */
export function endpointIsBangladesh(endpointUrl: string): boolean {
  if (!endpointUrl) return false;
  let host: string;
  try {
    host = new URL(endpointUrl).hostname.toLowerCase();
  } catch {
    return false;
  }
  return host === "bd" || host.endsWith(".bd");
}

/** Read projection of an AIProvider (AIProviderAdminSerializer, T-009). */
export const aiProviderSchema = z.object({
  id: z.union([z.string(), z.number()]),
  category: z.enum(AI_CATEGORIES),
  provider_key: z.string(),
  is_primary: z.boolean(),
  is_fallback: z.boolean(),
  model_name: z.string(),
  endpoint_url: z.string(),
  params_json: z.unknown().nullable(),
  dpa_reference: z.string(),
  active: z.boolean(),
  // Write-only `api_key` is never returned; only this flag is.
  has_api_key: z.boolean(),
  created_at: z.string(),
  updated_at: z.string(),
});
export type AIProvider = z.infer<typeof aiProviderSchema>;

/** The editable subset of a provider (everything the form can write). */
export interface AIProviderChanges {
  category?: AICategory;
  provider_key?: string;
  is_primary?: boolean;
  is_fallback?: boolean;
  model_name?: string;
  endpoint_url?: string;
  dpa_reference?: string;
  active?: boolean;
  /** Plaintext key; sent only when the admin enters a new one. */
  api_key?: string;
}

/** Result of a test-connection call (AIProviderTestConnectionView, T-009). */
export const testConnectionResultSchema = z.union([
  z.object({
    ok: z.literal(true),
    provider_key: z.string(),
    model_name: z.string(),
  }),
  z.object({
    ok: z.literal(false),
    detail: z.string(),
  }),
]);
export type TestConnectionResult = z.infer<typeof testConnectionResultSchema>;

/** TanStack Query key for the AI-provider list. */
export const aiProvidersQueryKey = ["admin", "ai-providers"] as const;

/** Tolerates the bare-array or `{ results }`-paginated list envelope. */
const providerListSchema = z.union([
  z.array(aiProviderSchema),
  z.object({ results: z.array(aiProviderSchema) }),
]);

/** Fetch + validate every AI-provider config. */
export async function fetchAIProviders(): Promise<AIProvider[]> {
  const body = await apiFetch("/admin/api/ai-providers", providerListSchema);
  return Array.isArray(body) ? body : body.results;
}

/** Create a new provider config (DPA-validated server-side). */
export function createAIProvider(
  changes: AIProviderChanges,
): Promise<AIProvider> {
  return apiFetch("/admin/api/ai-providers", aiProviderSchema, {
    method: "POST",
    body: changes,
  });
}

/** Apply a partial change to an existing provider (DPA-validated server-side). */
export function updateAIProvider(
  id: AIProvider["id"],
  changes: AIProviderChanges,
): Promise<AIProvider> {
  return apiFetch("/admin/api/ai-providers/" + id, aiProviderSchema, {
    method: "PATCH",
    body: changes,
  });
}

/** Issue a minimal test call to verify the provider's credentials. */
export function testAIProviderConnection(
  id: AIProvider["id"],
): Promise<TestConnectionResult> {
  return apiFetch(
    "/admin/api/ai-providers/" + id + "/test-connection",
    testConnectionResultSchema,
    { method: "POST" },
  );
}
