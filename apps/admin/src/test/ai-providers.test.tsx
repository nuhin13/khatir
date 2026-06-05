import { describe, it, expect, vi, beforeEach } from "vitest";
import {
  render,
  screen,
  fireEvent,
  waitFor,
  within,
} from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { ReactNode } from "react";
import { AIProvidersPanel } from "@/components/admin/ai_providers_panel";
import {
  endpointIsBangladesh,
  type AIProvider,
  type TestConnectionResult,
} from "@/lib/api/ai-providers";

const fetchAIProviders = vi.fn<() => Promise<AIProvider[]>>();
const createAIProvider = vi.fn<() => Promise<AIProvider>>();
const updateAIProvider = vi.fn<() => Promise<AIProvider>>();
const testAIProviderConnection = vi.fn<() => Promise<TestConnectionResult>>();

vi.mock("@/lib/api/ai-providers", async () => {
  const actual = await vi.importActual<typeof import("@/lib/api/ai-providers")>(
    "@/lib/api/ai-providers",
  );
  return {
    ...actual,
    fetchAIProviders: () => fetchAIProviders(),
    createAIProvider: (changes: unknown) => createAIProvider(changes),
    updateAIProvider: (id: unknown, changes: unknown) =>
      updateAIProvider(id, changes),
    testAIProviderConnection: (id: unknown) => testAIProviderConnection(id),
  };
});

function makeProvider(overrides: Partial<AIProvider> = {}): AIProvider {
  return {
    id: 1,
    category: "ocr",
    provider_key: "tesseract",
    is_primary: true,
    is_fallback: false,
    model_name: "tesseract-v5",
    endpoint_url: "https://ocr.example.bd",
    params_json: null,
    dpa_reference: "",
    active: true,
    has_api_key: true,
    created_at: "2026-06-01T00:00:00Z",
    updated_at: "2026-06-01T00:00:00Z",
    ...overrides,
  };
}

function renderPanel() {
  const client = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  const wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  );
  return render(<AIProvidersPanel />, { wrapper });
}

describe("endpointIsBangladesh", () => {
  it("treats a .bd endpoint as BD-hosted", () => {
    expect(endpointIsBangladesh("https://ocr.gov.bd")).toBe(true);
  });
  it("treats a non-.bd or empty endpoint as non-BD", () => {
    expect(endpointIsBangladesh("https://vision.googleapis.com")).toBe(false);
    expect(endpointIsBangladesh("")).toBe(false);
  });
});

describe("AIProvidersPanel", () => {
  beforeEach(() => {
    fetchAIProviders.mockReset();
    createAIProvider.mockReset();
    updateAIProvider.mockReset();
    testAIProviderConnection.mockReset();
  });

  it("renders the four category tabs", async () => {
    fetchAIProviders.mockResolvedValue([makeProvider()]);
    renderPanel();

    await waitFor(() => {
      expect(screen.getByRole("tab", { name: "OCR / Vision" })).toBeTruthy();
    });
    expect(screen.getByRole("tab", { name: "Chat / LLM" })).toBeTruthy();
    expect(screen.getByRole("tab", { name: "Voice / ASR" })).toBeTruthy();
    expect(screen.getByRole("tab", { name: "Lease generation" })).toBeTruthy();
  });

  it("filters providers by the active tab and masks the API key", async () => {
    fetchAIProviders.mockResolvedValue([
      makeProvider(),
      makeProvider({ id: 2, category: "chat", provider_key: "openai" }),
    ]);
    renderPanel();

    // OCR is the default tab — tesseract shows, openai (chat) does not.
    await waitFor(() => {
      expect(screen.getAllByText("tesseract").length).toBeGreaterThan(0);
    });
    expect(screen.queryByText("openai")).toBeNull();
    // The stored key is shown masked, never in plaintext.
    expect(screen.getByText(/key ••••••••••/)).toBeTruthy();

    fireEvent.click(screen.getByRole("tab", { name: "Chat / LLM" }));
    await waitFor(() => {
      expect(screen.getAllByText("openai").length).toBeGreaterThan(0);
    });
    expect(screen.queryByText("tesseract")).toBeNull();
  });

  it("shows an error state with a retry control when the fetch fails", async () => {
    fetchAIProviders.mockRejectedValue(new Error("network"));
    renderPanel();

    await waitFor(() => {
      expect(screen.getByText("Could not load AI providers")).toBeTruthy();
    });
    expect(screen.getByRole("button", { name: "Retry" })).toBeTruthy();
  });

  it("test-connection fires the gateway call and shows the result", async () => {
    fetchAIProviders.mockResolvedValue([makeProvider()]);
    testAIProviderConnection.mockResolvedValue({
      ok: true,
      provider_key: "tesseract",
      model_name: "tesseract-v5",
    });
    renderPanel();

    await waitFor(() => {
      expect(screen.getByRole("button", { name: "Edit" })).toBeTruthy();
    });
    fireEvent.click(screen.getByRole("button", { name: "Edit" }));

    const dialog = screen.getByRole("dialog", { name: "Edit AI provider" });
    expect(testAIProviderConnection).not.toHaveBeenCalled();

    fireEvent.click(
      within(dialog).getByRole("button", { name: "Test connection" }),
    );
    await waitFor(() => {
      expect(testAIProviderConnection).toHaveBeenCalledTimes(1);
    });
    await waitFor(() => {
      expect(within(dialog).getByText(/Connected · tesseract-v5/)).toBeTruthy();
    });
  });

  it("surfaces the DPA warning and blocks saving a non-BD OCR provider without a reference", async () => {
    fetchAIProviders.mockResolvedValue([
      makeProvider({ endpoint_url: "https://vision.googleapis.com", dpa_reference: "" }),
    ]);
    renderPanel();

    await waitFor(() => {
      expect(screen.getByRole("button", { name: "Edit" })).toBeTruthy();
    });
    fireEvent.click(screen.getByRole("button", { name: "Edit" }));

    const dialog = screen.getByRole("dialog", { name: "Edit AI provider" });
    // Non-BD OCR endpoint → DPA warning visible.
    expect(within(dialog).getByText("Data residency warning")).toBeTruthy();
    // Save is blocked until a DPA reference is supplied.
    const save = within(dialog).getByRole("button", { name: "Save provider" });
    expect(save.hasAttribute("disabled")).toBe(true);

    fireEvent.change(
      within(dialog).getByPlaceholderText("e.g. DPA-2026-014"),
      { target: { value: "DPA-2026-014" } },
    );
    expect(
      (
        within(dialog).getByRole("button", {
          name: "Save provider",
        }) as HTMLButtonElement
      ).disabled,
    ).toBe(false);

    updateAIProvider.mockResolvedValue(makeProvider());
    fireEvent.click(within(dialog).getByRole("button", { name: "Save provider" }));
    await waitFor(() => {
      expect(updateAIProvider).toHaveBeenCalledTimes(1);
    });
  });

  it("opens an add-provider form that creates via the API", async () => {
    fetchAIProviders.mockResolvedValue([]);
    createAIProvider.mockResolvedValue(makeProvider({ category: "chat" }));
    renderPanel();

    await waitFor(() => {
      expect(screen.getByRole("button", { name: "Add provider" })).toBeTruthy();
    });
    // Switch to a non-OCR tab so the DPA rule does not apply.
    fireEvent.click(screen.getByRole("tab", { name: "Chat / LLM" }));
    fireEvent.click(screen.getByRole("button", { name: "Add provider" }));

    const dialog = screen.getByRole("dialog", { name: "Add AI provider" });
    fireEvent.change(within(dialog).getByPlaceholderText("e.g. openai"), {
      target: { value: "anthropic" },
    });
    fireEvent.click(within(dialog).getByRole("button", { name: "Save provider" }));
    await waitFor(() => {
      expect(createAIProvider).toHaveBeenCalledTimes(1);
    });
  });
});
