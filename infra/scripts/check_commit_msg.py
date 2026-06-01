#!/usr/bin/env python3
"""Validate commit messages against Conventional Commits + epic tag rules.

Rules:
- Subject must be a Conventional Commit: ``<type>(<scope>)?(!)?: <subject>``.
- Allowed types: build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test.
- ``feat``, ``fix``, ``refactor``, ``perf`` and ``test`` commits MUST include an epic
  tag of the form ``[EPIC-NN T-XXX]`` somewhere in the message.
- ``docs`` and ``chore`` (and other low-risk types) are exempt from the epic tag.
- Merge/revert/fixup commits are skipped.

Usage (pre-commit passes the commit-msg file path as the first argument)::

    check_commit_msg.py .git/COMMIT_EDITMSG
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

CONVENTIONAL_TYPES = (
    "build",
    "chore",
    "ci",
    "docs",
    "feat",
    "fix",
    "perf",
    "refactor",
    "revert",
    "style",
    "test",
)

# Types that must reference an epic/task tag.
TAGGED_TYPES = {"feat", "fix", "refactor", "perf", "test"}

SUBJECT_RE = re.compile(
    r"^(?P<type>" + "|".join(CONVENTIONAL_TYPES) + r")"
    r"(?P<scope>\([\w./-]+\))?"
    r"(?P<breaking>!)?"
    r": .+"
)

EPIC_TAG_RE = re.compile(r"\[EPIC-\d{2} T-\d{3}\]")

# Lines we should not treat as the subject (auto-generated commits).
SKIP_PREFIXES = ("Merge ", "Revert ", "fixup!", "squash!")


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("check_commit_msg: missing commit message file path", file=sys.stderr)
        return 1

    msg_path = Path(argv[1])
    try:
        raw = msg_path.read_text(encoding="utf-8")
    except OSError as exc:  # pragma: no cover - defensive
        print(f"check_commit_msg: cannot read {msg_path}: {exc}", file=sys.stderr)
        return 1

    # Drop comment lines (git editor template) and trailing whitespace.
    lines = [ln for ln in raw.splitlines() if not ln.lstrip().startswith("#")]
    non_empty = [ln for ln in lines if ln.strip()]
    if not non_empty:
        print("check_commit_msg: empty commit message", file=sys.stderr)
        return 1

    subject = non_empty[0]
    body = "\n".join(non_empty)

    if subject.startswith(SKIP_PREFIXES):
        return 0

    match = SUBJECT_RE.match(subject)
    if not match:
        print(
            "check_commit_msg: subject is not a Conventional Commit.\n"
            f"  got:      {subject!r}\n"
            "  expected: <type>(<scope>)?: <subject>\n"
            f"  types:    {', '.join(CONVENTIONAL_TYPES)}",
            file=sys.stderr,
        )
        return 1

    commit_type = match.group("type")
    if commit_type in TAGGED_TYPES and not EPIC_TAG_RE.search(body):
        print(
            f"check_commit_msg: {commit_type!r} commits must include an epic tag "
            "'[EPIC-NN T-XXX]'.\n"
            f"  subject: {subject!r}\n"
            "  (docs/chore commits are exempt)",
            file=sys.stderr,
        )
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
