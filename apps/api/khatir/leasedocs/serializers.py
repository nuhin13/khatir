"""Lease-document API serializers (EPIC-18 · T-004).

Read serialization of a :class:`LeaseDocument`, plus the edit request shape for
``PATCH /lease-documents/{id}`` (a partial clause map). Write paths stay thin:
the view validates with a serializer, then hands the cleaned data to a service —
business rules (required-clause guarantee, draft-only edit) live in the model /
service, never here.
"""

from __future__ import annotations

from typing import Any

from rest_framework import serializers

from .models import LeaseDocument


class LeaseDocumentSerializer(serializers.ModelSerializer[LeaseDocument]):
    """Read representation of a generated lease document."""

    class Meta:
        model = LeaseDocument
        fields = (
            "id",
            "lease",
            "content_json",
            "status",
            "model_used",
            "generated_at",
            "created_at",
            "updated_at",
        )
        read_only_fields = fields


class LeaseDocumentEditSerializer(serializers.Serializer[Any]):
    """Request body for editing a draft document's clauses.

    ``clauses`` is a partial map of ``{clause_key: clause}`` where each clause is
    either a scaffold-shaped object (``{title_en, title_bn, body, …}``) or a bare
    body string. It is merged onto the existing ``content_json`` by the service.
    """

    clauses = serializers.DictField(allow_empty=False)
