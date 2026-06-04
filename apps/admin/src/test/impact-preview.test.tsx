import { describe, it, expect, vi } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import {
  ImpactPreviewModal,
  revenueDelta,
  losesVerification,
  type TierImpact,
} from "@/components/admin/impact_preview_modal";

function makeImpact(overrides: Partial<TierImpact> = {}): TierImpact {
  return {
    tierLabel: "Unlimited Annual",
    tierKey: "unlimited_annual",
    oldMonthly: 999,
    newMonthly: 949,
    subscribersAffected: 1420,
    oldIncludesVerification: true,
    newIncludesVerification: true,
    ...overrides,
  };
}

describe("revenueDelta", () => {
  it("multiplies the price change by the subscriber count", () => {
    expect(revenueDelta(makeImpact({ oldMonthly: 999, newMonthly: 949 }))).toBe(
      -71000,
    );
    expect(revenueDelta(makeImpact({ oldMonthly: 500, newMonthly: 600 }))).toBe(
      142000,
    );
  });
});

describe("losesVerification", () => {
  it("is true only when verification is dropped for existing subscribers", () => {
    expect(
      losesVerification(
        makeImpact({
          oldIncludesVerification: true,
          newIncludesVerification: false,
        }),
      ),
    ).toBe(true);
    // gaining verification is not a warning
    expect(
      losesVerification(
        makeImpact({
          oldIncludesVerification: false,
          newIncludesVerification: true,
        }),
      ),
    ).toBe(false);
    // dropping verification with no subscribers is not a warning
    expect(
      losesVerification(
        makeImpact({
          oldIncludesVerification: true,
          newIncludesVerification: false,
          subscribersAffected: 0,
        }),
      ),
    ).toBe(false);
  });
});

describe("ImpactPreviewModal", () => {
  it("renders nothing when closed", () => {
    const { container } = render(
      <ImpactPreviewModal open={false} impact={makeImpact()} onClose={vi.fn()} />,
    );
    expect(container.firstChild).toBeNull();
  });

  it("renders subscriber count, revenue delta, and no warning by default", () => {
    render(
      <ImpactPreviewModal open impact={makeImpact()} onClose={vi.fn()} />,
    );

    expect(screen.getByText("1,420")).toBeTruthy();
    // delta = (949 - 999) * 1420 = -71,000 → negative, uses the minus sign
    expect(screen.getByText("−৳71,000/mo")).toBeTruthy();
    expect(screen.queryByRole("alert")).toBeNull();
  });

  it("renders a positive delta with a plus sign", () => {
    render(
      <ImpactPreviewModal
        open
        impact={makeImpact({ oldMonthly: 500, newMonthly: 600 })}
        onClose={vi.fn()}
      />,
    );
    expect(screen.getByText("+৳142,000/mo")).toBeTruthy();
  });

  it("shows the NID verification warning when verification is lost", () => {
    render(
      <ImpactPreviewModal
        open
        impact={makeImpact({
          oldIncludesVerification: true,
          newIncludesVerification: false,
        })}
        onClose={vi.fn()}
      />,
    );
    const alert = screen.getByRole("alert");
    expect(alert).toBeTruthy();
    expect(
      screen.getByText("NID verification will be removed"),
    ).toBeTruthy();
  });

  it("shows the loading skeleton without data", () => {
    render(<ImpactPreviewModal open loading onClose={vi.fn()} />);
    expect(screen.getByLabelText("Loading impact")).toBeTruthy();
    expect(screen.queryByText("1,420")).toBeNull();
  });

  it("calls onClose from the close button and the backdrop", () => {
    const onClose = vi.fn();
    render(
      <ImpactPreviewModal open impact={makeImpact()} onClose={onClose} />,
    );
    fireEvent.click(screen.getByLabelText("Close"));
    expect(onClose).toHaveBeenCalledTimes(1);

    fireEvent.click(screen.getByRole("presentation"));
    expect(onClose).toHaveBeenCalledTimes(2);
  });

  it("renders and fires the confirm CTA only when onConfirm is provided", () => {
    const onConfirm = vi.fn();
    const { rerender } = render(
      <ImpactPreviewModal open impact={makeImpact()} onClose={vi.fn()} />,
    );
    expect(screen.queryByRole("button", { name: "Apply change" })).toBeNull();

    rerender(
      <ImpactPreviewModal
        open
        impact={makeImpact()}
        onClose={vi.fn()}
        onConfirm={onConfirm}
      />,
    );
    fireEvent.click(screen.getByRole("button", { name: "Apply change" }));
    expect(onConfirm).toHaveBeenCalledTimes(1);
  });

  it("disables the confirm CTA when confirmDisabled is set", () => {
    render(
      <ImpactPreviewModal
        open
        impact={makeImpact()}
        onClose={vi.fn()}
        onConfirm={vi.fn()}
        confirmDisabled
      />,
    );
    const cta = screen.getByRole("button", {
      name: "Apply change",
    }) as HTMLButtonElement;
    expect(cta.disabled).toBe(true);
  });
});
