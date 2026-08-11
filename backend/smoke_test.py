from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path

from fastapi.testclient import TestClient

from main import app


SAMPLE_RECORD_DIR = Path(r"D:\DATA\100")
SAMPLE_HEA = SAMPLE_RECORD_DIR / "00001_lr.hea"
SAMPLE_DAT = SAMPLE_RECORD_DIR / "00001_lr.dat"


def _require_sample_files() -> None:
    missing = [str(path) for path in (SAMPLE_HEA, SAMPLE_DAT) if not path.is_file()]
    if missing:
        raise FileNotFoundError(f"Missing sample ECG files: {', '.join(missing)}")


def run_smoke_test() -> dict:
    _require_sample_files()
    stamp = datetime.now().strftime("%Y%m%d%H%M%S")
    mobile = f"010{stamp[-8:]}"
    email = f"doctor_{stamp}@example.com"

    with TestClient(app) as client:
        register = client.post(
            "/auth/register",
            json={
                "email": email,
                "mobile": mobile,
                "password": "Pass1234!",
                "role": "doctor",
                "name": "Smoke Doctor",
                "specialty": "Cardiology",
            },
        )
        register.raise_for_status()
        register_data = register.json()

        headers = {"Authorization": f"Bearer {register_data['token']}"}

        patient = client.post(
            "/patients",
            headers=headers,
            json={
                "name": "Smoke Patient",
                "age": 57,
                "gender": "Male",
                "phone": "01000000000",
                "notes": "backend smoke test",
            },
        )
        patient.raise_for_status()
        patient_data = patient.json()

        with SAMPLE_HEA.open("rb") as hea_handle, SAMPLE_DAT.open("rb") as dat_handle:
            analysis = client.post(
                f"/analyze_files?patientId={patient_data['id']}",
                headers=headers,
                files=[
                    ("files", (SAMPLE_HEA.name, hea_handle, "text/plain")),
                    ("files", (SAMPLE_DAT.name, dat_handle, "application/octet-stream")),
                ],
            )
        analysis.raise_for_status()
        analysis_data = analysis.json()

        history = client.get(f"/patients/{patient_data['id']}/history", headers=headers)
        history.raise_for_status()
        history_data = history.json()

        report = client.post(
            "/reports/generate",
            headers=headers,
            json={"analysisId": analysis_data["analysisId"]},
        )
        report.raise_for_status()
        report_data = report.json()

        patient_report = client.get(
            f"/reports/patient/{patient_data['id']}",
            headers=headers,
        )
        patient_report.raise_for_status()
        patient_report_data = patient_report.json()

        download = client.get(
            f"/reports/{report_data['reportId']}/download",
            headers=headers,
        )
        download.raise_for_status()

        health = client.get("/health")
        health.raise_for_status()

    return {
        "auth": {
            "userId": register_data["userId"],
            "role": register_data["role"],
        },
        "patient": {
            "id": patient_data["id"],
            "name": patient_data["name"],
        },
        "analysis": {
            "analysisId": analysis_data["analysisId"],
            "riskLevel": analysis_data["riskLevel"],
            "modelVersion": analysis_data["modelVersion"],
            "threshold": analysis_data["threshold"],
            "bpm": analysis_data["bpm"],
        },
        "historyCount": len(history_data),
        "report": {
            "reportId": report_data["reportId"],
            "filePath": report_data["filePath"],
        },
        "patientReport": {
            "reportId": patient_report_data["reportId"],
            "trendPoints": len(patient_report_data.get("labels", [])),
        },
        "download": {
            "contentType": download.headers.get("content-type"),
            "bytes": len(download.content),
        },
        "health": health.json(),
    }


if __name__ == "__main__":
    print(json.dumps(run_smoke_test(), indent=2))
