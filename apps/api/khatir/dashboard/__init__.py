"""Dashboard domain — read-only aggregation selectors (EPIC-09 · T-001).

This app owns no models. It is a thin read-side package that computes landlord
dashboard metrics from existing domain data (``leases.RentSchedule``,
``maintenance.Expense``, ``properties.Unit``) via ORM aggregations. All reads are
scoped to the requesting user through each domain's ``for_user`` manager so a
landlord only ever sees their own numbers — a missing scope is a P0 security bug
(``04_coding_conventions.md`` §3).

Because there are no models there is no migration and nothing to add to the app
registry's model graph; the package is still registered as a Django app
(``DashboardConfig``) so its tests and selectors live under a clear namespace.
"""
