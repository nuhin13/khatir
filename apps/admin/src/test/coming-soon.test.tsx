import { describe, it, expect } from "vitest";
import { render, screen } from "@testing-library/react";
import { ComingSoon } from "@/components/features/coming-soon";

/**
 * EPIC-11.T-010 — the reusable "coming soon" stub rendered by every unbuilt
 * admin module page ((dashboard)/users, /pricing, … all proxy to this).
 */
describe("ComingSoon", () => {
  it("renders the module title as the page heading", () => {
    render(<ComingSoon title="Pricing" />);
    const heading = screen.getByRole("heading", { name: "Pricing" });
    expect(heading).toBeTruthy();
  });

  it("shows the coming-soon placeholder message", () => {
    render(<ComingSoon title="Notifications" />);
    expect(screen.getByText("Coming soon")).toBeTruthy();
    expect(screen.getByText(/has not been built yet/i)).toBeTruthy();
  });
});
