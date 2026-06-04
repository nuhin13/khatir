import { z } from "zod";
import { apiFetch } from "./client";

/**
 * Notifications data layer — EPIC-15.T-010 (composer).
 *
 * Consumes the admin notification broadcast endpoints committed by
 * EPIC-15.T-007 (mounted under `/admin/api/`, super/ops only):
 *
 * - `GET  /admin/api/notifications`            — list broadcasts (newest first).
 * - `POST /admin/api/notifications`            — compose + dispatch a broadcast.
 * - `GET  /admin/api/notifications/{id}`       — retrieve one + its deliveries.
 * - `POST /admin/api/notifications/{id}/send-test` — preview to the acting admin.
 *
 * The compose endpoint returns the serialized {@link Notification} with two
 * extra preview fields injected by the view (`reach`, `estimated_cost`); the
 * composer surfaces those in the reach+cost preview. Every payload is
 * zod-validated at the boundary (coding standards §5).
 */

/** Audience targeting type (NotificationAudienceType, notifications/enums.py). */
export const AUDIENCE_TYPES = ["all", "role", "segment", "specific"] as const;
export type AudienceType = (typeof AUDIENCE_TYPES)[number];

/** Delivery channel (Channel, core/enums.py). `inapp` is always free. */
export const CHANNELS = ["inapp", "whatsapp", "sms", "email"] as const;
export type ChannelValue = (typeof CHANNELS)[number];

/** When the broadcast is sent (NotificationScheduleType). */
export const SCHEDULE_TYPES = ["now", "scheduled", "recurring"] as const;
export type ScheduleType = (typeof SCHEDULE_TYPES)[number];

/** Customer roles that can be addressed by a `role` / `segment` audience. */
export const CUSTOMER_ROLES = [
  "landlord",
  "manager",
  "tenant",
  "caretaker",
] as const;
export type CustomerRole = (typeof CUSTOMER_ROLES)[number];

/** Template variable chips auto-substituted per recipient (spec §4.5.1). */
export const TEMPLATE_VARIABLES = [
  "{name}",
  "{unit}",
  "{tier}",
  "{rent_amount}",
  "{building_name}",
] as const;

/** Read projection of a broadcast (NotificationSerializer, T-007). */
export const notificationSchema = z.object({
  id: z.union([z.string(), z.number()]),
  sender: z.union([z.string(), z.number()]).nullable(),
  audience_type: z.enum(AUDIENCE_TYPES),
  audience_filter: z.record(z.string(), z.unknown()),
  channels: z.array(z.string()),
  title_en: z.string(),
  title_bn: z.string(),
  body_en: z.string(),
  body_bn: z.string(),
  schedule_type: z.enum(SCHEDULE_TYPES),
  scheduled_at: z.string().nullable(),
  status: z.string(),
  sent_count: z.number(),
  delivered_count: z.number(),
  opened_count: z.number(),
  created_at: z.string(),
  updated_at: z.string(),
});
export type Notification = z.infer<typeof notificationSchema>;

/**
 * Compose response — the serialized broadcast plus the two preview fields the
 * view injects (`reach`, `estimated_cost` as a stringified Decimal).
 */
export const composeResultSchema = notificationSchema.extend({
  reach: z.number(),
  estimated_cost: z.string(),
});
export type ComposeResult = z.infer<typeof composeResultSchema>;

/** A crontab descriptor for a recurring send (CrontabSchedule fields). */
export interface Recurrence {
  minute?: string;
  hour?: string;
  day_of_week?: string;
  day_of_month?: string;
  month_of_year?: string;
}

/** Compose payload (NotificationComposeSerializer, T-007). */
export interface ComposeInput {
  audience_type: AudienceType;
  audience_filter?: Record<string, unknown>;
  channels: ChannelValue[];
  title_en: string;
  title_bn: string;
  body_en: string;
  body_bn: string;
  schedule_type: ScheduleType;
  scheduled_at?: string | null;
  recurrence?: Recurrence | null;
}

/** TanStack Query key for the broadcast list. */
export const notificationsQueryKey = ["admin", "notifications"] as const;

/** Tolerates the bare-array or `{ results }`-paginated list envelope. */
const notificationListSchema = z.union([
  z.array(notificationSchema),
  z.object({ results: z.array(notificationSchema) }),
]);

/** Fetch + validate every broadcast (newest first). */
export async function fetchNotifications(): Promise<Notification[]> {
  const body = await apiFetch("/admin/api/notifications", notificationListSchema);
  return Array.isArray(body) ? body : body.results;
}

/** Compose + dispatch (or schedule) a broadcast; returns reach + cost preview. */
export function composeNotification(
  input: ComposeInput,
): Promise<ComposeResult> {
  return apiFetch("/admin/api/notifications", composeResultSchema, {
    method: "POST",
    body: input,
  });
}

/** Deliver the broadcast's content to the acting admin only (preview send). */
export const sendTestResultSchema = z.object({
  detail: z.string(),
  recipient: z.string(),
});
export type SendTestResult = z.infer<typeof sendTestResultSchema>;

export function sendTestNotification(
  id: Notification["id"],
): Promise<SendTestResult> {
  return apiFetch(
    "/admin/api/notifications/" + id + "/send-test",
    sendTestResultSchema,
    { method: "POST" },
  );
}

/**
 * Client-side reach/cost preview helper — mirrors the backend estimate
 * (`reach × Σ per-channel cost`, services.py). Per-message costs match the
 * spec §4.5.1 illustrative table; `inapp` and `email` are free. This is a
 * provisional figure shown before submit; the authoritative reach + cost come
 * back from the compose response (and T-003 re-resolves reach at send time).
 */
export const CHANNEL_COST_BDT: Record<ChannelValue, number> = {
  inapp: 0,
  whatsapp: 0.5,
  sms: 0.3,
  email: 0,
};

export function estimateCost(
  reach: number,
  channels: ChannelValue[],
): number {
  const perRecipient = channels.reduce(
    (sum, c) => sum + CHANNEL_COST_BDT[c],
    0,
  );
  return perRecipient * reach;
}
