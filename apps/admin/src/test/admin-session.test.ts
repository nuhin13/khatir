import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

// The session cookie reader is server-only (next/headers) — stub it so the
// guard's behaviour is driven by the cookie value we choose per test.
const getSessionMock = vi.fn();
vi.mock("@/lib/auth/session", () => ({
  getSession: () => getSessionMock(),
  ADMIN_SESSION_COOKIE: "khatir_admin_session",
}));

import { getAuthenticatedAdmin } from "@/lib/auth/admin-session";

/** Build a JWT-shaped string carrying the given payload (signature ignored). */
function fakeJwt(payload: Record<string, unknown>): string {
  const b64 = (obj: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(obj)).toString("base64url");
  return `${b64({ alg: "HS256", typ: "JWT" })}.${b64(payload)}.sig`;
}

function mockMeResponse(body: unknown, ok = true, status = 200) {
  return vi.fn().mockResolvedValue({
    ok,
    status,
    json: async () => body,
  });
}

const validMe = {
  id: 7,
  email: "compliance@khatir.com.bd",
  name: "Dana Compliance",
  role: "compliance",
  disabled: false,
  last_login_at: null,
};

beforeEach(() => {
  getSessionMock.mockReset();
});

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("getAuthenticatedAdmin (real session guard)", () => {
  it("returns null when there is no session cookie", async () => {
    getSessionMock.mockResolvedValue(null);
    vi.stubGlobal("fetch", mockMeResponse(validMe));

    expect(await getAuthenticatedAdmin()).toBeNull();
  });

  it("resolves the admin (name, role, expiry) from /me with a valid token", async () => {
    const exp = Math.floor(Date.now() / 1000) + 1800;
    getSessionMock.mockResolvedValue({ token: fakeJwt({ exp, role: "compliance" }) });
    const fetchMock = mockMeResponse(validMe);
    vi.stubGlobal("fetch", fetchMock);

    const admin = await getAuthenticatedAdmin();
    expect(admin).not.toBeNull();
    expect(admin?.name).toBe("Dana Compliance");
    expect(admin?.role).toBe("compliance");
    expect(admin?.expiresAt).toBe(exp);
    // Calls /me with the bearer token, never exposing it to the client.
    expect(fetchMock).toHaveBeenCalledWith(
      expect.stringContaining("/admin/api/auth/me"),
      expect.objectContaining({
        headers: expect.objectContaining({
          Authorization: expect.stringContaining("Bearer "),
        }),
      }),
    );
  });

  it("returns null when the backend rejects the token (401)", async () => {
    getSessionMock.mockResolvedValue({ token: fakeJwt({ exp: 1 }) });
    vi.stubGlobal("fetch", mockMeResponse({}, false, 401));

    expect(await getAuthenticatedAdmin()).toBeNull();
  });

  it("returns null for a disabled account even with a live token", async () => {
    getSessionMock.mockResolvedValue({ token: fakeJwt({ exp: 9999999999 }) });
    vi.stubGlobal("fetch", mockMeResponse({ ...validMe, disabled: true }));

    expect(await getAuthenticatedAdmin()).toBeNull();
  });

  it("fails closed (null) when the backend is unreachable", async () => {
    getSessionMock.mockResolvedValue({ token: fakeJwt({ exp: 9999999999 }) });
    vi.stubGlobal(
      "fetch",
      vi.fn().mockRejectedValue(new Error("ECONNREFUSED")),
    );

    expect(await getAuthenticatedAdmin()).toBeNull();
  });

  it("returns null on a malformed /me response", async () => {
    getSessionMock.mockResolvedValue({ token: fakeJwt({ exp: 9999999999 }) });
    vi.stubGlobal("fetch", mockMeResponse({ unexpected: true }));

    expect(await getAuthenticatedAdmin()).toBeNull();
  });
});
