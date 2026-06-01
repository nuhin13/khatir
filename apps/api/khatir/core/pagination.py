"""Standard pagination classes emitting the project envelope.

Both classes produce (``04_coding_conventions.md`` §2)::

    {"results": [...], "pagination": {"next": ..., "previous": ..., "count": N}}

- ``StandardPageNumberPagination`` — small admin tables (default).
- ``StandardCursorPagination`` — large/append-only sets (audit log, notifications).

Default page size 20, max 100 via ``?page_size=``.
"""

from __future__ import annotations

from typing import Any

from rest_framework.pagination import CursorPagination, PageNumberPagination
from rest_framework.response import Response


class StandardPageNumberPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 100

    def get_paginated_response(self, data: Any) -> Response:
        assert self.page is not None
        return Response(
            {
                "results": data,
                "pagination": {
                    "next": self.get_next_link(),
                    "previous": self.get_previous_link(),
                    "count": self.page.paginator.count,
                },
            }
        )


class StandardCursorPagination(CursorPagination):
    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 100
    ordering = "-created_at"

    def get_paginated_response(self, data: Any) -> Response:
        return Response(
            {
                "results": data,
                "pagination": {
                    "next": self.get_next_link(),
                    "previous": self.get_previous_link(),
                    # Cursor pagination has no cheap exact count.
                    "count": None,
                },
            }
        )
