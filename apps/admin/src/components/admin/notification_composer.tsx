"use client";

import { useMemo, useRef, useState } from "react";
import { CheckCircle2, Send, Users } from "lucide-react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Card, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Chip } from "@/components/ui/chip";
import { AudienceSelector } from "@/components/admin/audience_selector";
import {
  ChannelSelector,
  CHANNEL_LABELS,
} from "@/components/admin/channel_selector";
import {
  SCHEDULE_TYPES,
  TEMPLATE_VARIABLES,
  composeNotification,
  estimateCost,
  notificationsQueryPrefix,
  type AudienceType,
  type ChannelValue,
  type ComposeInput,
  type ComposeResult,
  type CustomerRole,
  type Recurrence,
  type ScheduleType,
} from "@/lib/api/notifications";

/**
 * Notification composer — EPIC-15.T-010.
 *
 * The compose form from `04_Admin_Portal_Khatir.md` §4.5.1: pick an audience
 * (all / role / segment / specific IDs), one or more delivery channels
 * (in-app / WhatsApp / SMS / email), author a bilingual title + body with
 * insertable variable chips, choose a schedule (now / scheduled / recurring),
 * and review a live reach + cost preview before submitting. Submit hits
 * `POST /admin/api/notifications` (T-007), which composes, persists, and
 * dispatches/schedules the broadcast and returns the authoritative reach +
 * estimated cost.
 *
 * The super/ops route guard lives in the server page that renders this (it
 * mirrors the backend `IsPlatformAdmin` gate). All colours/spacing/radii come
 * from Notun Din token classes — no hardcoded prototype hex/px.
 */

const SCHEDULE_LABELS: Record<ScheduleType, string> = {
  now: "Immediately",
  scheduled: "Scheduled",
  recurring: "Recurring",
};

const INPUT_CLASS =
  "mt-s2 w-full rounded-input border border-line bg-card px-s3 py-s2 font-body text-sm text-ink placeholder:text-muted focus:border-sage focus:outline-none";

const FIELD_LABEL_CLASS = "font-title text-xs font-semibold text-mutedDk";

const taka = (amount: number): string =>
  "৳" +
  amount.toLocaleString("en-US", {
    minimumFractionDigits: amount % 1 === 0 ? 0 : 2,
    maximumFractionDigits: 2,
  });

export function NotificationComposer() {
  const queryClient = useQueryClient();

  const [audienceType, setAudienceType] = useState<AudienceType>("all");
  const [roles, setRoles] = useState<CustomerRole[]>([]);
  const [userIds, setUserIds] = useState("");

  const [channels, setChannels] = useState<ChannelValue[]>(["inapp"]);

  const [titleEn, setTitleEn] = useState("");
  const [titleBn, setTitleBn] = useState("");
  const [bodyEn, setBodyEn] = useState("");
  const [bodyBn, setBodyBn] = useState("");

  const [scheduleType, setScheduleType] = useState<ScheduleType>("now");
  const [scheduledAt, setScheduledAt] = useState("");
  const [cronMinute, setCronMinute] = useState("0");
  const [cronHour, setCronHour] = useState("9");
  const [cronDayOfWeek, setCronDayOfWeek] = useState("*");

  const bodyEnRef = useRef<HTMLTextAreaElement | null>(null);
  const bodyBnRef = useRef<HTMLTextAreaElement | null>(null);

  const compose = useMutation<ComposeResult, Error, ComposeInput>({
    mutationFn: composeNotification,
    onSuccess: () => {
      void queryClient.invalidateQueries({
        queryKey: notificationsQueryPrefix,
      });
    },
  });

  const toggleChannel = (channel: ChannelValue) => {
    setChannels((prev) =>
      prev.includes(channel)
        ? prev.filter((c) => c !== channel)
        : [...prev, channel],
    );
  };

  const toggleRole = (role: CustomerRole) => {
    setRoles((prev) =>
      prev.includes(role) ? prev.filter((r) => r !== role) : [...prev, role],
    );
  };

  const parsedUserIds = useMemo(
    () =>
      userIds
        .split(/[\s,]+/)
        .map((id) => id.trim())
        .filter((id) => id.length > 0),
    [userIds],
  );

  const insertVariable = (
    target: "en" | "bn",
    variable: string,
  ) => {
    const ref = target === "en" ? bodyEnRef : bodyBnRef;
    const setBody = target === "en" ? setBodyEn : setBodyBn;
    const el = ref.current;
    if (!el) {
      setBody((prev) => prev + variable);
      return;
    }
    const start = el.selectionStart ?? el.value.length;
    const end = el.selectionEnd ?? el.value.length;
    const next = el.value.slice(0, start) + variable + el.value.slice(end);
    setBody(next);
    // Restore the caret just after the inserted chip on the next tick.
    requestAnimationFrame(() => {
      el.focus();
      const caret = start + variable.length;
      el.setSelectionRange(caret, caret);
    });
  };

  const audienceFilter = useMemo<Record<string, unknown>>(() => {
    if (audienceType === "role") {
      // A single role goes in `role`; the backend role audience matches one
      // role. We submit one entry per selected role-cohort via `segment` when
      // more than one is picked, but the simplest contract is one role here.
      return roles.length > 0 ? { role: roles[0] } : {};
    }
    if (audienceType === "segment") {
      return roles.length > 0 ? { role: roles[0] } : {};
    }
    if (audienceType === "specific") {
      return { user_ids: parsedUserIds };
    }
    return {};
  }, [audienceType, roles, parsedUserIds]);

  // Provisional reach: unknown until the server resolves it, so we show a dash
  // for broad audiences and the explicit count for a specific-user audience.
  const provisionalReach =
    audienceType === "specific" ? parsedUserIds.length : null;

  const provisionalCost =
    provisionalReach === null
      ? null
      : estimateCost(provisionalReach, channels);

  const audienceValid =
    audienceType === "all" ||
    (audienceType === "role" && roles.length > 0) ||
    (audienceType === "segment" && roles.length > 0) ||
    (audienceType === "specific" && parsedUserIds.length > 0);

  const contentValid =
    titleEn.trim().length > 0 &&
    titleBn.trim().length > 0 &&
    bodyEn.trim().length > 0 &&
    bodyBn.trim().length > 0;

  const scheduleValid =
    scheduleType === "now" ||
    (scheduleType === "scheduled" && scheduledAt.length > 0) ||
    scheduleType === "recurring";

  const canSubmit =
    channels.length > 0 &&
    audienceValid &&
    contentValid &&
    scheduleValid &&
    !compose.isPending;

  const submit = () => {
    let recurrence: Recurrence | null = null;
    if (scheduleType === "recurring") {
      recurrence = {
        minute: cronMinute || "*",
        hour: cronHour || "*",
        day_of_week: cronDayOfWeek || "*",
      };
    }
    const input: ComposeInput = {
      audience_type: audienceType,
      audience_filter: audienceFilter,
      channels,
      title_en: titleEn.trim(),
      title_bn: titleBn.trim(),
      body_en: bodyEn.trim(),
      body_bn: bodyBn.trim(),
      schedule_type: scheduleType,
      scheduled_at:
        scheduleType === "scheduled"
          ? new Date(scheduledAt).toISOString()
          : null,
      recurrence,
    };
    compose.mutate(input);
  };

  if (compose.isSuccess) {
    return (
      <SuccessPanel
        result={compose.data}
        onCompose={() => compose.reset()}
      />
    );
  }

  return (
    <div className="space-y-s6">
      <div>
        <h1 className="font-title text-2xl font-bold text-ink">
          Compose notification
        </h1>
        <p className="mt-s1 text-sm text-muted">
          Target an audience, pick the delivery channels, write a bilingual
          message, then review the reach and cost before sending. Every send is
          audit-logged.
        </p>
      </div>

      <div className="grid gap-s5 lg:grid-cols-[1fr_20rem]">
        <div className="space-y-s5">
          <Card className="space-y-s4">
            <CardTitle>Audience</CardTitle>
            <AudienceSelector
              audienceType={audienceType}
              onAudienceType={setAudienceType}
              roles={roles}
              onToggleRole={toggleRole}
              userIds={userIds}
              onUserIds={setUserIds}
            />
          </Card>

          <Card className="space-y-s4">
            <CardTitle>Channels</CardTitle>
            <ChannelSelector value={channels} onToggle={toggleChannel} />
          </Card>

          <CompositionSection
            titleEn={titleEn}
            titleBn={titleBn}
            bodyEn={bodyEn}
            bodyBn={bodyBn}
            onTitleEn={setTitleEn}
            onTitleBn={setTitleBn}
            onBodyEn={setBodyEn}
            onBodyBn={setBodyBn}
            bodyEnRef={bodyEnRef}
            bodyBnRef={bodyBnRef}
            onInsertVariable={insertVariable}
          />

          <ScheduleSection
            scheduleType={scheduleType}
            onScheduleType={setScheduleType}
            scheduledAt={scheduledAt}
            onScheduledAt={setScheduledAt}
            cronMinute={cronMinute}
            cronHour={cronHour}
            cronDayOfWeek={cronDayOfWeek}
            onCronMinute={setCronMinute}
            onCronHour={setCronHour}
            onCronDayOfWeek={setCronDayOfWeek}
          />
        </div>

        <PreviewSidebar
          channels={channels}
          reach={provisionalReach}
          cost={provisionalCost}
          canSubmit={canSubmit}
          isPending={compose.isPending}
          isError={compose.isError}
          onSubmit={submit}
        />
      </div>
    </div>
  );
}

interface CompositionSectionProps {
  titleEn: string;
  titleBn: string;
  bodyEn: string;
  bodyBn: string;
  onTitleEn: (v: string) => void;
  onTitleBn: (v: string) => void;
  onBodyEn: (v: string) => void;
  onBodyBn: (v: string) => void;
  bodyEnRef: React.RefObject<HTMLTextAreaElement | null>;
  bodyBnRef: React.RefObject<HTMLTextAreaElement | null>;
  onInsertVariable: (target: "en" | "bn", variable: string) => void;
}

function CompositionSection({
  titleEn,
  titleBn,
  bodyEn,
  bodyBn,
  onTitleEn,
  onTitleBn,
  onBodyEn,
  onBodyBn,
  bodyEnRef,
  bodyBnRef,
  onInsertVariable,
}: CompositionSectionProps) {
  return (
    <Card className="space-y-s4">
      <CardTitle>Message</CardTitle>

      <div className="grid gap-s4 sm:grid-cols-2">
        <label className="block">
          <span className={FIELD_LABEL_CLASS}>Title (English)</span>
          <input
            value={titleEn}
            onChange={(e) => onTitleEn(e.target.value)}
            placeholder="e.g. Your rent is due"
            className={INPUT_CLASS}
          />
        </label>
        <label className="block">
          <span className={FIELD_LABEL_CLASS}>Title (Bangla)</span>
          <input
            value={titleBn}
            onChange={(e) => onTitleBn(e.target.value)}
            placeholder="যেমন আপনার ভাড়া বাকি"
            className={INPUT_CLASS}
            dir="auto"
          />
        </label>
      </div>

      <VariableChips
        label="Insert variable into English body"
        onInsert={(v) => onInsertVariable("en", v)}
      />
      <label className="block">
        <span className={FIELD_LABEL_CLASS}>Body (English)</span>
        <textarea
          ref={bodyEnRef}
          value={bodyEn}
          onChange={(e) => onBodyEn(e.target.value)}
          rows={3}
          placeholder="Hi {name}, your rent for {unit} is due."
          className={INPUT_CLASS}
        />
      </label>

      <VariableChips
        label="Insert variable into Bangla body"
        onInsert={(v) => onInsertVariable("bn", v)}
      />
      <label className="block">
        <span className={FIELD_LABEL_CLASS}>Body (Bangla)</span>
        <textarea
          ref={bodyBnRef}
          value={bodyBn}
          onChange={(e) => onBodyBn(e.target.value)}
          rows={3}
          placeholder="হ্যালো {name}, {unit} এর ভাড়া বাকি।"
          className={INPUT_CLASS}
          dir="auto"
        />
      </label>
    </Card>
  );
}

interface VariableChipsProps {
  label: string;
  onInsert: (variable: string) => void;
}

function VariableChips({ label, onInsert }: VariableChipsProps) {
  return (
    <div className="flex flex-wrap items-center gap-s2" aria-label={label}>
      {TEMPLATE_VARIABLES.map((variable) => (
        <button
          key={variable}
          type="button"
          onClick={() => onInsert(variable)}
          className="rounded-chip bg-butterBg px-s3 py-s1 font-mono text-xs font-semibold text-butterDk transition-colors hover:bg-butter"
        >
          {variable}
        </button>
      ))}
    </div>
  );
}

interface ScheduleSectionProps {
  scheduleType: ScheduleType;
  onScheduleType: (t: ScheduleType) => void;
  scheduledAt: string;
  onScheduledAt: (v: string) => void;
  cronMinute: string;
  cronHour: string;
  cronDayOfWeek: string;
  onCronMinute: (v: string) => void;
  onCronHour: (v: string) => void;
  onCronDayOfWeek: (v: string) => void;
}

function ScheduleSection({
  scheduleType,
  onScheduleType,
  scheduledAt,
  onScheduledAt,
  cronMinute,
  cronHour,
  cronDayOfWeek,
  onCronMinute,
  onCronHour,
  onCronDayOfWeek,
}: ScheduleSectionProps) {
  return (
    <Card className="space-y-s4">
      <CardTitle>Schedule</CardTitle>
      <div
        role="radiogroup"
        aria-label="Schedule type"
        className="flex flex-wrap gap-s2"
      >
        {SCHEDULE_TYPES.map((type) => {
          const selected = type === scheduleType;
          return (
            <button
              key={type}
              type="button"
              role="radio"
              aria-checked={selected}
              onClick={() => onScheduleType(type)}
              className={
                "rounded-button px-s4 py-s2 font-title text-sm font-semibold transition-colors " +
                (selected
                  ? "bg-ink text-card"
                  : "bg-sageBg text-ink hover:bg-line")
              }
            >
              {SCHEDULE_LABELS[type]}
            </button>
          );
        })}
      </div>

      {scheduleType === "scheduled" ? (
        <label className="block">
          <span className={FIELD_LABEL_CLASS}>Send at</span>
          <input
            type="datetime-local"
            value={scheduledAt}
            onChange={(e) => onScheduledAt(e.target.value)}
            className={INPUT_CLASS}
          />
        </label>
      ) : null}

      {scheduleType === "recurring" ? (
        <div className="grid gap-s3 sm:grid-cols-3">
          <label className="block">
            <span className={FIELD_LABEL_CLASS}>Minute</span>
            <input
              value={cronMinute}
              onChange={(e) => onCronMinute(e.target.value)}
              placeholder="0"
              className={INPUT_CLASS}
            />
          </label>
          <label className="block">
            <span className={FIELD_LABEL_CLASS}>Hour</span>
            <input
              value={cronHour}
              onChange={(e) => onCronHour(e.target.value)}
              placeholder="9"
              className={INPUT_CLASS}
            />
          </label>
          <label className="block">
            <span className={FIELD_LABEL_CLASS}>Day of week</span>
            <input
              value={cronDayOfWeek}
              onChange={(e) => onCronDayOfWeek(e.target.value)}
              placeholder="*"
              className={INPUT_CLASS}
            />
          </label>
        </div>
      ) : null}
    </Card>
  );
}

interface PreviewSidebarProps {
  channels: ChannelValue[];
  reach: number | null;
  cost: number | null;
  canSubmit: boolean;
  isPending: boolean;
  isError: boolean;
  onSubmit: () => void;
}

function PreviewSidebar({
  channels,
  reach,
  cost,
  canSubmit,
  isPending,
  isError,
  onSubmit,
}: PreviewSidebarProps) {
  return (
    <Card className="h-fit space-y-s4 lg:sticky lg:top-s5">
      <CardTitle className="flex items-center gap-s2">
        <Users size={18} className="text-sage" aria-hidden /> Reach &amp; cost
      </CardTitle>

      <dl className="space-y-s3">
        <div className="flex items-center justify-between">
          <dt className="text-sm text-muted">Estimated reach</dt>
          <dd className="font-title text-lg font-bold text-ink">
            {reach === null ? "—" : reach.toLocaleString("en-US")}
          </dd>
        </div>
        <div className="flex items-center justify-between">
          <dt className="text-sm text-muted">Estimated cost</dt>
          <dd className="font-title text-lg font-bold text-ink">
            {cost === null ? "—" : taka(cost)}
          </dd>
        </div>
      </dl>

      <div className="flex flex-wrap gap-s2">
        {channels.length === 0 ? (
          <span className="text-xs text-muted">No channels selected</span>
        ) : (
          channels.map((c) => (
            <Chip key={c} tone="neutral">
              {CHANNEL_LABELS[c]}
            </Chip>
          ))
        )}
      </div>

      {reach === null ? (
        <p className="text-xs text-muted">
          Final reach and cost are resolved on the server when you send.
        </p>
      ) : null}

      {isError ? (
        <p role="alert" className="text-sm text-roseDk">
          Could not send the notification. Check the fields and try again.
        </p>
      ) : null}

      <Button
        className="w-full"
        onClick={onSubmit}
        disabled={!canSubmit}
        aria-label="Send notification"
      >
        <Send size={16} aria-hidden />
        {isPending ? "Sending…" : "Send notification"}
      </Button>
    </Card>
  );
}

interface SuccessPanelProps {
  result: ComposeResult;
  onCompose: () => void;
}

function SuccessPanel({ result, onCompose }: SuccessPanelProps) {
  const cost = Number(result.estimated_cost);
  return (
    <div className="space-y-s6">
      <h1 className="font-title text-2xl font-bold text-ink">
        Compose notification
      </h1>
      <Card className="space-y-s4">
        <div className="flex items-center gap-s3">
          <CheckCircle2 size={24} className="text-sageDk" aria-hidden />
          <CardTitle>Notification {result.status}</CardTitle>
        </div>
        <dl className="grid gap-s4 sm:grid-cols-2">
          <div>
            <dt className="text-xs uppercase tracking-wide text-muted">
              Reach
            </dt>
            <dd className="mt-s1 font-title text-lg font-bold text-ink">
              {result.reach.toLocaleString("en-US")}
            </dd>
          </div>
          <div>
            <dt className="text-xs uppercase tracking-wide text-muted">
              Estimated cost
            </dt>
            <dd className="mt-s1 font-title text-lg font-bold text-ink">
              {taka(Number.isFinite(cost) ? cost : 0)}
            </dd>
          </div>
        </dl>
        <Button onClick={onCompose}>Compose another</Button>
      </Card>
    </div>
  );
}
