import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import LoginPage from "@/app/login/page";
import MfaPage from "@/app/login/mfa/page";

// next/navigation is not available in jsdom — stub the router.
const push = vi.fn();
const refresh = vi.fn();
vi.mock("next/navigation", () => ({
  useRouter: () => ({ push, refresh }),
}));

function mockFetchOnce(body: unknown, ok = true, status = 200) {
  return vi.fn().mockResolvedValue({
    ok,
    status,
    json: async () => body,
  });
}

beforeEach(() => {
  push.mockReset();
  refresh.mockReset();
});

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("Admin login (step one)", () => {
  it("renders the email + password form", () => {
    render(<LoginPage />);
    expect(screen.getByPlaceholderText("you@khatir.com.bd")).toBeTruthy();
    expect(
      screen.getByRole("button", { name: /sign in/i }),
    ).toBeTruthy();
  });

  it("submits credentials and routes to MFA when a challenge is required", async () => {
    const fetchMock = mockFetchOnce({ mfa_required: true });
    vi.stubGlobal("fetch", fetchMock);

    render(<LoginPage />);
    fireEvent.change(screen.getByPlaceholderText("you@khatir.com.bd"), {
      target: { value: "ops@khatir.com.bd" },
    });
    fireEvent.change(screen.getByPlaceholderText("••••••••"), {
      target: { value: "secret123" },
    });
    fireEvent.click(screen.getByRole("button", { name: /sign in/i }));

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledWith(
        "/api/auth/login",
        expect.objectContaining({ method: "POST" }),
      );
      expect(push).toHaveBeenCalledWith("/login/mfa");
    });
  });

  it("routes straight to the dashboard when no MFA is required", async () => {
    vi.stubGlobal("fetch", mockFetchOnce({ mfa_required: false }));

    render(<LoginPage />);
    fireEvent.change(screen.getByPlaceholderText("you@khatir.com.bd"), {
      target: { value: "ops@khatir.com.bd" },
    });
    fireEvent.change(screen.getByPlaceholderText("••••••••"), {
      target: { value: "secret123" },
    });
    fireEvent.click(screen.getByRole("button", { name: /sign in/i }));

    await waitFor(() => {
      expect(push).toHaveBeenCalledWith("/dashboard");
    });
  });

  it("shows an error message on invalid credentials", async () => {
    vi.stubGlobal(
      "fetch",
      mockFetchOnce({ error: "Invalid credentials." }, false, 401),
    );

    render(<LoginPage />);
    fireEvent.change(screen.getByPlaceholderText("you@khatir.com.bd"), {
      target: { value: "ops@khatir.com.bd" },
    });
    fireEvent.change(screen.getByPlaceholderText("••••••••"), {
      target: { value: "wrong" },
    });
    fireEvent.click(screen.getByRole("button", { name: /sign in/i }));

    await waitFor(() => {
      expect(screen.getByRole("alert").textContent).toContain(
        "Invalid credentials.",
      );
      expect(push).not.toHaveBeenCalled();
    });
  });
});

describe("Admin login (step two — MFA)", () => {
  it("disables verify until a 6-digit code is entered", () => {
    render(<MfaPage />);
    const button = screen.getByRole("button", { name: /verify/i });
    expect((button as HTMLButtonElement).disabled).toBe(true);
  });

  it("verifies the code and redirects to the dashboard", async () => {
    vi.stubGlobal("fetch", mockFetchOnce({ ok: true }));

    render(<MfaPage />);
    const input = screen.getByLabelText(/6-digit authentication code/i);
    fireEvent.change(input, { target: { value: "123456" } });
    fireEvent.click(screen.getByRole("button", { name: /verify/i }));

    await waitFor(() => {
      expect(push).toHaveBeenCalledWith("/dashboard");
    });
  });

  it("shows an error and clears the field on a wrong code", async () => {
    vi.stubGlobal(
      "fetch",
      mockFetchOnce({ error: "That code didn't work. Please try again." }, false, 401),
    );

    render(<MfaPage />);
    const input = screen.getByLabelText(
      /6-digit authentication code/i,
    ) as HTMLInputElement;
    fireEvent.change(input, { target: { value: "000000" } });
    fireEvent.click(screen.getByRole("button", { name: /verify/i }));

    await waitFor(() => {
      expect(screen.getByRole("alert").textContent).toContain(
        "That code didn't work",
      );
      expect(input.value).toBe("");
    });
  });

  it("strips non-digits from the code input", () => {
    render(<MfaPage />);
    const input = screen.getByLabelText(
      /6-digit authentication code/i,
    ) as HTMLInputElement;
    fireEvent.change(input, { target: { value: "12ab34" } });
    expect(input.value).toBe("1234");
  });
});
