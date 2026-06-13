import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Topbar } from "@/components/features/topbar";

const replace = vi.fn();
const refresh = vi.fn();
vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace, refresh }),
}));

beforeEach(() => {
  replace.mockReset();
  refresh.mockReset();
});

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("Topbar", () => {
  it("shows the admin name and a human-readable role badge", () => {
    render(<Topbar name="Sam Super" role="super" />);
    expect(screen.getByText("Sam Super")).toBeTruthy();
    expect(screen.getByText("Super Admin")).toBeTruthy();
  });

  it("logs out: POSTs to the logout route then routes to /login", async () => {
    const fetchMock = vi.fn().mockResolvedValue({ ok: true, json: async () => ({}) });
    vi.stubGlobal("fetch", fetchMock);

    render(<Topbar name="Olive Ops" role="ops" />);
    fireEvent.click(screen.getByRole("button", { name: /log out/i }));

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledWith(
        "/api/auth/logout",
        expect.objectContaining({ method: "POST" }),
      );
      expect(replace).toHaveBeenCalledWith("/login");
    });
  });
});
