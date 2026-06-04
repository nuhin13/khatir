"""Expense API — CRUD + filtered list + CSV export under ``/api/v1/expenses``.

A ``GenericViewSet`` whose queryset is **always** scoped through
``Expense.objects.for_user`` (``ForUserQuerySetMixin``) so a user never sees
another user's expenses — a missing scope is a P0 bug (``04_coding_conventions``
§3). Reachable only as a landlord or manager (``IsLandlordOrManager``); object
access is guarded by ``IsOwnerOfExpense``. Because list scoping already hides
foreign rows, an unknown/foreign id resolves to **404** (never 403).

The list (and the CSV export) accept optional ``building``, ``unit`` and
``date_from`` / ``date_to`` filters. Manual + auto (``source=request``) expenses
both appear in listings (T-003 §15). Views stay thin: validate → call a service
→ serialize. The owning landlord is derived server-side via the unit's building,
never trusted from the client.

The CSV export **streams** so a large set never has to be buffered in memory
(T-003 §15) and is scoped exactly like the list.
"""

from __future__ import annotations

import csv
import datetime
from typing import Any, cast

from django.db.models import QuerySet
from django.http import StreamingHttpResponse
from rest_framework import mixins, viewsets
from rest_framework.decorators import action
from rest_framework.request import Request
from rest_framework.response import Response

from khatir.accounts.models import User
from khatir.core.permissions import ForUserQuerySetMixin, IsLandlordOrManager
from khatir.core.responses import created, no_content, success

from .models import Expense
from .permissions import IsOwnerOfExpense
from .selectors import expense_total_by_category, expense_total_by_month
from .serializers import (
    ExpenseCreateSerializer,
    ExpenseSerializer,
    ExpenseUpdateSerializer,
)
from .services import create_expense, delete_expense, update_expense

_CSV_COLUMNS = (
    "id",
    "unit_id",
    "category",
    "amount",
    "date",
    "source",
    "note",
    "created_at",
)


class _Echo:
    """A write-only file-like object that echoes what it is given.

    Lets ``csv.writer`` produce rows lazily for ``StreamingHttpResponse`` without
    buffering the whole export in memory.
    """

    def write(self, value: str) -> str:
        return value


def _parse_date(raw: str | None) -> datetime.date | None:
    """Parse an ISO ``YYYY-MM-DD`` query param, or ``None`` if absent/blank."""
    if not raw:
        return None
    try:
        return datetime.date.fromisoformat(raw)
    except ValueError:
        return None


class ExpenseViewSet(
    ForUserQuerySetMixin,
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    viewsets.GenericViewSet[Expense],
):
    """CRUD + filtered list + CSV export for expenses, scoped to the user."""

    queryset = cast("QuerySet[Expense]", Expense.objects.all())
    serializer_class = ExpenseSerializer
    permission_classes = [IsLandlordOrManager & IsOwnerOfExpense]

    def _filter_kwargs(self) -> dict[str, Any]:
        """Parse the optional ``building`` / ``unit`` / ``date_*`` query params.

        Shared by the list/export filtering and the summary selectors so the two
        paths apply identical filters.
        """
        params = self.request.query_params
        return {
            "unit": params.get("unit") or None,
            "building": params.get("building") or None,
            "date_from": _parse_date(params.get("date_from")),
            "date_to": _parse_date(params.get("date_to")),
        }

    def _filtered_queryset(self) -> QuerySet[Expense]:
        """The user-scoped queryset narrowed by the request's filter params.

        Filters (all optional): ``building``, ``unit``, ``date_from``,
        ``date_to``. Applied on top of ``for_user`` scoping so they can only ever
        narrow the already-isolated set.
        """
        qs = self.get_queryset()
        filters = self._filter_kwargs()
        if filters["unit"]:
            qs = qs.filter(unit_id=filters["unit"])
        if filters["building"]:
            qs = qs.filter(unit__building_id=filters["building"])
        if filters["date_from"] is not None:
            qs = qs.filter(date__gte=filters["date_from"])
        if filters["date_to"] is not None:
            qs = qs.filter(date__lte=filters["date_to"])
        return qs

    def list(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        page = self.paginate_queryset(self._filtered_queryset())
        serializer = self.get_serializer(page, many=True)
        return self.get_paginated_response(serializer.data)

    def retrieve(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        expense = self.get_object()
        return success(ExpenseSerializer(expense).data)

    def create(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        serializer = ExpenseCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        expense = create_expense(
            actor=cast(User, request.user), **serializer.validated_data
        )
        return created(ExpenseSerializer(expense).data)

    def partial_update(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        expense = self.get_object()
        serializer = ExpenseUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        expense = update_expense(
            actor=cast(User, request.user),
            expense=expense,
            **serializer.validated_data,
        )
        return success(ExpenseSerializer(expense).data)

    def destroy(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        expense = self.get_object()
        delete_expense(actor=cast(User, request.user), expense=expense)
        return no_content()

    @action(detail=False, methods=["get"], url_path="export")
    def export(self, request: Request, *args: Any, **kwargs: Any) -> StreamingHttpResponse:
        """Stream the (scoped + filtered) expenses as a CSV download (T-003 §7).

        Uses the same scoping and filters as ``list`` so the export can never
        leak another user's expenses. Streams row-by-row so a large set is never
        fully buffered in memory.
        """
        queryset = self._filtered_queryset().order_by("-date", "-created_at")
        writer = csv.writer(_Echo())

        def rows() -> Any:
            yield writer.writerow(_CSV_COLUMNS)
            for expense in queryset.iterator():
                yield writer.writerow(
                    [
                        str(expense.pk),
                        str(expense.unit_id),
                        expense.category,
                        str(expense.amount),
                        expense.date.isoformat(),
                        expense.source,
                        expense.note,
                        expense.created_at.isoformat(),
                    ]
                )

        response = StreamingHttpResponse(rows(), content_type="text/csv")
        response["Content-Disposition"] = 'attachment; filename="expenses.csv"'
        return response

    @action(detail=False, methods=["get"], url_path="summary")
    def summary(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """Expense totals by category + by month for the dashboard (T-012 §7).

        Read-only: delegates to the ``selectors`` aggregation (scoped to the user
        and narrowed by the same ``building`` / ``unit`` / ``date_*`` filters as
        the list). Amounts are serialized as strings to preserve Decimal
        precision; each month bucket is the first day of that month (ISO date).
        """
        actor = cast(User, request.user)
        filters = self._filter_kwargs()
        by_category = expense_total_by_category(actor, **filters)
        by_month = expense_total_by_month(actor, **filters)
        return success(
            {
                "by_category": [
                    {"category": row["category"], "total": str(row["total"])}
                    for row in by_category
                ],
                "by_month": [
                    {"month": row["month"].isoformat(), "total": str(row["total"])}
                    for row in by_month
                ],
            }
        )
