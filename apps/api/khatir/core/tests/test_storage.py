"""Tests for the encrypted object-storage helper (EPIC-04 T-003).

Exercises both backends:

* the S3 backend (boto3) against an in-memory bucket via ``moto``, asserting
  objects are stored ``private`` with server-side encryption and retrieved only
  through a TTL-bounded presigned URL;
* the local filesystem fallback used in dev/test when no bucket is configured.
"""

from __future__ import annotations

import urllib.parse
from collections.abc import Iterator

import boto3
import pytest
from moto import mock_aws

from khatir.core import storage

_BUCKET = "khatir-media-test"


@pytest.fixture
def s3_backend(settings: object) -> Iterator[object]:
    """Configure the S3 backend against a fresh moto bucket."""
    settings.S3_BUCKET = _BUCKET
    settings.S3_ENDPOINT_URL = ""
    settings.S3_REGION = "us-east-1"
    settings.S3_ACCESS_KEY = "test"
    settings.S3_SECRET_KEY = "test"
    settings.S3_SSE = "AES256"
    storage._s3_client.cache_clear()
    with mock_aws():
        client = boto3.client("s3", region_name="us-east-1")
        client.create_bucket(Bucket=_BUCKET)
        yield client
    storage._s3_client.cache_clear()


# ── S3 backend ─────────────────────────────────────────────────────────


def test_store_returns_opaque_key(s3_backend: object) -> None:
    key = storage.store_encrypted(b"nid-image-bytes", kind="nid")
    # Opaque, kind-namespaced, unguessable — not a URL, not the raw filename.
    assert key.startswith("nid/")
    assert "http" not in key
    assert len(key.split("/", 1)[1]) >= 16


def test_store_and_signed_url_roundtrip(s3_backend: object) -> None:
    payload = b"sensitive-proof-bytes"
    key = storage.store_encrypted(payload, kind="proof")

    url = storage.signed_url(key, ttl=120)
    parsed = urllib.parse.urlparse(url)
    qs = urllib.parse.parse_qs(parsed.query)

    # Presigned URL: time-limited credentials, not a bare public link.
    assert key in url
    assert qs.get("X-Amz-Expires") == ["120"]
    assert "X-Amz-Signature" in qs

    # The bytes actually round-trip through the bucket.
    obj = s3_backend.get_object(Bucket=_BUCKET, Key=key)
    assert obj["Body"].read() == payload


def test_stored_object_is_encrypted_at_rest(s3_backend: object) -> None:
    key = storage.store_encrypted(b"x", kind="nid")
    head = s3_backend.head_object(Bucket=_BUCKET, Key=key)
    assert head["ServerSideEncryption"] == "AES256"


def test_stored_object_not_public(s3_backend: object) -> None:
    key = storage.store_encrypted(b"x", kind="nid")
    acl = s3_backend.get_object_acl(Bucket=_BUCKET, Key=key)
    # No grant to AllUsers / AuthenticatedUsers — never public-readable.
    grantee_uris = [
        g["Grantee"].get("URI", "")
        for g in acl["Grants"]
        if g["Grantee"].get("Type") == "Group"
    ]
    assert not any("AllUsers" in uri or "AuthenticatedUsers" in uri for uri in grantee_uris)


def test_delete_removes_object(s3_backend: object) -> None:
    key = storage.store_encrypted(b"x", kind="pdf")
    storage.delete(key)
    with pytest.raises(s3_backend.exceptions.NoSuchKey):
        s3_backend.get_object(Bucket=_BUCKET, Key=key)


def test_delete_is_idempotent(s3_backend: object) -> None:
    # Deleting a never-stored key must not raise (S3 delete is idempotent).
    storage.delete("nid/does-not-exist")


def test_unknown_kind_rejected(s3_backend: object) -> None:
    with pytest.raises(ValueError, match="unknown storage kind"):
        storage.store_encrypted(b"x", kind="bogus")


# ── Filesystem fallback (no bucket configured) ─────────────────────────


@pytest.fixture
def fs_backend(settings: object, tmp_path: object) -> Iterator[None]:
    settings.S3_BUCKET = ""
    settings.ENCRYPTED_STORAGE_ROOT = str(tmp_path)
    settings.ENCRYPTED_STORAGE_PUBLIC_BASE = "https://storage.local"
    storage._s3_client.cache_clear()
    yield
    storage._s3_client.cache_clear()


def test_fs_store_signed_url_and_delete(fs_backend: None, tmp_path: object) -> None:
    payload = b"local-bytes"
    key = storage.store_encrypted(payload, kind="nid")
    assert key.startswith("nid/")
    assert (tmp_path / key).read_bytes() == payload

    url = storage.signed_url(key, ttl=30)
    assert key in url
    assert "ttl=30" in url
    assert "sig=" in url

    storage.delete(key)
    assert not (tmp_path / key).exists()
    # Idempotent.
    storage.delete(key)


def test_fs_signed_url_is_not_a_public_path(fs_backend: None) -> None:
    key = storage.store_encrypted(b"x", kind="proof")
    url = storage.signed_url(key)
    # A signature query param guards retrieval — not a bare public file URL.
    assert "sig=" in url
