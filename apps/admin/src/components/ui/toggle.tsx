"use client";

import { cn } from "@/lib/utils/cn";

export interface ToggleProps {
  checked: boolean;
  onChange: (checked: boolean) => void;
  label?: string;
  disabled?: boolean;
}

export function Toggle({ checked, onChange, label, disabled }: ToggleProps) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      disabled={disabled}
      onClick={() => onChange(!checked)}
      className={cn(
        "relative inline-flex h-6 w-11 shrink-0 items-center rounded-pill transition-colors disabled:opacity-50",
        checked ? "bg-sage" : "bg-lineDk",
      )}
    >
      <span
        className={cn(
          "inline-block h-5 w-5 transform rounded-pill bg-card transition-transform",
          checked ? "translate-x-5" : "translate-x-1",
        )}
      />
    </button>
  );
}
