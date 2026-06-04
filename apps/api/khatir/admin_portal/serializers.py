"""Request/response serializers for the admin auth endpoints — EPIC-11.T-003."""

from __future__ import annotations

from rest_framework import serializers

from .models import AdminUser


class AdminLoginSerializer(serializers.Serializer[dict[str, str]]):
    """``POST /admin/api/auth/login`` request body."""

    email = serializers.EmailField()
    password = serializers.CharField(trim_whitespace=False, write_only=True)


class AdminVerifyMfaSerializer(serializers.Serializer[dict[str, str]]):
    """``POST /admin/api/auth/verify-mfa`` request body."""

    mfa_token = serializers.CharField()
    code = serializers.CharField(max_length=10)


class AdminUserSerializer(serializers.ModelSerializer[AdminUser]):
    """Public projection of an admin account (never exposes secrets)."""

    class Meta:
        model = AdminUser
        fields = ("id", "email", "name", "role", "scope", "disabled", "last_login_at")
        read_only_fields = fields
