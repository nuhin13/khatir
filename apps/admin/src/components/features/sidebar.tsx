"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { NAV_ITEMS } from "@/app/(dashboard)/_nav";
import { cn } from "@/lib/utils/cn";

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="flex w-64 shrink-0 flex-col border-r border-line bg-card">
      <div className="flex h-16 items-center gap-s2 border-b border-line px-s5">
        <span className="font-title text-lg font-bold text-ink">Khatir</span>
        <span className="font-hand text-sm text-sageDk">admin</span>
      </div>
      <nav className="flex-1 space-y-s1 overflow-y-auto p-s3">
        {NAV_ITEMS.map((item) => {
          const active =
            pathname === item.href || pathname.startsWith(`${item.href}/`);
          const Icon = item.icon;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex items-center gap-s3 rounded-md px-s3 py-s2 font-title text-sm transition-colors",
                active
                  ? "bg-sageBg font-semibold text-sageDk"
                  : "text-ink2 hover:bg-sageBg",
              )}
            >
              <Icon size={18} aria-hidden />
              <span className="flex-1">{item.label}</span>
              {item.comingSoon ? (
                <span className="rounded-chip bg-butterBg px-s2 py-px text-[10px] font-semibold text-butterDk">
                  Soon
                </span>
              ) : null}
            </Link>
          );
        })}
      </nav>
    </aside>
  );
}
