import type { LucideIcon } from "lucide-react";
import {
  LayoutDashboard,
  Users,
  DollarSign,
  Rocket,
  Power,
  Send,
  Bot,
  ClipboardCheck,
  ScrollText,
  Settings,
  LifeBuoy,
  UserCog,
  BarChart3,
  ShieldCheck,
} from "lucide-react";
import type { AdminRole } from "@/types/enums";

export interface NavItem {
  label: string;
  href: string;
  icon: LucideIcon;
  /**
   * Admin roles allowed to see this item. `super` is always allowed (see
   * {@link navForRole}), so it is omitted from these lists. Mirrors the backend
   * role → section matrix in `admin_portal/permissions.py` (EPIC-11.T-004) and
   * the role table in Admin Portal spec §2.1.
   */
  roles: readonly AdminRole[];
  /** Not-yet-built modules render a "Coming soon" placeholder. */
  comingSoon?: boolean;
}

/**
 * Sidebar navigation — matches Admin Portal spec §3.1, role-gated per §2.1.
 *
 * Role mapping (super is implicitly allowed everywhere):
 * - Dashboard / Analytics: visible to every role (overview, metrics).
 * - Users / Support: ops + support (the `users` backend section).
 * - Pricing: finance (the `billing`/`pricing` sections).
 * - Features / Kill-switch / Compliance: compliance (audit + kill-switches).
 * - Notifications / AI providers / System / Admin users / Security: super only
 *   (no scoped role owns these in §2.1, so they stay super-exclusive).
 *
 * Dashboard is the only live page in this scaffold; everything else is stubbed.
 */
export const NAV_ITEMS: readonly NavItem[] = [
  { label: "Dashboard", href: "/dashboard", icon: LayoutDashboard, roles: ["ops", "finance", "compliance", "support"] },
  { label: "Users", href: "/users", icon: Users, roles: ["ops", "support"] },
  { label: "Pricing", href: "/pricing", icon: DollarSign, roles: ["finance"] },
  { label: "Features", href: "/features", icon: Rocket, roles: ["compliance"], comingSoon: true },
  {
    label: "Kill-switch",
    href: "/kill-switch",
    icon: Power,
    roles: ["compliance"],
    comingSoon: true,
  },
  {
    label: "Notifications",
    href: "/notifications",
    icon: Send,
    roles: [],
    comingSoon: true,
  },
  {
    label: "AI providers",
    href: "/ai-providers",
    icon: Bot,
    roles: [],
    comingSoon: true,
  },
  {
    label: "Audit log",
    href: "/audit",
    icon: ScrollText,
    roles: ["compliance"],
  },
  {
    label: "Compliance",
    href: "/compliance",
    icon: ClipboardCheck,
    roles: ["compliance"],
    comingSoon: true,
  },
  { label: "System", href: "/system", icon: Settings, roles: [], comingSoon: true },
  { label: "Support", href: "/support", icon: LifeBuoy, roles: ["ops", "support"], comingSoon: true },
  { label: "Admin users", href: "/admins", icon: UserCog, roles: [], comingSoon: true },
  {
    label: "Analytics",
    href: "/analytics",
    icon: BarChart3,
    roles: ["ops", "finance", "compliance", "support"],
    comingSoon: true,
  },
  {
    label: "Security",
    href: "/security",
    icon: ShieldCheck,
    roles: [],
    comingSoon: true,
  },
];

/**
 * Return the nav items visible to `role`. `super` sees everything; every other
 * role sees Dashboard plus the items that name it in {@link NavItem.roles}.
 */
export function navForRole(role: AdminRole): NavItem[] {
  if (role === "super") return [...NAV_ITEMS];
  return NAV_ITEMS.filter((item) => item.roles.includes(role));
}
