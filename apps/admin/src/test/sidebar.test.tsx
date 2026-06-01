import { describe, it, expect, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import { Sidebar } from "@/components/features/sidebar";
import { NAV_ITEMS } from "@/app/(dashboard)/_nav";

// next/navigation is not available in jsdom — stub the hook the Sidebar uses.
vi.mock("next/navigation", () => ({
  usePathname: () => "/dashboard",
}));

describe("Sidebar", () => {
  it("renders every nav item from the admin spec", () => {
    render(<Sidebar />);
    for (const item of NAV_ITEMS) {
      expect(screen.getByText(item.label)).toBeTruthy();
    }
  });

  it("renders all 13 nav links", () => {
    render(<Sidebar />);
    expect(NAV_ITEMS).toHaveLength(13);
    expect(screen.getAllByRole("link")).toHaveLength(NAV_ITEMS.length);
  });
});
