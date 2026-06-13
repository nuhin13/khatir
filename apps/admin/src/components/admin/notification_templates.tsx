"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Pencil, X } from "lucide-react";
import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Chip } from "@/components/ui/chip";
import { Toggle } from "@/components/ui/toggle";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeaderCell,
  TableRow,
} from "@/components/ui/table";
import {
  ChannelSelector,
  CHANNEL_LABELS,
} from "@/components/admin/channel_selector";
import { CHANNELS } from "@/lib/api/notifications";
import {
  fetchTemplates,
  templatesQueryKey,
  templatesQueryPrefix,
  updateTemplate,
  type ChannelValue,
  type NotificationTemplate,
  type TemplateUpdateInput,
} from "@/lib/api/notifications";

/**
 * Notification templates — EPIC-15.T-013.
 *
 * The Templates tab from `04_Admin_Portal_Khatir.md` §4.5.3: a list of the
 * system-triggered notification templates (key, trigger event, delivery
 * channels, active flag). Each template is editable for its bilingual
 * title/body, channels, and active flag (`PATCH /admin/api/notification-
 * templates/{key}`, T-008). The `trigger_event` is immutable — it is the
 * internal event that fires the template — so it is surfaced read-only, and the
 * editor never sends it. A variable reference is shown so editors know which
 * `{placeholders}` each template substitutes per recipient.
 *
 * The super/ops route guard lives in the server page that renders this (it
 * mirrors the backend `IsPlatformAdmin` gate). All colours/spacing/radii come
 * from Notun Din token classes — no hardcoded prototype hex/px.
 */

const INPUT_CLASS =
  "mt-s2 w-full rounded-input border border-line bg-card px-s3 py-s2 font-body text-sm text-ink placeholder:text-muted focus:border-sage focus:outline-none";

const FIELD_LABEL_CLASS = "font-title text-xs font-semibold text-mutedDk";

/** Render a template's channels as readable chips. */
function ChannelChips({ channels }: { channels: string[] }) {
  if (channels.length === 0) {
    return <span className="text-xs text-muted">None</span>;
  }
  return (
    <span className="flex flex-wrap gap-s1">
      {channels.map((c) => (
        <Chip key={c} tone="neutral">
          {CHANNEL_LABELS[c as ChannelValue] ?? c}
        </Chip>
      ))}
    </span>
  );
}

export function NotificationTemplates() {
  const [editingKey, setEditingKey] = useState<string | null>(null);

  const { data, isPending, isError, refetch } = useQuery({
    queryKey: templatesQueryKey(),
    queryFn: fetchTemplates,
  });

  if (isPending) {
    return (
      <div className="space-y-s6">
        <Header />
        <Card
          className="h-64 animate-pulse"
          aria-busy
          aria-label="Loading notification templates"
        />
      </div>
    );
  }

  if (isError) {
    return (
      <div className="space-y-s6">
        <Header />
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Could not load notification templates</CardTitle>
          <CardDescription>
            The templates request failed. Check your connection and try again.
          </CardDescription>
          <Button onClick={() => void refetch()}>Retry</Button>
        </Card>
      </div>
    );
  }

  const editing =
    editingKey === null
      ? null
      : (data.find((t) => t.key === editingKey) ?? null);

  return (
    <div className="space-y-s6">
      <Header />

      {data.length === 0 ? (
        <Card className="flex flex-col items-center gap-s2 py-s8 text-center">
          <CardTitle>No templates</CardTitle>
          <CardDescription>
            No system notification templates have been seeded yet.
          </CardDescription>
        </Card>
      ) : (
        <Table>
          <TableHead>
            <TableRow>
              <TableHeaderCell>Template</TableHeaderCell>
              <TableHeaderCell>Trigger event</TableHeaderCell>
              <TableHeaderCell>Channels</TableHeaderCell>
              <TableHeaderCell>Active</TableHeaderCell>
              <TableHeaderCell>
                <span className="sr-only">Edit</span>
              </TableHeaderCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {data.map((template) => (
              <TableRow key={template.key}>
                <TableCell>
                  <span className="font-title text-sm font-semibold text-ink">
                    {template.title_en || template.key}
                  </span>
                  <span className="mt-s1 block font-mono text-xs text-muted">
                    {template.key}
                  </span>
                </TableCell>
                <TableCell>
                  <span className="font-mono text-xs text-mutedDk">
                    {template.trigger_event}
                  </span>
                </TableCell>
                <TableCell>
                  <ChannelChips channels={template.channels} />
                </TableCell>
                <TableCell>
                  <Chip tone={template.active ? "sage" : "neutral"}>
                    {template.active ? "Active" : "Inactive"}
                  </Chip>
                </TableCell>
                <TableCell className="text-right">
                  <Button
                    variant="secondary"
                    onClick={() => setEditingKey(template.key)}
                    aria-label={`Edit ${template.key}`}
                  >
                    <Pencil size={14} aria-hidden /> Edit
                  </Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      )}

      {editing ? (
        <TemplateEditor
          key={editing.key}
          template={editing}
          onClose={() => setEditingKey(null)}
        />
      ) : null}
    </div>
  );
}

function Header() {
  return (
    <div>
      <h1 className="font-title text-2xl font-bold text-ink">
        Notification templates
      </h1>
      <p className="mt-s1 text-sm text-muted">
        System-triggered notifications. Edit the bilingual title and body,
        delivery channels, and active flag. The trigger event is fixed and
        cannot be changed.
      </p>
    </div>
  );
}

interface TemplateEditorProps {
  template: NotificationTemplate;
  onClose: () => void;
}

function TemplateEditor({ template, onClose }: TemplateEditorProps) {
  const queryClient = useQueryClient();

  const [titleEn, setTitleEn] = useState(template.title_en);
  const [titleBn, setTitleBn] = useState(template.title_bn);
  const [bodyEn, setBodyEn] = useState(template.body_en);
  const [bodyBn, setBodyBn] = useState(template.body_bn);
  const [channels, setChannels] = useState<ChannelValue[]>(
    template.channels.filter((c): c is ChannelValue =>
      (CHANNELS as readonly string[]).includes(c),
    ),
  );
  const [active, setActive] = useState(template.active);

  // The editor is remounted per template (`key={editing.key}` at the call
  // site), so the `useState` initializers above always seed from the freshly
  // opened template — no synchronizing effect needed.

  const save = useMutation<
    NotificationTemplate,
    Error,
    { key: string; input: TemplateUpdateInput }
  >({
    mutationFn: ({ key, input }) => updateTemplate(key, input),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: templatesQueryPrefix });
      onClose();
    },
  });

  const toggleChannel = (channel: ChannelValue) => {
    setChannels((prev) =>
      prev.includes(channel)
        ? prev.filter((c) => c !== channel)
        : [...prev, channel],
    );
  };

  const contentValid =
    titleEn.trim().length > 0 &&
    titleBn.trim().length > 0 &&
    bodyEn.trim().length > 0 &&
    bodyBn.trim().length > 0;

  const canSave = contentValid && channels.length > 0 && !save.isPending;

  const submit = () => {
    save.mutate({
      key: template.key,
      input: {
        title_en: titleEn.trim(),
        title_bn: titleBn.trim(),
        body_en: bodyEn.trim(),
        body_bn: bodyBn.trim(),
        channels,
        active,
      },
    });
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label={`Edit template ${template.key}`}
      className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-ink/40 p-s5"
    >
      <Card className="w-full max-w-2xl space-y-s5">
        <div className="flex items-start justify-between gap-s3">
          <div>
            <CardTitle>Edit template</CardTitle>
            <p className="mt-s1 font-mono text-xs text-muted">{template.key}</p>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Close editor"
            className="rounded-button p-s1 text-muted transition-colors hover:bg-sageBg hover:text-ink"
          >
            <X size={18} aria-hidden />
          </button>
        </div>

        <dl className="grid gap-s4 sm:grid-cols-2">
          <div>
            <dt className={FIELD_LABEL_CLASS}>Trigger event (fixed)</dt>
            <dd className="mt-s1 font-mono text-sm text-ink">
              {template.trigger_event}
            </dd>
          </div>
          <div>
            <dt className={FIELD_LABEL_CLASS}>Variables</dt>
            <dd className="mt-s2 flex flex-wrap gap-s1">
              {template.variables.length === 0 ? (
                <span className="text-xs text-muted">None</span>
              ) : (
                template.variables.map((v) => (
                  <span
                    key={v}
                    className="rounded-chip bg-butterBg px-s3 py-s1 font-mono text-xs font-semibold text-butterDk"
                  >
                    {"{" + v + "}"}
                  </span>
                ))
              )}
            </dd>
          </div>
        </dl>

        <div className="grid gap-s4 sm:grid-cols-2">
          <label className="block">
            <span className={FIELD_LABEL_CLASS}>Title (English)</span>
            <input
              value={titleEn}
              onChange={(e) => setTitleEn(e.target.value)}
              className={INPUT_CLASS}
            />
          </label>
          <label className="block">
            <span className={FIELD_LABEL_CLASS}>Title (Bangla)</span>
            <input
              value={titleBn}
              onChange={(e) => setTitleBn(e.target.value)}
              className={INPUT_CLASS}
              dir="auto"
            />
          </label>
        </div>

        <label className="block">
          <span className={FIELD_LABEL_CLASS}>Body (English)</span>
          <textarea
            value={bodyEn}
            onChange={(e) => setBodyEn(e.target.value)}
            rows={3}
            className={INPUT_CLASS}
          />
        </label>

        <label className="block">
          <span className={FIELD_LABEL_CLASS}>Body (Bangla)</span>
          <textarea
            value={bodyBn}
            onChange={(e) => setBodyBn(e.target.value)}
            rows={3}
            className={INPUT_CLASS}
            dir="auto"
          />
        </label>

        <div>
          <span className={FIELD_LABEL_CLASS}>Channels</span>
          <div className="mt-s2">
            <ChannelSelector value={channels} onToggle={toggleChannel} />
          </div>
        </div>

        <div className="flex items-center gap-s3">
          <Toggle checked={active} onChange={setActive} label="Active" />
          <span className="font-title text-sm font-semibold text-ink">
            {active ? "Active" : "Inactive"}
          </span>
        </div>

        {save.isError ? (
          <p role="alert" className="text-sm text-roseDk">
            Could not save the template. Check the fields and try again.
          </p>
        ) : null}

        <div className="flex justify-end gap-s2">
          <Button variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button
            onClick={submit}
            disabled={!canSave}
            aria-label="Save template"
          >
            {save.isPending ? "Saving…" : "Save changes"}
          </Button>
        </div>
      </Card>
    </div>
  );
}
