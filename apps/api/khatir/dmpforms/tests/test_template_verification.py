"""Golden field-verification test for the DMP form (EPIC-05 T-010).

The release gate for the wedge. Asserts the renderer (T-003) places every
official DMP tenant-registration field — documented in
``documnets/docs/epics/EPIC-05-dmp-form/T-010-dmp-field-map.md`` — at a stable,
named position, that every assembled value appears in the rendered PDF, and that
output is byte-for-byte deterministic for a fixed input + template version.

The ``OFFICIAL_FIELDS`` tuple below is the test's frozen copy of the canonical
field list. If the official form changes: update the field-map doc, the
renderer's ``FIELD_LAYOUT``, this tuple, and bump ``dmp_template_version`` —
together. Pixel-overlay confirmation against the authoritative scanned master is
pending founder input (T-010 §15); this test locks the field set and positions
so only the position constants need confirming once the scan arrives.
"""

from __future__ import annotations

from khatir.dmpforms.dto import DmpData, FamilyMemberData
from khatir.dmpforms.pdf import FIELD_LAYOUT, FieldSpec, render_dmp_pdf

TEMPLATE_VERSION = "2026.1"

# Frozen copy of the canonical official field list (T-010 field-map §3, rows 1-9).
# Each entry is the (DmpData attribute key, human label) the form must carry.
OFFICIAL_FIELDS: tuple[tuple[str, str], ...] = (
    ("tenant_name", "Tenant name"),
    ("nid_number", "NID number"),
    ("dob", "Date of birth"),
    ("permanent_address", "Permanent address"),
    ("present_address", "Present address"),
    ("building_address", "Building address"),
    ("building_area", "Area"),
    ("landlord_name", "Landlord name"),
    ("landlord_phone", "Landlord phone"),
)


def _sample_data() -> DmpData:
    """A fully-populated DmpData covering every official field + a family row."""
    return DmpData(
        tenant_name="Karim Uddin",
        nid_number="1234567788",
        dob="1990-01-15",
        permanent_address="Village Rd, Comilla",
        present_address="House 4, Mirpur, Dhaka",
        building_address="Karim Manzil, Road 7",
        building_area="Mirpur-10",
        landlord_name="Owner Mia",
        landlord_phone="+8801712340001",
        family_members=(FamilyMemberData(name="Rahima", relation="spouse"),),
    )


# ── field-set parity: every official field is in the layout, in order ─────────


def test_layout_covers_every_official_field() -> None:
    """FIELD_LAYOUT carries exactly the canonical official fields, in order."""
    layout_keys = tuple(spec.key for spec in FIELD_LAYOUT)
    official_keys = tuple(key for key, _ in OFFICIAL_FIELDS)
    assert layout_keys == official_keys


def test_every_layout_field_exists_on_dto() -> None:
    """Each rendered field maps to a real DmpData attribute (no orphan fields)."""
    data = _sample_data()
    for spec in FIELD_LAYOUT:
        assert hasattr(data, spec.key), f"DmpData missing official field {spec.key!r}"


def test_field_specs_have_distinct_positions() -> None:
    """No two fixed fields share a position (would overprint on the form)."""
    positions = [(spec.x, spec.y) for spec in FIELD_LAYOUT]
    assert len(positions) == len(set(positions))


def test_field_labels_match_official() -> None:
    """The rendered label for each field matches the canonical caption."""
    by_key: dict[str, FieldSpec] = {spec.key: spec for spec in FIELD_LAYOUT}
    for key, label in OFFICIAL_FIELDS:
        assert by_key[key].label == label


# ── golden: every value is rendered into the PDF at its position ──────────────


def test_every_field_value_present_in_pdf() -> None:
    """Each official field's value appears in the rendered PDF content stream."""
    data = _sample_data()
    pdf = render_dmp_pdf(data, TEMPLATE_VERSION)

    for spec in FIELD_LAYOUT:
        value = getattr(data, spec.key)
        # Value is drawn as "label: value" — assert the value text is present.
        assert value.encode("latin-1") in pdf, f"{spec.key} value not rendered"
        # And drawn at its declared baseline via an absolute text matrix.
        matrix = f"1 0 0 1 {spec.x} {spec.y} Tm".encode("latin-1")
        assert matrix in pdf, f"{spec.key} not positioned at ({spec.x}, {spec.y})"


def test_template_version_rendered() -> None:
    """The template version is stamped on the form."""
    pdf = render_dmp_pdf(_sample_data(), TEMPLATE_VERSION)
    assert TEMPLATE_VERSION.encode("latin-1") in pdf


def test_family_members_rendered() -> None:
    data = _sample_data()
    pdf = render_dmp_pdf(data, TEMPLATE_VERSION)
    assert b"Rahima" in pdf
    assert b"spouse" in pdf


# ── golden: deterministic, valid PDF ──────────────────────────────────────────


def test_render_is_byte_for_byte_deterministic() -> None:
    data = _sample_data()
    assert render_dmp_pdf(data, TEMPLATE_VERSION) == render_dmp_pdf(data, TEMPLATE_VERSION)


def test_render_produces_valid_pdf_envelope() -> None:
    pdf = render_dmp_pdf(_sample_data(), TEMPLATE_VERSION)
    assert pdf.startswith(b"%PDF")
    assert pdf.rstrip().endswith(b"%%EOF")


def test_pdf_string_delimiters_escaped() -> None:
    """Field values containing PDF delimiters stay valid (no stream corruption)."""
    data = DmpData(tenant_name="A (test) \\ name", landlord_name="X)Y(Z")
    pdf = render_dmp_pdf(data, TEMPLATE_VERSION)
    assert pdf.startswith(b"%PDF")
    assert pdf.rstrip().endswith(b"%%EOF")
    # Parens inside the value are escaped in the content stream.
    assert rb"\(test\)" in pdf
