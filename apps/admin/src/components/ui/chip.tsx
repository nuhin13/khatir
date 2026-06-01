import type { HTMLAttributes } from "react";
import { cn } from "@/lib/utils/cn";

type Tone = "neutral" | "sage" | "rose" | "butter" | "danger";

const TONES: Record<Tone, string> = {
  neutral: "bg-line text-mutedDk",
  sage: "bg-sageBg text-sageDk",
  rose: "bg-roseBg text-roseDk",
  butter: "bg-butterBg text-butterDk",
  danger: "bg-dangerBg text-danger",
};

export interface ChipProps extends HTMLAttributes<HTMLSpanElement> {
  tone?: Tone;
}

export function Chip({ tone = "neutral", className, ...props }: ChipProps) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-chip px-s3 py-s1 font-title text-xs font-semibold",
        TONES[tone],
        className,
      )}
      {...props}
    />
  );
}
