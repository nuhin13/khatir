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

describe("Sidebar (role-aware)", () => {
  it("renders every nav item for a super admin", () => {
    render(<Sidebar role="super" />);
    for (const item of NAV_ITEMS) {
      expect(screen.getByText(item.label)).toBeTruthy();
    }
    expect(screen.getAllByRole("link")).toHaveLength(NAV_ITEMS.length);
  });

  it("does not render Pricing for a compliance admin", () => {
    render(<Sidebar role="compliance" />);
    expect(screen.queryByText("Pricing")).toBeNull();
    expect(screen.getByText("Dashboard")).toBeTruthy();
    expect(screen.getByText("Compliance")).toBeTruthy();
  });
});
