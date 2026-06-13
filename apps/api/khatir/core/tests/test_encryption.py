"""Tests for Fernet encryption + masking."""

import pytest
from cryptography.fernet import InvalidToken

from khatir.core.encryption import decrypt, encrypt, mask


def test_encrypt_decrypt_roundtrip() -> None:
    plaintext = "1990123456789"
    token = encrypt(plaintext)
    assert token != plaintext
    assert decrypt(token) == plaintext


def test_ciphertext_is_nondeterministic() -> None:
    # Fernet embeds a random IV, so two encryptions differ.
    assert encrypt("same") != encrypt("same")


def test_decrypt_tampered_raises() -> None:
    token = encrypt("secret")
    with pytest.raises(InvalidToken):
        decrypt(token[:-2] + "xx")


def test_mask_keeps_last_four() -> None:
    assert mask("1990123456789") == "*********6789"


def test_mask_short_value_fully_masked() -> None:
    assert mask("12") == "**"


def test_mask_empty() -> None:
    assert mask("") == ""
