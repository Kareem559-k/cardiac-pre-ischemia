from __future__ import annotations

import csv
import json
import os
from collections import Counter
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

import numpy as np
import wfdb

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_FEATURE_DATA_DIR = Path(
    os.getenv("CARDIAC_AUDIT_FEATURE_DIR", str(PROJECT_ROOT / "ECG_FEATURE_DATA"))
)
DEFAULT_WFDB_DIR = Path(os.getenv("CARDIAC_AUDIT_WFDB_DIR", str(PROJECT_ROOT / "ECG_WFDB_SAMPLE")))
DATASET_AUDIT_PATH = PROJECT_ROOT / "DATASET_AUDIT.md"
PROBE_CSV_PATH = PROJECT_ROOT / "MODEL_PROBE_AUDIT.csv"


@dataclass
class FeatureDatasetAudit:
    data_dir: str
    x_file_count: int
    y_file_count: int
    total_samples: int
    feature_count: int | None
    class_distribution: dict[str, int]
    nan_count: int
    inf_count: int
    note: str


@dataclass
class WfdbRecordAudit:
    record_id: str
    fs: float
    lead_count: int
    sample_count: int
    duration_seconds: float
    lead_names: list[str]


def audit_feature_dataset(data_dir: Path) -> FeatureDatasetAudit:
    x_files = sorted(data_dir.glob("batch_X_*.npy"))
    y_files = sorted(data_dir.glob("batch_y_*.npy"))
    total_samples = 0
    feature_count: int | None = None
    nan_count = 0
    inf_count = 0
    labels: list[np.ndarray] = []

    for x_path in x_files:
        arr = np.load(x_path, mmap_mode="r")
        if arr.ndim >= 2 and feature_count is None:
            feature_count = int(arr.shape[1])
        total_samples += int(arr.shape[0]) if arr.ndim >= 1 else 0
        nan_count += int(np.isnan(arr).sum())
        inf_count += int(np.isinf(arr).sum())

    for y_path in y_files:
        labels.append(np.asarray(np.load(y_path), dtype=np.int64).reshape(-1))

    y_all = np.concatenate(labels) if labels else np.asarray([], dtype=np.int64)
    class_distribution = {str(k): int(v) for k, v in sorted(Counter(y_all.tolist()).items())}
    note = (
        "Patient identifiers are not available in this feature-only directory, so patient-level leakage "
        "cannot be verified from these files alone."
    )
    return FeatureDatasetAudit(
        data_dir=str(data_dir),
        x_file_count=len(x_files),
        y_file_count=len(y_files),
        total_samples=total_samples,
        feature_count=feature_count,
        class_distribution=class_distribution,
        nan_count=nan_count,
        inf_count=inf_count,
        note=note,
    )


def audit_wfdb_directory(records_dir: Path, limit: int = 20) -> list[WfdbRecordAudit]:
    audits: list[WfdbRecordAudit] = []
    for hea_path in sorted(records_dir.glob("*.hea"))[:limit]:
        record_path = hea_path.with_suffix("")
        record = wfdb.rdrecord(str(record_path))
        signal = np.asarray(record.p_signal, dtype=np.float32)
        sample_count = int(signal.shape[0]) if signal.ndim == 2 else 0
        lead_count = int(signal.shape[1]) if signal.ndim == 2 else 0
        fs = float(record.fs)
        duration = float(sample_count / fs) if fs > 0 else 0.0
        audits.append(
            WfdbRecordAudit(
                record_id=record_path.name,
                fs=fs,
                lead_count=lead_count,
                sample_count=sample_count,
                duration_seconds=duration,
                lead_names=list(getattr(record, "sig_name", []) or []),
            )
        )
    return audits


def probe_records(records_dir: Path, limit: int = 12) -> list[dict[str, Any]]:
    try:
        import main as backend_main
    except Exception as exc:  # pragma: no cover - environment-specific diagnostic path
        return [
            {
                "recordingId": "probe_unavailable",
                "inputFile": str(records_dir),
                "probeError": f"Backend import unavailable for probe execution: {exc}",
            }
        ]

    rows: list[dict[str, Any]] = []
    for hea_path in sorted(records_dir.glob("*.hea"))[:limit]:
        record_path = hea_path.with_suffix("")
        try:
            row = backend_main._probe_analysis_from_record(record_path)
            rows.append(asdict(row))
        except Exception as exc:  # pragma: no cover - diagnostic path
            rows.append(
                {
                    "recordingId": record_path.name,
                    "inputFile": str(record_path),
                    "probeError": str(exc),
                }
            )
    return rows


def write_probe_csv(rows: list[dict[str, Any]], target: Path) -> None:
    if not rows:
        return
    fieldnames: list[str] = []
    for row in rows:
        for key in row.keys():
            if key not in fieldnames:
                fieldnames.append(key)
    with target.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def write_dataset_audit(
    feature_audit: FeatureDatasetAudit,
    wfdb_audits: list[WfdbRecordAudit],
    probe_rows: list[dict[str, Any]],
    target: Path,
) -> None:
    lines: list[str] = []
    lines.append("# DATASET AUDIT")
    lines.append("")
    lines.append("Generated on August 12, 2026.")
    lines.append("")
    lines.append("## Feature Dataset")
    lines.append(f"- Data dir: `{feature_audit.data_dir}`")
    lines.append(f"- X files: `{feature_audit.x_file_count}`")
    lines.append(f"- y files: `{feature_audit.y_file_count}`")
    lines.append(f"- Total samples: `{feature_audit.total_samples}`")
    lines.append(f"- Feature count: `{feature_audit.feature_count}`")
    lines.append(f"- Class distribution: `{json.dumps(feature_audit.class_distribution)}`")
    lines.append(f"- NaN count: `{feature_audit.nan_count}`")
    lines.append(f"- Inf count: `{feature_audit.inf_count}`")
    lines.append(f"- Note: {feature_audit.note}")
    lines.append("")
    lines.append("## WFDB Sample Records")
    if not wfdb_audits:
        lines.append("- No WFDB records were audited.")
    else:
        fs_values = sorted({round(item.fs, 4) for item in wfdb_audits})
        lead_counts = sorted({item.lead_count for item in wfdb_audits})
        durations = [item.duration_seconds for item in wfdb_audits]
        lines.append(f"- Records audited: `{len(wfdb_audits)}`")
        lines.append(f"- Sampling rates seen: `{fs_values}`")
        lines.append(f"- Lead counts seen: `{lead_counts}`")
        lines.append(
            f"- Duration range (seconds): `{min(durations):.2f}` to `{max(durations):.2f}`"
        )
    lines.append("")
    lines.append("## Model Probe")
    if not probe_rows:
        lines.append("- Probe not executed.")
    else:
        errors = sum(1 for row in probe_rows if row.get("probeError"))
        raw_values = [
            float(row["rawProbability"])
            for row in probe_rows
            if row.get("rawProbability") not in (None, "")
        ]
        calibrated_values = [
            float(row["calibratedProbability"])
            for row in probe_rows
            if row.get("calibratedProbability") not in (None, "")
        ]
        lines.append(f"- Probe rows: `{len(probe_rows)}`")
        lines.append(f"- Probe errors: `{errors}`")
        if raw_values:
            lines.append(
                f"- Raw probability range: `{min(raw_values):.4f}` to `{max(raw_values):.4f}`"
            )
        if calibrated_values:
            lines.append(
                f"- Calibrated probability range: `{min(calibrated_values):.4f}` to `{max(calibrated_values):.4f}`"
            )
        lines.append(f"- Detailed CSV: `{PROBE_CSV_PATH.name}`")
    target.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    feature_dir = DEFAULT_FEATURE_DATA_DIR
    wfdb_dir = DEFAULT_WFDB_DIR
    feature_audit = audit_feature_dataset(feature_dir)
    wfdb_audits = audit_wfdb_directory(wfdb_dir, limit=20) if wfdb_dir.is_dir() else []
    probe_rows = probe_records(wfdb_dir, limit=12) if wfdb_dir.is_dir() else []
    write_probe_csv(probe_rows, PROBE_CSV_PATH)
    write_dataset_audit(feature_audit, wfdb_audits, probe_rows, DATASET_AUDIT_PATH)
    print(json.dumps({
        "datasetAudit": str(DATASET_AUDIT_PATH),
        "probeCsv": str(PROBE_CSV_PATH),
        "wfdbRecordsAudited": len(wfdb_audits),
        "probeRows": len(probe_rows),
    }, indent=2))


if __name__ == "__main__":
    main()
