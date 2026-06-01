// TS unions mirroring docs/architecture/enums.md.
// Wire values are lowercase snake_case strings — never integers.
// Source of truth: documnets/docs/architecture/enums.md. Keep in sync.

export const ROLES = [
  "landlord",
  "manager",
  "tenant",
  "caretaker",
  "admin",
] as const;
export type Role = (typeof ROLES)[number];

export const ADMIN_ROLES = [
  "super",
  "ops",
  "finance",
  "compliance",
  "support",
] as const;
export type AdminRole = (typeof ADMIN_ROLES)[number];

export const LANGUAGES = ["bn", "en"] as const;
export type Language = (typeof LANGUAGES)[number];

export const AREAS = [
  "uttara",
  "mirpur",
  "mohammadpur",
  "dhanmondi",
  "banasree",
  "gulshan",
  "banani",
  "bashundhara",
  "old_dhaka",
  "other",
] as const;
export type Area = (typeof AREAS)[number];

export const UNIT_TYPES = [
  "apartment",
  "room",
  "commercial",
  "garage",
  "other",
] as const;
export type UnitType = (typeof UNIT_TYPES)[number];

export const UNIT_STATUSES = ["occupied", "vacant", "maintenance"] as const;
export type UnitStatus = (typeof UNIT_STATUSES)[number];

export const VERIFICATION_STATUSES = [
  "unverified",
  "matched",
  "not_matched",
  "error",
] as const;
export type VerificationStatus = (typeof VERIFICATION_STATUSES)[number];

export const LEASE_STATUSES = [
  "draft",
  "active",
  "ended",
  "terminated",
] as const;
export type LeaseStatus = (typeof LEASE_STATUSES)[number];

export const RENT_SCHEDULE_STATUSES = [
  "pending",
  "requested",
  "paid",
  "overdue",
] as const;
export type RentScheduleStatus = (typeof RENT_SCHEDULE_STATUSES)[number];

export const RENT_REQUEST_STATUSES = [
  "sent",
  "proof_submitted",
  "verified",
  "rejected",
] as const;
export type RentRequestStatus = (typeof RENT_REQUEST_STATUSES)[number];

export const PAYMENT_PROOF_TYPES = [
  "bkash_txn",
  "nagad_txn",
  "screenshot",
  "photo",
  "note",
] as const;
export type PaymentProofType = (typeof PAYMENT_PROOF_TYPES)[number];

export const CHANNELS = ["inapp", "whatsapp", "sms", "email"] as const;
export type Channel = (typeof CHANNELS)[number];

export const MAINTENANCE_CATEGORIES = [
  "plumbing",
  "electrical",
  "paint",
  "structural",
  "appliance",
  "utility",
  "other",
] as const;
export type MaintenanceCategory = (typeof MAINTENANCE_CATEGORIES)[number];

export const MAINTENANCE_STATUSES = ["open", "resolved"] as const;
export type MaintenanceStatus = (typeof MAINTENANCE_STATUSES)[number];

export const EXPENSE_CATEGORIES = [
  "plumbing",
  "paint",
  "electrical",
  "structural",
  "appliance",
  "utility",
  "other",
] as const;
export type ExpenseCategory = (typeof EXPENSE_CATEGORIES)[number];

export const EXPENSE_SOURCES = ["request", "manual"] as const;
export type ExpenseSource = (typeof EXPENSE_SOURCES)[number];

export const PRICING_TIER_KEYS = [
  "free",
  "per_tenant",
  "bundle_20",
  "bundle_40",
  "unlimited_monthly",
  "unlimited_annual",
] as const;
export type PricingTierKey = (typeof PRICING_TIER_KEYS)[number];

export const BILLING_CYCLES = ["monthly", "annual"] as const;
export type BillingCycle = (typeof BILLING_CYCLES)[number];

export const SUBSCRIPTION_STATUSES = [
  "active",
  "past_due",
  "cancelled",
] as const;
export type SubscriptionStatus = (typeof SUBSCRIPTION_STATUSES)[number];

export const AI_PROVIDER_CATEGORIES = [
  "chat",
  "voice",
  "ocr",
  "lease",
] as const;
export type AIProviderCategory = (typeof AI_PROVIDER_CATEGORIES)[number];

export const NOTIFICATION_AUDIENCE_TYPES = [
  "all",
  "role",
  "segment",
  "specific",
] as const;
export type NotificationAudienceType =
  (typeof NOTIFICATION_AUDIENCE_TYPES)[number];

export const NOTIFICATION_STATUSES = [
  "draft",
  "scheduled",
  "sending",
  "sent",
  "failed",
] as const;
export type NotificationStatus = (typeof NOTIFICATION_STATUSES)[number];

export const NOTIFICATION_DELIVERY_STATUSES = [
  "queued",
  "sent",
  "delivered",
  "opened",
  "failed",
] as const;
export type NotificationDeliveryStatus =
  (typeof NOTIFICATION_DELIVERY_STATUSES)[number];

export const SYSTEM_CONFIG_TYPES = ["int", "money", "text", "bool"] as const;
export type SystemConfigType = (typeof SYSTEM_CONFIG_TYPES)[number];

export const ERROR_CODES = [
  "validation_error",
  "not_found",
  "permission_denied",
  "auth_required",
  "auth_invalid",
  "conflict",
  "rate_limited",
  "upstream_unavailable",
  "feature_disabled",
  "payment_required",
  "server_error",
] as const;
export type ErrorCode = (typeof ERROR_CODES)[number];
