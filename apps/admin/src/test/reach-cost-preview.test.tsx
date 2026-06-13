import { describe, it, expect, vi } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import { ReachCostPreview } from "@/components/admin/reach_cost_preview";

/**
 * EPIC-15.T-014 — reusable reach + cost preview widget.
 *
 * The widget is controlled + presentational: the caller owns reach/channels
 * and the cost is derived from the shared estimateCost helper
 * (reach × Σ per-channel cost; inapp/email free, whatsapp ৳0.5, sms ৳0.3).
 */
describe("ReachCostPreview", () => {
  it("shows the explicit reach and derived cost for a known audience", () => {
    // 412 recipients × (whatsapp 0.5) = ৳206; inapp is free.
    render(<ReachCostPreview channels={["inapp", "whatsapp"]} reach={412} />);
    expect(screen.getByText("412")).toBeTruthy();
    expect(screen.getByText("৳206")).toBeTruthy();
  });

  it("renders a chip per selected channel", () => {
    render(<ReachCostPreview channels={["inapp", "sms"]} reach={10} />);
    expect(screen.getByText("In-app")).toBeTruthy();
    expect(screen.getByText("SMS")).toBeTruthy();
    // 10 × sms 0.3 = ৳3.
    expect(screen.getByText("৳3")).toBeTruthy();
  });

  it("shows the no-channels hint when nothing is selected", () => {
    render(<ReachCostPreview channels={[]} reach={5} />);
    expect(screen.getByText("No channels selected")).toBeTruthy();
    // No paid channels → ৳0.
    expect(screen.getByText("৳0")).toBeTruthy();
  });

  it("dashes reach + cost and explains server resolution when reach is null", () => {
    render(<ReachCostPreview channels={["whatsapp"]} reach={null} />);
    // Both reach and cost render an em-dash.
    expect(screen.getAllByText("—").length).toBe(2);
    expect(
      screen.getByText(/resolved on the server when you send/),
    ).toBeTruthy();
  });

  it("surfaces an error message as an alert", () => {
    render(
      <ReachCostPreview
        channels={["inapp"]}
        reach={3}
        errorMessage="Could not send the notification."
      />,
    );
    expect(screen.getByRole("alert").textContent).toContain(
      "Could not send the notification.",
    );
  });

  it("renders a provided action node (e.g. the send button)", () => {
    const onClick = vi.fn();
    render(
      <ReachCostPreview
        channels={["inapp"]}
        reach={1}
        action={
          <button type="button" onClick={onClick}>
            Send notification
          </button>
        }
      />,
    );
    fireEvent.click(
      screen.getByRole("button", { name: "Send notification" }),
    );
    expect(onClick).toHaveBeenCalledTimes(1);
  });
});
