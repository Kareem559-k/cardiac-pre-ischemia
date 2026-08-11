from __future__ import annotations

from pathlib import Path
from typing import Any

from .report_data import build_report_data
from .report_variants import generate_report_variant


def generate_report_pdf(report_path: Path, context: dict[str, Any]) -> dict[str, Any]:
    report_data = build_report_data(context)
    result = generate_report_variant(report_path, context, "approved")
    return {"report_data": report_data, "charts": result.get("charts", []), "variant": "approved"}
