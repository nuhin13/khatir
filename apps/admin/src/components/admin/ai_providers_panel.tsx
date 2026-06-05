"use client";

import { useMemo, useState } from "react";
import { AlertTriangle, Bot, CheckCircle2, XCircle } from "lucide-react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Chip } from "@/components/ui/chip";
import { Toggle } from "@/components/ui/toggle";
import {
  AI_CATEGORIES,
  aiProvidersQueryKey,
  createAIProvider,
  endpointIsBangladesh,
  fetchAIProviders,
  testAIProviderConnection,
  updateAIProvider,
  type AICategory,
  type AIProvider,
  type AIProviderChanges,
  type TestConnectionResult,
} from "@/lib/api/ai-providers";

/**
 * AI-providers configuration panel — EPIC-14.T-011.
 *
 * The four-category provider editor from `04_Admin_Portal_Khatir.md` §4.6
 * (Chat / Voice / OCR / Lease). Each tab lists the providers configured for
 * that category — their primary/fallback role, model, masked key status — and
 * offers an inline edit form (vendor, model, API key, endpoint, primary/
 * fallback) plus a "Test connection" button that hits the gateway and shows the
 * pass/fail result. The OCR tab additionally surfaces the NID data-residency
 * (DPA) warning whenever the chosen endpoint is non-Bangladesh, mirroring the
 * server-side save-time rule in `ai_providers/serializers.py` (T-009): a non-BD
 * OCR provider cannot be saved without a `dpa_reference`.
 *
 * The super/ops route guard lives in the server page that renders this. The
 * stored API key is never returned by the API (only `has_api_key`); the UI
 * shows a masked placeholder once configured and only ever sends a new key when
 * the admin types one (task §15). All colours/spacing/radii come from Notun Din
 * token classes — no hardcoded prototype hex/px.
 */

/** Tab labels per the spec §4.6.1 table. */
const CATEGORY_LABELS: Record<AICategory, string> = {
  chat: "Chat / LLM",
  voice: "Voice / ASR",
  ocr: "OCR / Vision",
  lease: "Lease generation",
};

/** Suggested vendors per category (spec §4.6.1) — free-text is also allowed. */
const CATEGORY_VENDORS: Record<AICategory, readonly string[]> = {
  chat: ["openai", "anthropic", "openrouter", "google_gemini", "ollama"],
  voice: ["verbex", "google_speech", "openai_whisper", "azure_speech", "whisper_self_hosted"],
  ocr: ["google_vision", "azure_document_intelligence", "aws_textract", "tesseract"],
  lease: ["anthropic", "openai", "google_gemini"],
};

export function AIProvidersPanel() {
  const [category, setCategory] = useState<AICategory>("ocr");
  const { data, isPending, isError, refetch } = useQuery({
    queryKey: aiProvidersQueryKey,
    queryFn: fetchAIProviders,
  });

  return (
    <div className="space-y-s6">
      <div>
        <h1 className="font-title text-2xl font-bold text-ink">AI providers</h1>
        <p className="mt-s1 text-sm text-muted">
          Swap AI providers without code changes. Configure the primary and
          fallback provider per category, then test the connection before it
          goes live. Every change is audit-logged.
        </p>
      </div>

      <CategoryTabs active={category} onSelect={setCategory} />

      {isPending ? (
        <Card
          className="h-64 animate-pulse"
          aria-busy
          aria-label="Loading AI providers"
        />
      ) : isError ? (
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Could not load AI providers</CardTitle>
          <CardDescription>
            The AI-provider request failed. Check your connection and try again.
          </CardDescription>
          <Button onClick={() => void refetch()}>Retry</Button>
        </Card>
      ) : (
        <CategoryPanel
          category={category}
          providers={data.filter((p) => p.category === category)}
        />
      )}
    </div>
  );
}

interface CategoryTabsProps {
  active: AICategory;
  onSelect: (category: AICategory) => void;
}

function CategoryTabs({ active, onSelect }: CategoryTabsProps) {
  return (
    <div role="tablist" aria-label="AI category" className="flex flex-wrap gap-s2">
      {AI_CATEGORIES.map((cat) => {
        const selected = cat === active;
        return (
          <button
            key={cat}
            type="button"
            role="tab"
            aria-selected={selected}
            onClick={() => onSelect(cat)}
            className={
              "rounded-button px-s4 py-s2 font-title text-sm font-semibold transition-colors " +
              (selected
                ? "bg-ink text-card"
                : "bg-sageBg text-ink hover:bg-line")
            }
          >
            {CATEGORY_LABELS[cat]}
          </button>
        );
      })}
    </div>
  );
}

interface CategoryPanelProps {
  category: AICategory;
  providers: AIProvider[];
}

function CategoryPanel({ category, providers }: CategoryPanelProps) {
  const [editing, setEditing] = useState<AIProvider | "new" | null>(null);
  const primary = providers.find((p) => p.is_primary);
  const fallback = providers.find((p) => p.is_fallback);

  return (
    <div
      role="tabpanel"
      aria-label={CATEGORY_LABELS[category]}
      className="space-y-s5"
    >
      <div className="grid gap-s4 sm:grid-cols-2">
        <ActiveSummary label="Primary provider" provider={primary} />
        <ActiveSummary label="Fallback provider" provider={fallback} />
      </div>

      <div className="overflow-hidden rounded-card border border-line bg-card shadow-sm">
        <div className="flex items-center justify-between border-b border-line px-s5 py-s4">
          <div>
            <h2 className="font-title text-base font-bold text-ink">
              {CATEGORY_LABELS[category]} providers
            </h2>
            <p className="mt-s1 text-xs text-muted">
              {providers.length} configured · API keys are encrypted at rest
            </p>
          </div>
          <Button onClick={() => setEditing("new")}>Add provider</Button>
        </div>

        {providers.length === 0 ? (
          <div className="flex flex-col items-center gap-s2 px-s5 py-s8 text-center">
            <Bot size={24} className="text-muted" aria-hidden />
            <p className="text-sm text-muted">
              No providers configured for this category yet.
            </p>
          </div>
        ) : (
          <ul className="divide-y divide-line">
            {providers.map((provider) => (
              <li
                key={provider.id}
                className="flex items-center justify-between gap-s4 px-s5 py-s4"
              >
                <div className="min-w-0">
                  <div className="flex items-center gap-s2">
                    <span className="font-title text-sm font-semibold text-ink">
                      {provider.provider_key}
                    </span>
                    {provider.is_primary ? (
                      <Chip tone="sage">Primary</Chip>
                    ) : null}
                    {provider.is_fallback ? (
                      <Chip tone="butter">Fallback</Chip>
                    ) : null}
                    {provider.active ? (
                      <Chip tone="sage">Active</Chip>
                    ) : (
                      <Chip tone="neutral">Inactive</Chip>
                    )}
                  </div>
                  <div className="mt-s1 truncate font-mono text-xs text-muted">
                    {provider.model_name || "—"}
                    {provider.has_api_key ? " · key ••••••••••" : " · no key"}
                  </div>
                </div>
                <Button variant="secondary" onClick={() => setEditing(provider)}>
                  Edit
                </Button>
              </li>
            ))}
          </ul>
        )}
      </div>

      {editing !== null ? (
        <ProviderForm
          category={category}
          provider={editing === "new" ? null : editing}
          onClose={() => setEditing(null)}
        />
      ) : null}
    </div>
  );
}

interface ActiveSummaryProps {
  label: string;
  provider: AIProvider | undefined;
}

function ActiveSummary({ label, provider }: ActiveSummaryProps) {
  return (
    <Card>
      <CardTitle className="text-xs uppercase tracking-wide text-muted">
        {label}
      </CardTitle>
      {provider ? (
        <>
          <p className="mt-s1 font-title text-base font-bold text-ink">
            {provider.provider_key}
          </p>
          <p className="mt-s1 font-mono text-xs text-muted">
            {provider.model_name || "—"}
          </p>
        </>
      ) : (
        <p className="mt-s1 text-sm text-muted">Not configured</p>
      )}
    </Card>
  );
}

interface ProviderFormProps {
  category: AICategory;
  /** The provider being edited, or `null` for a new one. */
  provider: AIProvider | null;
  onClose: () => void;
}

const INPUT_CLASS =
  "mt-s2 w-full rounded-input border border-line bg-card px-s3 py-s2 font-body text-sm text-ink placeholder:text-muted focus:border-sage focus:outline-none";

function ProviderForm({ category, provider, onClose }: ProviderFormProps) {
  const queryClient = useQueryClient();
  const [providerKey, setProviderKey] = useState(provider?.provider_key ?? "");
  const [modelName, setModelName] = useState(provider?.model_name ?? "");
  const [endpointUrl, setEndpointUrl] = useState(provider?.endpoint_url ?? "");
  const [dpaReference, setDpaReference] = useState(provider?.dpa_reference ?? "");
  const [apiKey, setApiKey] = useState("");
  const [isPrimary, setIsPrimary] = useState(provider?.is_primary ?? false);
  const [isFallback, setIsFallback] = useState(provider?.is_fallback ?? false);
  const [active, setActive] = useState(provider?.active ?? true);

  // The DPA warning mirrors the backend rule: an OCR provider on a non-BD
  // endpoint must carry a DPA reference before it can be saved (T-009).
  const dpaRequired = useMemo(
    () => category === "ocr" && !endpointIsBangladesh(endpointUrl),
    [category, endpointUrl],
  );
  const dpaBlocking = dpaRequired && dpaReference.trim().length === 0;

  const save = useMutation({
    mutationFn: () => {
      const changes: AIProviderChanges = {
        category,
        provider_key: providerKey.trim(),
        model_name: modelName.trim(),
        endpoint_url: endpointUrl.trim(),
        dpa_reference: dpaReference.trim(),
        is_primary: isPrimary,
        is_fallback: isFallback,
        active,
      };
      // Only send a key when the admin actually typed a new one — an empty
      // field leaves the encrypted key untouched (it is never returned).
      if (apiKey.length > 0) changes.api_key = apiKey;
      return provider
        ? updateAIProvider(provider.id, changes)
        : createAIProvider(changes);
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: aiProvidersQueryKey });
      onClose();
    },
  });

  return (
    <div
      role="presentation"
      onClick={onClose}
      className="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 p-s4"
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-label={provider ? "Edit AI provider" : "Add AI provider"}
        onClick={(e) => e.stopPropagation()}
        className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-card bg-card shadow-lg"
      >
        <header className="border-b border-line px-s5 py-s4">
          <h2 className="font-title text-base font-extrabold text-ink">
            {provider ? "Edit provider" : "Add provider"}
          </h2>
          <p className="mt-s1 text-xs text-muted">{CATEGORY_LABELS[category]}</p>
        </header>

        <div className="space-y-s4 px-s5 py-s5">
          <label className="block">
            <span className="font-title text-xs font-semibold text-mutedDk">
              Vendor
            </span>
            <input
              list="ai-vendor-options"
              value={providerKey}
              onChange={(e) => setProviderKey(e.target.value)}
              placeholder="e.g. openai"
              className={INPUT_CLASS}
            />
            <datalist id="ai-vendor-options">
              {CATEGORY_VENDORS[category].map((v) => (
                <option key={v} value={v} />
              ))}
            </datalist>
          </label>

          <label className="block">
            <span className="font-title text-xs font-semibold text-mutedDk">
              Model
            </span>
            <input
              value={modelName}
              onChange={(e) => setModelName(e.target.value)}
              placeholder="e.g. gpt-4o"
              className={INPUT_CLASS}
            />
          </label>

          <label className="block">
            <span className="font-title text-xs font-semibold text-mutedDk">
              API key
            </span>
            <input
              type="password"
              value={apiKey}
              onChange={(e) => setApiKey(e.target.value)}
              placeholder={
                provider?.has_api_key
                  ? "•••••••••• (leave blank to keep current)"
                  : "Enter API key"
              }
              autoComplete="off"
              className={INPUT_CLASS}
            />
          </label>

          <label className="block">
            <span className="font-title text-xs font-semibold text-mutedDk">
              Endpoint URL{" "}
              <span className="font-body font-normal text-muted">
                (self-hosted / OpenAI-compatible only)
              </span>
            </span>
            <input
              value={endpointUrl}
              onChange={(e) => setEndpointUrl(e.target.value)}
              placeholder="https://…"
              className={INPUT_CLASS}
            />
          </label>

          {dpaRequired ? (
            <div className="space-y-s3">
              <div
                role="alert"
                className="flex items-start gap-s3 rounded-card border border-butter bg-butterBg px-s4 py-s3"
              >
                <AlertTriangle
                  size={18}
                  className="mt-s1 flex-shrink-0 text-butterDk"
                  aria-hidden
                />
                <div>
                  <p className="font-title text-sm font-bold text-butterDk">
                    Data residency warning
                  </p>
                  <p className="mt-s1 text-xs text-mutedDk">
                    NID OCR data may not leave Bangladesh without a signed Data
                    Processing Agreement. This endpoint is not BD-hosted — enter
                    the DPA reference before saving.
                  </p>
                </div>
              </div>
              <label className="block">
                <span className="font-title text-xs font-semibold text-mutedDk">
                  DPA reference
                </span>
                <input
                  value={dpaReference}
                  onChange={(e) => setDpaReference(e.target.value)}
                  placeholder="e.g. DPA-2026-014"
                  className={INPUT_CLASS}
                />
              </label>
            </div>
          ) : null}

          <div className="space-y-s3 rounded-card border border-line px-s4 py-s3">
            <ToggleRow
              label="Primary provider"
              checked={isPrimary}
              onChange={setIsPrimary}
            />
            <ToggleRow
              label="Fallback provider"
              checked={isFallback}
              onChange={setIsFallback}
            />
            <ToggleRow label="Active" checked={active} onChange={setActive} />
          </div>

          {provider ? <TestConnectionRow providerId={provider.id} /> : null}

          {save.isError ? (
            <p role="alert" className="text-sm text-roseDk">
              Could not save the provider.
              {dpaBlocking
                ? " A DPA reference is required for a non-BD OCR provider."
                : " Check the fields and try again."}
            </p>
          ) : null}
        </div>

        <footer className="flex items-center justify-end gap-s3 border-t border-line px-s5 py-s4">
          <Button variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button
            onClick={() => save.mutate()}
            disabled={
              save.isPending || providerKey.trim().length === 0 || dpaBlocking
            }
          >
            {save.isPending ? "Saving…" : "Save provider"}
          </Button>
        </footer>
      </div>
    </div>
  );
}

interface ToggleRowProps {
  label: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
}

function ToggleRow({ label, checked, onChange }: ToggleRowProps) {
  return (
    <div className="flex items-center justify-between">
      <span className="text-sm text-ink">{label}</span>
      <Toggle checked={checked} onChange={onChange} label={label} />
    </div>
  );
}

interface TestConnectionRowProps {
  providerId: AIProvider["id"];
}

/** "Test connection" button — issues a minimal gateway call and shows the result. */
function TestConnectionRow({ providerId }: TestConnectionRowProps) {
  const [result, setResult] = useState<TestConnectionResult | null>(null);
  const test = useMutation({
    mutationFn: () => testAIProviderConnection(providerId),
    onSuccess: (data) => setResult(data),
  });

  return (
    <div className="flex flex-wrap items-center gap-s3 rounded-card border border-line px-s4 py-s3">
      <Button
        variant="secondary"
        onClick={() => test.mutate()}
        disabled={test.isPending}
      >
        {test.isPending ? "Testing…" : "Test connection"}
      </Button>
      {test.isError ? (
        <span role="status" className="flex items-center gap-s1 text-sm text-roseDk">
          <XCircle size={16} aria-hidden /> Request failed
        </span>
      ) : result ? (
        result.ok ? (
          <span role="status" className="flex items-center gap-s1 text-sm text-sageDk">
            <CheckCircle2 size={16} aria-hidden /> Connected · {result.model_name}
          </span>
        ) : (
          <span role="status" className="flex items-center gap-s1 text-sm text-roseDk">
            <XCircle size={16} aria-hidden /> {result.detail}
          </span>
        )
      ) : null}
    </div>
  );
}
