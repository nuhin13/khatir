import type {
  HTMLAttributes,
  TableHTMLAttributes,
  TdHTMLAttributes,
  ThHTMLAttributes,
} from "react";
import { cn } from "@/lib/utils/cn";

export function Table({
  className,
  ...props
}: TableHTMLAttributes<HTMLTableElement>) {
  return (
    <div className="overflow-hidden rounded-card border border-line">
      <table
        className={cn("w-full border-collapse text-left text-sm", className)}
        {...props}
      />
    </div>
  );
}

export function TableHead(props: HTMLAttributes<HTMLTableSectionElement>) {
  return <thead className="bg-sageBg" {...props} />;
}

export function TableBody(props: HTMLAttributes<HTMLTableSectionElement>) {
  return <tbody {...props} />;
}

export function TableRow({
  className,
  ...props
}: HTMLAttributes<HTMLTableRowElement>) {
  return (
    <tr
      className={cn("border-b border-line last:border-0", className)}
      {...props}
    />
  );
}

export function TableHeaderCell({
  className,
  ...props
}: ThHTMLAttributes<HTMLTableCellElement>) {
  return (
    <th
      className={cn(
        "px-s4 py-s3 font-title text-xs font-semibold uppercase tracking-wide text-mutedDk",
        className,
      )}
      {...props}
    />
  );
}

export function TableCell({
  className,
  ...props
}: TdHTMLAttributes<HTMLTableCellElement>) {
  return <td className={cn("px-s4 py-s3 text-ink", className)} {...props} />;
}
