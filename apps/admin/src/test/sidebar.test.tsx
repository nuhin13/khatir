import { describe, it, expect, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import { Sidebar } from "@/components/features/sidebar";
import { NAV_ITEMS, navForRole } from "@/app/(dashboard)/_nav";
import type { AdminRole } from "@/types/enums";

// next/navigation is not available in jsdom — stub the hook the Sidebar uses.
vi.mock("next/navigation", () => ({
  usePathname: () => "/dashboard",
}));

describe("navForRole (role → nav matrix)", () => {
  it("shows every nav item to super", () => {
    expect(navForRole("super")).toHaveLength(NAV_ITEMS.length);
  });

  it("never hides Dashboard from any role", () => {
    const roles: AdminRole[] = [
      "super",
      "ops",
      "finance",
      "compliance",
      "support",
    ];
    for (const role of roles) {
      const labels = navForRole(role).map((i) => i.label);
      expect(labels).toContain("Dashboard");
    }
  });

  it("hides Pricing from a compliance admin", () => {
    const labels = navForRole("compliance").map((i) => i.label);
    expect(labels).not.toContain("Pricing");
  });

  it("shows Pricing to a finance admin but hides Users", () => {
    const labels = navForRole("finance").map((i) => i.label);
    expect(labels).toContain("Pricing");
    expect(labels).not.toContain("Users");
  });

  it("shows Users + Support to an ops admin but hides Pricing", () => {
    const labels = navForRole("ops").map((i) => i.label);
    expect(labels).toContain("Users");
    expect(labels).toContain("Support");
    expect(labels).not.toContain("Pricing");
  });

  it("reserves super-only modules (Admin users, Security, System) for super", () => {
    const superOnly = ["Admin users", "Security", "System"];
    const otherRoles: AdminRole[] = ["ops", "finance", "compliance", "support"];
    for (const role of otherRoles) {
      const labels = navForRole(role).map((i) => i.label);
      for (const reserved of superOnly) {
        expect(labels).not.toContain(reserved);
      }
    }
  });
});

describe("NAV_ITEMS (routes — EPIC-11.T-010)", () => {
  it("covers every Admin Portal spec §3.1 sidebar entry", () => {
    const labels = NAV_ITEMS.map((i) => i.label);
    for (const expected of [
      "Dashboard",
      "Users",
      "Pricing",
      "Features",
      "Kill-switch",
      "Notifications",
      "AI providers",
      "Compliance",
      "System",
      "Support",
      "Admin users",
      "Analytics",
      "Security",
    ]) {
      expect(labels).toContain(expected);
    }
  });

  it("links every nav item to a distinct absolute route", () => {
    for (const item of NAV_ITEMS) {
      // Single- or multi-segment absolute path (e.g. /billing/refunds).
      expect(item.href).toMatch(/^\/[a-z-]+(\/[a-z-]+)*$/);
    }
    const hrefs = NAV_ITEMS.map((i) => i.href);
    expect(new Set(hrefs).size).toBe(hrefs.length);
  });

  it("marks every unbuilt module as coming-soon and built pages as live", () => {
    // Live pages shipped so far: Dashboard (T-009), Audit log (T-011),
    // Pricing (EPIC-12.T-005), Users (EPIC-12.T-007), Refunds (EPIC-12.T-009).
    const livePages = new Set([
      "Dashboard",
      "Audit log",
      "Pricing",
      "Users",
      "Refunds",
    ]);
    for (const item of NAV_ITEMS) {
      if (livePages.has(item.label)) {
        expect(item.comingSoon).toBeFalsy();
      } else {
        expect(item.comingSoon).toBe(true);
      }
    }
  });
});

describe("Sidebar (role-aware)", () => {
  it("renders every nav item for a super admin", () => {
    render(<Sidebar role="super" />);
    for (const item of NAV_ITEMS) {
      expect(screen.getByText(item.label)).toBeTruthy();
    }
    expect(screen.getAllByRole("link")).toHaveLength(NAV_ITEMS.length);
  });

  it("points each rendered link at its nav route", () => {
    render(<Sidebar role="super" />);
    for (const item of NAV_ITEMS) {
      const link = screen.getByText(item.label).closest("a");
      expect(link?.getAttribute("href")).toBe(item.href);
    }
  });

  it("renders a 'Soon' badge for unbuilt modules but not for Dashboard", () => {
    render(<Sidebar role="super" />);
    // Dashboard (live) has no badge; the 12 stubbed modules each show one.
    const badges = screen.getAllByText("Soon");
    expect(badges).toHaveLength(NAV_ITEMS.filter((i) => i.comingSoon).length);
  });

  it("does not render Pricing for a compliance admin", () => {
    render(<Sidebar role="compliance" />);
    expect(screen.queryByText("Pricing")).toBeNull();
    expect(screen.getByText("Dashboard")).toBeTruthy();
    expect(screen.getByText("Compliance")).toBeTruthy();
  });
});
