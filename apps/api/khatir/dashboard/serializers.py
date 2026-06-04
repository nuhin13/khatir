"""DRF serializers for the dashboard endpoint (EPIC-09 · T-002 §3/§7).

Read-only, output-shaping serializers over the typed
:class:`~khatir.dashboard.selectors.DashboardMetrics` dataclass produced by
T-001. They never bind to a model and never accept input — the dashboard is a
pure read. Money fields are rendered as fixed-2dp strings (the project's money
JSON convention); ``occupancy`` / ``late_payer_count`` are ints and rates are
floats.
"""

from __future__ import annotations

from rest_framework import serializers


class MonthPointSerializer(serializers.Serializer):
    """One ``YYYY-MM`` point of the collected-vs-expense time series."""

    period = serializers.CharField(read_only=True)
    collected = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )
    expense = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )


class CategoryTotalSerializer(serializers.Serializer):
    """One expense-category total in the top-categories breakdown."""

    category = serializers.CharField(read_only=True)
    amount = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )


class DashboardSerializer(serializers.Serializer):
    """The full dashboard payload — every metric in a single response body."""

    total_collected = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )
    total_pending = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )
    total_overdue = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )
    collection_rate = serializers.FloatField(read_only=True)
    occupied_units = serializers.IntegerField(read_only=True)
    total_units = serializers.IntegerField(read_only=True)
    occupancy_rate = serializers.FloatField(read_only=True)
    total_income = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )
    total_expense = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )
    net = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    late_payer_count = serializers.IntegerField(read_only=True)
    monthly_series = MonthPointSerializer(many=True, read_only=True)
    top_expense_categories = CategoryTotalSerializer(many=True, read_only=True)
