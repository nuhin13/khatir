import { describe, it, expect, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import { Sidebar } from "@/components/features/sidebar";

/**
 * EPIC-11.T-010 — active-link highlight. The sidebar marks the item whose
 * route matches the current pathname (or is a parent of it) as active. We pin
 * usePathname to a non-dashboard route so the highlight is unambiguous.
 */
vi.mock("next/navigation", () => ({
  usePathname: () => "/pricing",
}));

describe("Sidebar active-link highlight", () => {
  it("applies the active style to the link for the current route", () => {
    render(<Sidebar role="super" />);
    const active = screen.getByText("Pricing").closest("a");
    const inactive = screen.getByText("Dashboard").closest("a");

    // Active item carries the sage highlight; inactive items do not.
    expect(active?.className).toContain("bg-sageBg");
    expect(active?.className).toContain("text-sageDk");
    expect(inactive?.className).not.toContain("text-sageDk");
  });

  it("treats a child route as keeping its parent nav item active", () => {
    // /pricing/invoices should still highlight the Pricing item.
    render(<Sidebar role="super" />);
    const active = screen.getByText("Pricing").closest("a");
    expect(active?.className).toContain("bg-sageBg");
  });
});
