"""Helpers for consistent success / paginated responses.

Success responses return the resource directly (DRF default). Lists are wrapped
in the ``{results, pagination}`` envelope (``04_coding_conventions.md`` §2).
Pagination classes in ``core.pagination`` produce the same shape automatically;
these helpers are for hand-built (non-DRF-paginator) list responses.
"""

from __future__ import annotations

from typing import Any

from rest_framework import status as http_status
from rest_framework.response import Response


def success(data: Any, *, status: int = http_status.HTTP_200_OK) -> Response:
    """Return a resource/data payload directly with the given status."""
    return Response(data, status=status)


def created(data: Any) -> Response:
    """201 Created with the new resource as the body."""
    return Response(data, status=http_status.HTTP_201_CREATED)


def no_content() -> Response:
    """204 No Content (e.g. after a delete)."""
    return Response(status=http_status.HTTP_204_NO_CONTENT)


def paginated(
    results: list[Any],
    *,
    count: int,
    next: str | None = None,
    previous: str | None = None,
    status: int = http_status.HTTP_200_OK,
) -> Response:
    """Wrap a list in the standard ``{results, pagination}`` envelope."""
    return Response(
        {
            "results": results,
            "pagination": {"next": next, "previous": previous, "count": count},
        },
        status=status,
    )
