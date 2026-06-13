"use client";

import {
  AUDIENCE_TYPES,
  CUSTOMER_ROLES,
  type AudienceType,
  type CustomerRole,
} from "@/lib/api/notifications";

/**
 * AudienceSelector — EPIC-15.T-011.
 *
 * Reusable audience picker for notification broadcasts. Lets an admin choose a
 * targeting type (all / by role / by segment / specific users), then refine it:
 *
 * - `all`      → reaches every active user (informational note).
 * - `role`     → pick one or more customer-role cohorts.
 * - `segment`  → pick a role cohort to segment on.
 * - `specific` → search/enter user IDs (comma- or space-separated).
 *
 * Controlled: the caller owns `audienceType`, `roles`, and `userIds` and the
 * matching change handlers. Consumed by the notification composer (T-010) and
 * available to any other admin flow that targets an audience. All
 * colours/spacing/radii come from Notun Din token classes — no hardcoded
 * prototype hex/px.
 */

export const AUDIENCE_LABELS: Record<AudienceType, string> = {
  all: "All users",
  role: "By role",
  segment: "By segment",
  specific: "Specific users",
};

export const ROLE_LABELS: Record<CustomerRole, string> = {
  landlord: "Landlord",
  manager: "Manager",
  tenant: "Tenant",
  caretaker: "Caretaker",
};

const INPUT_CLASS =
  "mt-s2 w-full rounded-input border border-line bg-card px-s3 py-s2 font-body text-sm text-ink placeholder:text-muted focus:border-sage focus:outline-none";

const FIELD_LABEL_CLASS = "font-title text-xs font-semibold text-mutedDk";

export interface AudienceSelectorProps {
  audienceType: AudienceType;
  onAudienceType: (t: AudienceType) => void;
  roles: CustomerRole[];
  onToggleRole: (r: CustomerRole) => void;
  /** Raw comma/space-separated user-id search string. */
  userIds: string;
  onUserIds: (v: string) => void;
}

export function AudienceSelector({
  audienceType,
  onAudienceType,
  roles,
  onToggleRole,
  userIds,
  onUserIds,
}: AudienceSelectorProps) {
  return (
    <div className="space-y-s4">
      <div
        role="radiogroup"
        aria-label="Audience type"
        className="flex flex-wrap gap-s2"
      >
        {AUDIENCE_TYPES.map((type) => {
          const selected = type === audienceType;
          return (
            <button
              key={type}
              type="button"
              role="radio"
              aria-checked={selected}
              onClick={() => onAudienceType(type)}
              className={
                "rounded-button px-s4 py-s2 font-title text-sm font-semibold transition-colors " +
                (selected
                  ? "bg-ink text-card"
                  : "bg-sageBg text-ink hover:bg-line")
              }
            >
              {AUDIENCE_LABELS[type]}
            </button>
          );
        })}
      </div>

      {audienceType === "role" || audienceType === "segment" ? (
        <fieldset className="space-y-s2">
          <legend className={FIELD_LABEL_CLASS}>
            {audienceType === "role" ? "Roles" : "Segment role cohort"}
          </legend>
          <div className="flex flex-wrap gap-s2">
            {CUSTOMER_ROLES.map((role) => {
              const selected = roles.includes(role);
              return (
                <label
                  key={role}
                  className={
                    "cursor-pointer rounded-button px-s4 py-s2 font-title text-sm font-semibold transition-colors " +
                    (selected
                      ? "bg-sage text-card"
                      : "bg-sageBg text-ink hover:bg-line")
                  }
                >
                  <input
                    type="checkbox"
                    className="sr-only"
                    checked={selected}
                    onChange={() => onToggleRole(role)}
                  />
                  {ROLE_LABELS[role]}
                </label>
              );
            })}
          </div>
        </fieldset>
      ) : null}

      {audienceType === "specific" ? (
        <label className="block">
          <span className={FIELD_LABEL_CLASS}>
            User IDs{" "}
            <span className="font-body font-normal text-muted">
              (comma or space separated)
            </span>
          </span>
          <textarea
            value={userIds}
            onChange={(e) => onUserIds(e.target.value)}
            rows={2}
            placeholder="e.g. 1024, 1187, 2390"
            className={INPUT_CLASS}
          />
        </label>
      ) : null}

      {audienceType === "all" ? (
        <p className="text-sm text-muted">
          This message will reach every active user on the platform.
        </p>
      ) : null}
    </div>
  );
}
