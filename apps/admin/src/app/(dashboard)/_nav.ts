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
  Settings,
  LifeBuoy,
  UserCog,
  BarChart3,
  ShieldCheck,
} from "lucide-react";

export interface NavItem {
  label: string;
  href: string;
  icon: LucideIcon;
  /** Not-yet-built modules render a "Coming soon" placeholder. */
  comingSoon?: boolean;
}

/**
 * Sidebar navigation — matches Admin Portal spec §3.1.
 * Dashboard is the only live page in this scaffold; everything else is stubbed.
 */
export const NAV_ITEMS: NavItem[] = [
  { label: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
  { label: "Users", href: "/users", icon: Users, comingSoon: true },
  { label: "Pricing", href: "/pricing", icon: DollarSign, comingSoon: true },
  { label: "Features", href: "/features", icon: Rocket, comingSoon: true },
  {
    label: "Kill-switch",
    href: "/kill-switch",
    icon: Power,
    comingSoon: true,
  },
  {
    label: "Notifications",
    href: "/notifications",
    icon: Send,
    comingSoon: true,
  },
  {
    label: "AI providers",
    href: "/ai-providers",
    icon: Bot,
    comingSoon: true,
  },
  {
    label: "Compliance",
    href: "/compliance",
    icon: ClipboardCheck,
    comingSoon: true,
  },
  { label: "System", href: "/system", icon: Settings, comingSoon: true },
  { label: "Support", href: "/support", icon: LifeBuoy, comingSoon: true },
  { label: "Admin users", href: "/admins", icon: UserCog, comingSoon: true },
  {
    label: "Analytics",
    href: "/analytics",
    icon: BarChart3,
    comingSoon: true,
  },
  {
    label: "Security",
    href: "/security",
    icon: ShieldCheck,
    comingSoon: true,
  },
];
