from __future__ import annotations

import io
import json
import os
import sqlite3
import sys
import tempfile
import uuid
import hashlib
import zipfile
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import cv2
import joblib
import numpy as np
import wfdb
import ecg_pipeline
from fastapi import Depends, FastAPI, File, Header, HTTPException, Request, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from PIL import Image
from pydantic import BaseModel, Field
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from scipy.fft import fft
from scipy.io import wavfile
from scipy.signal import butter, find_peaks, lfilter
from scipy.stats import kurtosis, skew


BASE_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = BASE_DIR.parent
DEPLOY_DATA_DIR = Path(os.getenv("CARDIAC_DATA_DIR", BASE_DIR))
DB_PATH = Path(os.getenv("CARDIAC_DB_PATH", str(DEPLOY_DATA_DIR / "app.db")))
REPORTS_DIR = Path(
    os.getenv("CARDIAC_REPORTS_DIR", str(DEPLOY_DATA_DIR / "generated_reports"))
)
WFDB_EXPORTS_DIR = Path(
    os.getenv("CARDIAC_WFDB_EXPORTS_DIR", str(DEPLOY_DATA_DIR / "generated_wfdb"))
)
MASTER_REPORT_TEMPLATE = Path(
    os.getenv("CARDIAC_MASTER_REPORT_TEMPLATE", str(PROJECT_ROOT / "00001_lr_approved.pdf"))
)
WEB_BUILD_DIR = Path(os.getenv("CARDIAC_WEB_BUILD_DIR", str(PROJECT_ROOT / "build" / "web")))
MODEL_SEARCH_DIRS = [
    os.getenv("KIMO_ECG_MODEL_DIR"),
    r"D:\DATA\ECG_MODEL_V15_FINAL",
    r"D:\DATA\KIMO_ECG_ULTRA_V14_PLUS",
    r"D:\DATA\KIMO_ECG_ULTRA_V14_PRO",
]
ALLOWED_IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".bmp", ".webp"}
ALLOWED_SIGNAL_EXTENSIONS = {".hea", ".dat", ".csv", ".wav"}
MAX_UPLOAD_BYTES = 20 * 1024 * 1024


def _allowed_origins() -> List[str]:
    raw = os.getenv("CARDIAC_ALLOWED_ORIGINS", "*").strip()
    if not raw or raw == "*":
        return ["*"]
    return [item.strip() for item in raw.split(",") if item.strip()]


app = FastAPI(title="Cardiac Pre-Ischemia API", version="1.2.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=_allowed_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class AuthIn(BaseModel):
    email: Optional[str] = None
    mobile: Optional[str] = None
    password: str
    role: str = "doctor"
    name: Optional[str] = None
    specialty: Optional[str] = None


class AuthOut(BaseModel):
    token: str
    userId: int
    role: str
    name: Optional[str] = None
    mobile: Optional[str] = None
    specialty: Optional[str] = None


class ForgotPasswordIn(BaseModel):
    email: Optional[str] = None
    mobile: Optional[str] = None


class ForgotPasswordOut(BaseModel):
    requestId: str
    status: str
    message: str


class PatientIn(BaseModel):
    name: str
    age: Optional[int] = None
    gender: Optional[str] = None
    phone: Optional[str] = None
    notes: Optional[str] = None


class PatientOut(PatientIn):
    id: int
    userId: Optional[int] = None
    createdByUserId: Optional[int] = None
    createdAt: str


class EmergencyIn(BaseModel):
    patientName: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class EmergencyOut(BaseModel):
    id: int
    patientName: str
    latitude: Optional[float]
    longitude: Optional[float]
    createdAt: str


class MessageIn(BaseModel):
    patientId: int
    text: str
    senderRole: str
    senderName: str


class MessageOut(MessageIn):
    id: int
    createdAt: str


class AppointmentIn(BaseModel):
    patientId: int
    doctorName: str
    when: str
    status: str = "Pending"
    notes: Optional[str] = None


class AppointmentOut(AppointmentIn):
    id: int
    createdAt: str


class StatsOut(BaseModel):
    patients: int
    emergencies: int
    messages: int


class MeasurementOut(BaseModel):
    name: str
    value: Optional[float]
    unit: Optional[str]
    source: str


class AnalysisResponse(BaseModel):
    analysisId: str
    recordingId: Optional[str] = None
    patientId: Optional[int] = None
    status: str
    inputType: str
    classification: str
    riskLevel: str
    region: str
    confidence: float
    modelScore: float
    bpm: int
    signalQuality: Optional[float] = None
    signalQualityLabel: Optional[str] = None
    activeCoils: List[str]
    recommendations: List[str]
    findings: List[str]
    explainability: Dict[str, Any] = Field(default_factory=dict)
    measurements: Dict[str, MeasurementOut]
    graphData: Dict[str, Any] = Field(default_factory=dict)
    modelVersion: str
    pipelineVersion: str
    featureVersion: str
    featureCount: int
    threshold: float
    createdAt: str


class AnalysisStatusOut(BaseModel):
    analysisId: str
    status: str
    createdAt: str
    modelVersion: str
    pipelineVersion: str


class AnalysisHistoryItem(BaseModel):
    analysisId: str
    patientId: Optional[int]
    createdAt: str
    inputType: str
    riskLevel: str
    classification: str
    modelScore: float
    bpm: int
    signalQuality: Optional[float]
    modelVersion: str


class TrendPoint(BaseModel):
    analysisId: str
    createdAt: str
    bpm: int
    riskLevel: str
    signalQuality: Optional[float]
    modelScore: float


class PatientTrendOut(BaseModel):
    patientId: int
    totalAnalyses: int
    avgBpm: Optional[float]
    avgSignalQuality: Optional[float]
    trend: List[TrendPoint]


class MonitoringStartIn(BaseModel):
    patientId: int
    mode: str = "demo"
    notes: Optional[str] = None


class MonitoringStopIn(BaseModel):
    sessionId: str
    notes: Optional[str] = None


class MonitoringSessionOut(BaseModel):
    sessionId: str
    patientId: int
    mode: str
    status: str
    notes: Optional[str] = None
    startedAt: str
    stoppedAt: Optional[str] = None


class GenerateReportIn(BaseModel):
    analysisId: Optional[str] = None
    patientId: Optional[int] = None


class ReportOut(BaseModel):
    reportId: str
    analysisId: Optional[str] = None
    patientId: Optional[int] = None
    filePath: str
    createdAt: str
    bpm: List[int] = Field(default_factory=list)
    labels: List[str] = Field(default_factory=list)
    riskLevels: List[str] = Field(default_factory=list)


class ModelProbeRow(BaseModel):
    recordingId: str
    inputFile: Optional[str] = None
    signalLength: Optional[int] = None
    samplingRate: Optional[float] = None
    channelUsed: Optional[str] = None
    signalMin: Optional[float] = None
    signalMax: Optional[float] = None
    signalMean: Optional[float] = None
    signalStd: Optional[float] = None
    validSamples: Optional[int] = None
    featureCount: Optional[int] = None
    featureVectorHash: Optional[str] = None
    featureMin: Optional[float] = None
    featureMax: Optional[float] = None
    featureMean: Optional[float] = None
    featureStd: Optional[float] = None
    heartRate: Optional[float] = None
    rrIntervalMs: Optional[float] = None
    qrsDurationMs: Optional[float] = None
    qtcMs: Optional[float] = None
    stDeviation: Optional[float] = None
    rawProbability: Optional[float] = None
    calibratedProbability: float
    threshold: float
    predictedClass: str
    inferenceMode: str
    modelVersion: str


class ModelProbeOut(BaseModel):
    total: int
    uniqueFeatureVectors: int = 0
    uniqueRawProbabilities: int = 0
    uniqueCalibratedProbabilities: int = 0
    probabilityMean: Optional[float] = None
    probabilityStd: Optional[float] = None
    probabilityMin: Optional[float] = None
    probabilityMax: Optional[float] = None
    pctAbove099: Optional[float] = None
    pctBelow001: Optional[float] = None
    pctIdenticalPredictions: Optional[float] = None
    rows: List[ModelProbeRow]


class HealthOut(BaseModel):
    backend: str
    database: str
    model: str
    modelVersion: Optional[str] = None
    pipelineVersion: Optional[str] = None
    threshold: Optional[float] = None
    time: str


class WFDBConversionOut(BaseModel):
    conversionId: str
    recordId: str
    heaFileName: str
    datFileName: str
    zipFileName: str
    outputDir: str
    downloadUrl: str
    createdAt: str


class ModelBundle:
    def __init__(
        self,
        model: Any,
        imputer: Any,
        qt: Any,
        threshold: float,
        model_dir: Path,
    ) -> None:
        self.model = model
        self.imputer = imputer
        self.qt = qt
        self.threshold = threshold
        self.model_dir = model_dir
        self.metadata = _load_model_metadata(model_dir, threshold)
        if isinstance(model, dict):
            self.stack_model = model.get("stack_model")
            self.platt_scaler = model.get("platt_scaler")
        else:
            self.stack_model = model
            self.platt_scaler = None

    @staticmethod
    def load(model_dir: str) -> "ModelBundle":
        model_dir_path = Path(model_dir)
        if (model_dir_path / "model_metadata.json").is_file():
            loaded = ecg_pipeline.load_bundle(model_dir_path)
            return ModelBundle(
                model=loaded.model,
                imputer=loaded.imputer,
                qt=loaded.scaler,
                threshold=loaded.threshold,
                model_dir=model_dir_path,
            )
        paths = _model_paths(model_dir_path)
        model = joblib.load(paths["model"])
        imputer = joblib.load(paths["imputer"])
        qt = joblib.load(paths["qt"])
        threshold = float(np.load(paths["threshold"]))
        return ModelBundle(
            model=model,
            imputer=imputer,
            qt=qt,
            threshold=threshold,
            model_dir=model_dir_path,
        )

    def predict_probability(self, x_scaled: np.ndarray) -> float:
        return self.predict_details(x_scaled)["calibrated_probability"]

    def predict_details(self, x_scaled: np.ndarray) -> Dict[str, Any]:
        if self.stack_model is None:
            raise ValueError("Model bundle does not contain a stack_model")
        raw_prob = float(self.stack_model.predict_proba(x_scaled)[0, 1])
        if self.platt_scaler is None:
            return {
                "raw_probability": raw_prob,
                "calibrated_probability": raw_prob,
                "calibration_applied": False,
            }
        clipped = np.clip(np.asarray([raw_prob], dtype=np.float64), 1e-6, 1.0 - 1e-6)
        logits = np.log(clipped / (1.0 - clipped)).reshape(-1, 1)
        calibrated = float(self.platt_scaler.predict_proba(logits)[0, 1])
        return {
            "raw_probability": raw_prob,
            "calibrated_probability": calibrated,
            "calibration_applied": True,
        }


_model_bundle: Optional[ModelBundle] = None


def _db_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def _column_exists(conn: sqlite3.Connection, table: str, column: str) -> bool:
    rows = conn.execute(f"PRAGMA table_info({table})").fetchall()
    return any(row[1] == column for row in rows)


def _ensure_column(
    conn: sqlite3.Connection, table: str, column: str, definition: str
) -> None:
    if not _column_exists(conn, table, column):
        conn.execute(f"ALTER TABLE {table} ADD COLUMN {column} {definition}")


def _model_paths(model_dir: Path) -> Dict[str, Path]:
    if (model_dir / "model_metadata.json").is_file():
        paths = ecg_pipeline.model_paths(model_dir)
        return {
            "model": paths["model"],
            "imputer": paths["imputer"],
            "qt": paths["scaler"],
            "threshold": paths["threshold"],
        }
    candidates = [
        {
            "model": model_dir / "model_v14_plus_calibrated.pkl",
            "imputer": model_dir / "imputer_v14_plus.pkl",
            "qt": model_dir / "qt_v14_plus.pkl",
            "threshold": model_dir / "threshold_v14_plus.npy",
        },
        {
            "model": model_dir / "model_v14_pro.pkl",
            "imputer": model_dir / "imputer_v14.pkl",
            "qt": model_dir / "qt_v14_pro.pkl",
            "threshold": model_dir / "threshold_v14_pro.npy",
        },
    ]
    for paths in candidates:
        if all(path.is_file() for path in paths.values()):
            return paths
    return candidates[0]


def _load_model_metadata(model_dir: Path, threshold: float) -> Dict[str, Any]:
    metadata_path = model_dir / "model_metadata.json"
    if metadata_path.is_file():
        try:
            metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
            return metadata
        except Exception:
            pass
    summary_path = model_dir / "training_summary_v14_plus.json"
    model_version = model_dir.name
    if summary_path.is_file():
        try:
            with summary_path.open("r", encoding="utf-8") as handle:
                summary = json.load(handle)
            model_version = summary.get("model_name", model_dir.name)
            threshold = float(summary.get("metrics", {}).get("threshold", threshold))
        except Exception:
            pass
    return {
        "model_version": model_version,
        "pipeline_version": "wfdb_image_pipeline_v1",
        "feature_version": "300_feature_vector_v1",
        "feature_count": 300,
        "threshold": threshold,
    }


def _resolve_model_dir() -> Optional[Path]:
    for candidate in MODEL_SEARCH_DIRS:
        if not candidate:
            continue
        model_dir = Path(candidate)
        if not model_dir.is_dir():
            continue
        paths = _model_paths(model_dir)
        if all(path.is_file() for path in paths.values()):
            return model_dir
    return None


def _ensure_model_files(model_dir: Path) -> None:
    paths = _model_paths(model_dir)
    missing = [name for name, path in paths.items() if not path.is_file()]
    if missing:
        raise HTTPException(
            status_code=503,
            detail=f"Model files missing in {model_dir}: {', '.join(missing)}",
        )


def _ensure_runtime_dirs() -> None:
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    WFDB_EXPORTS_DIR.mkdir(parents=True, exist_ok=True)


def _init_db() -> None:
    with _db_connection() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                email TEXT UNIQUE,
                mobile TEXT UNIQUE,
                password_hash TEXT NOT NULL,
                role TEXT NOT NULL,
                name TEXT,
                specialty TEXT,
                created_at TEXT NOT NULL
            );
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS sessions (
                token TEXT PRIMARY KEY,
                user_id INTEGER NOT NULL,
                created_at TEXT NOT NULL
            );
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS password_reset_requests (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                request_uid TEXT UNIQUE NOT NULL,
                user_id INTEGER,
                email TEXT,
                mobile TEXT,
                status TEXT NOT NULL,
                created_at TEXT NOT NULL
            );
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS patients (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER,
                created_by_user_id INTEGER,
                name TEXT NOT NULL,
                age INTEGER,
                gender TEXT,
                phone TEXT,
                notes TEXT,
                created_at TEXT NOT NULL
            );
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS emergencies (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                patient_name TEXT NOT NULL,
                latitude REAL,
                longitude REAL,
                created_at TEXT NOT NULL
            );
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                patient_id INTEGER NOT NULL,
                sender_role TEXT NOT NULL,
                sender_name TEXT NOT NULL,
                text TEXT NOT NULL,
                created_at TEXT NOT NULL
            );
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS appointments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                patient_id INTEGER NOT NULL,
                doctor_name TEXT NOT NULL,
                when_at TEXT NOT NULL,
                status TEXT NOT NULL,
                notes TEXT,
                created_at TEXT NOT NULL
            );
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS analyses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                analysis_uid TEXT UNIQUE NOT NULL,
                patient_id INTEGER,
                input_type TEXT NOT NULL,
                source_filename TEXT,
                status TEXT NOT NULL,
                risk_level TEXT NOT NULL,
                classification TEXT NOT NULL,
                region TEXT NOT NULL,
                confidence REAL NOT NULL,
                model_score REAL NOT NULL,
                bpm INTEGER NOT NULL,
                signal_quality REAL,
                signal_quality_label TEXT,
                active_coils_json TEXT NOT NULL,
                recommendations_json TEXT NOT NULL,
                findings_json TEXT NOT NULL,
                explainability_json TEXT NOT NULL,
                measurements_json TEXT NOT NULL,
                graph_data_json TEXT NOT NULL,
                model_version TEXT NOT NULL,
                pipeline_version TEXT NOT NULL,
                feature_version TEXT NOT NULL,
                feature_count INTEGER NOT NULL,
                threshold REAL NOT NULL,
                created_at TEXT NOT NULL
            );
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS reports (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                report_uid TEXT UNIQUE NOT NULL,
                analysis_uid TEXT,
                patient_id INTEGER,
                file_path TEXT NOT NULL,
                created_at TEXT NOT NULL
            );
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS monitoring_sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_uid TEXT UNIQUE NOT NULL,
                patient_id INTEGER NOT NULL,
                mode TEXT NOT NULL,
                status TEXT NOT NULL,
                notes TEXT,
                started_at TEXT NOT NULL,
                stopped_at TEXT
            );
            """
        )

        _ensure_column(conn, "users", "mobile", "TEXT")
        _ensure_column(conn, "users", "specialty", "TEXT")
        _ensure_column(conn, "patients", "user_id", "INTEGER")
        _ensure_column(conn, "patients", "created_by_user_id", "INTEGER")
        conn.commit()


def _hash_password(raw: str) -> str:
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def _create_token() -> str:
    return uuid.uuid4().hex


def _identity_email(mobile: Optional[str], email: Optional[str]) -> Optional[str]:
    if email:
        return email.strip().lower()
    if mobile:
        cleaned = "".join(ch for ch in mobile if ch.isdigit() or ch == "+")
        if cleaned:
            return f"{cleaned.replace('+', 'plus')}@cardiac-prestroke.app"
    return None


def _normalize_mobile(mobile: Optional[str]) -> Optional[str]:
    if not mobile:
        return None
    cleaned = "".join(ch for ch in mobile if ch.isdigit() or ch == "+")
    return cleaned or None


def _get_user_by_token(auth_header: Optional[str]) -> Dict[str, Any]:
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Authentication required")
    token = auth_header.replace("Bearer ", "").strip()
    with _db_connection() as conn:
        row = conn.execute(
            """
            SELECT u.id, u.email, u.mobile, u.role, u.name, u.specialty
            FROM sessions s
            JOIN users u ON s.user_id = u.id
            WHERE s.token = ?
            """,
            (token,),
        ).fetchone()
    if row is None:
        raise HTTPException(status_code=401, detail="Invalid or expired session")
    return dict(row)


def _current_user(authorization: Optional[str] = Header(default=None)) -> Dict[str, Any]:
    return _get_user_by_token(authorization)


def _current_user_optional(
    authorization: Optional[str] = Header(default=None),
) -> Optional[Dict[str, Any]]:
    if not authorization:
        return None
    try:
        return _get_user_by_token(authorization)
    except HTTPException:
        return None


def _public_base_url(request: Optional[Request] = None) -> str:
    configured = os.getenv("CARDIAC_PUBLIC_BASE_URL", "").strip().rstrip("/")
    if configured:
        return configured
    if request is not None:
        return str(request.base_url).rstrip("/")
    return "http://127.0.0.1:8001"


def _ensure_role(user: Dict[str, Any], allowed_roles: List[str]) -> None:
    if user["role"] not in allowed_roles:
        raise HTTPException(status_code=403, detail="Not authorized for this action")


def _ensure_model() -> ModelBundle:
    global _model_bundle
    if _model_bundle is None:
        model_dir = _resolve_model_dir()
        if model_dir is None:
            raise HTTPException(
                status_code=503,
                detail=(
                    "Model not available. Set KIMO_ECG_MODEL_DIR or ensure "
                    "the V14_PLUS / V14_PRO model directories exist with valid files."
                ),
            )
        _ensure_model_files(model_dir)
        try:
            _model_bundle = ModelBundle.load(str(model_dir))
        except Exception as exc:
            raise HTTPException(status_code=503, detail=f"Model load failed: {exc}")
    return _model_bundle


def _fallback_model_metadata() -> Dict[str, Any]:
    return {
        "model_version": "heuristic_ecg_fallback_v1",
        "pipeline_version": "signal_only_fallback_v1",
        "feature_version": "fallback_rules_v1",
        "feature_count": 0,
        "threshold": 0.52,
    }


def _heuristic_model_score(
    *,
    bpm: int,
    signal_quality: float,
    measurements: Dict[str, "MeasurementOut"],
    signal_signature: Optional[Dict[str, float]] = None,
) -> float:
    signature = signal_signature or {}
    score = 0.12
    score += min(abs(float(bpm) - 72.0) / 65.0, 1.0) * 0.16

    qrs = measurements.get("qrs_duration")
    if qrs and qrs.value is not None:
        score += min(max((float(qrs.value) - 92.0) / 55.0, 0.0), 1.0) * 0.18

    qtc = measurements.get("qtc")
    if qtc and qtc.value is not None:
        score += min(max((float(qtc.value) - 415.0) / 95.0, 0.0), 1.0) * 0.14

    st_dev = measurements.get("st_deviation")
    if st_dev and st_dev.value is not None:
        score += min(abs(float(st_dev.value)) / 0.35, 1.0) * 0.20

    sdnn = measurements.get("sdnn")
    if sdnn and sdnn.value is not None:
        score += min(max((float(sdnn.value) - 40.0) / 120.0, 0.0), 1.0) * 0.08

    rmssd = measurements.get("rmssd")
    if rmssd and rmssd.value is not None:
        score += min(max((float(rmssd.value) - 25.0) / 95.0, 0.0), 1.0) * 0.08

    score += min(max(float(signature.get("lead_strength_cv", 0.0)) / 0.55, 0.0), 1.0) * 0.08
    score += min(max(float(signature.get("lead_diversity_index", 0.0)) / 0.65, 0.0), 1.0) * 0.12
    score += min(max(float(signature.get("rr_irregularity_index", 0.0)) / 0.30, 0.0), 1.0) * 0.10
    score += min(max(float(signature.get("spectral_entropy", 0.0)) - 0.55, 0.0) / 0.35, 1.0) * 0.07
    score += min(max(abs(float(signature.get("dominant_region_margin", 0.0))) / 0.25, 0.0), 1.0) * 0.03
    score += min(max(1.0 - float(signal_quality), 0.0), 1.0) * 0.07

    return float(np.clip(score, 0.05, 0.95))


def _image_signal_screening_score(
    *,
    bpm: int,
    signal_quality: float,
    measurements: Dict[str, "MeasurementOut"],
    signal_signature: Optional[Dict[str, float]] = None,
) -> float:
    signature = signal_signature or {}
    score = 0.10

    rr = measurements.get("rr_interval")
    if rr and rr.value is not None:
        score += min(abs(float(rr.value) - 800.0) / 550.0, 1.0) * 0.08

    score += min(abs(float(bpm) - 72.0) / 70.0, 1.0) * 0.16

    pr = measurements.get("pr_interval")
    if pr and pr.value is not None:
        pr_val = float(pr.value)
        if pr_val < 110 or pr_val > 220:
            score += min(abs(pr_val - 165.0) / 120.0, 1.0) * 0.06

    qrs = measurements.get("qrs_duration")
    if qrs and qrs.value is not None:
        qrs_val = float(qrs.value)
        score += min(abs(qrs_val - 95.0) / 70.0, 1.0) * 0.17

    qt = measurements.get("qt_interval")
    if qt and qt.value is not None:
        score += min(abs(float(qt.value) - 380.0) / 170.0, 1.0) * 0.06

    qtc = measurements.get("qtc")
    if qtc and qtc.value is not None:
        qtc_val = float(qtc.value)
        score += min(abs(qtc_val - 420.0) / 140.0, 1.0) * 0.15

    st_dev = measurements.get("st_deviation")
    if st_dev and st_dev.value is not None:
        score += min(abs(float(st_dev.value)) / 0.30, 1.0) * 0.18

    sdnn = measurements.get("sdnn")
    if sdnn and sdnn.value is not None:
        score += min(float(sdnn.value) / 180.0, 1.0) * 0.06

    rmssd = measurements.get("rmssd")
    if rmssd and rmssd.value is not None:
        score += min(float(rmssd.value) / 220.0, 1.0) * 0.05

    pnn50 = measurements.get("pnn50")
    if pnn50 and pnn50.value is not None:
        score += min(float(pnn50.value) / 100.0, 1.0) * 0.04

    score += min(max(float(signature.get("lead_strength_cv", 0.0)) / 0.60, 0.0), 1.0) * 0.07
    score += min(max(float(signature.get("raw_lead_strength_cv", 0.0)) / 0.70, 0.0), 1.0) * 0.08
    score += min(max(float(signature.get("lead_diversity_index", 0.0)) / 0.70, 0.0), 1.0) * 0.08
    score += min(max(float(signature.get("rr_irregularity_index", 0.0)) / 0.35, 0.0), 1.0) * 0.08
    score += min(max(float(signature.get("slope_energy", 0.0)) / 0.35, 0.0), 1.0) * 0.05
    score += min(max(float(signature.get("zero_crossing_rate", 0.0)) / 0.20, 0.0), 1.0) * 0.04
    score += min(max(float(signature.get("spectral_entropy", 0.0)) - 0.50, 0.0) / 0.40, 1.0) * 0.05
    score += min(max(1.0 - float(signal_quality), 0.0), 1.0) * 0.06

    return float(np.clip(score, 0.03, 0.97))


def _signal_signature_metrics(
    raw_signal: np.ndarray,
    processed_signal: np.ndarray,
    fs: float,
    quality: Dict[str, Any],
    rr: Dict[str, Any],
) -> Dict[str, float]:
    raw = ecg_pipeline.ensure_lead_first(raw_signal)
    processed = ecg_pipeline.ensure_lead_first(processed_signal)
    usable = processed[: min(12, processed.shape[0])]

    lead_strength = np.asarray(
        [float(np.std(lead) + 0.35 * np.max(np.abs(lead))) for lead in usable],
        dtype=np.float32,
    )
    raw_usable = raw[: min(12, raw.shape[0])]
    raw_lead_strength = np.asarray(
        [float(np.std(lead) + 0.35 * np.max(np.abs(lead))) for lead in raw_usable],
        dtype=np.float32,
    )
    lead_strength_mean = float(np.mean(lead_strength)) if lead_strength.size else 0.0
    lead_strength_cv = (
        float(np.std(lead_strength) / (lead_strength_mean + 1e-6)) if lead_strength.size else 0.0
    )
    raw_strength_mean = float(np.mean(raw_lead_strength)) if raw_lead_strength.size else 0.0
    raw_strength_cv = (
        float(np.std(raw_lead_strength) / (raw_strength_mean + 1e-6)) if raw_lead_strength.size else 0.0
    )

    lead_diversity_index = 0.0
    if usable.shape[0] >= 2:
        corr = np.corrcoef(usable)
        corr = np.nan_to_num(corr, nan=0.0, posinf=0.0, neginf=0.0)
        upper = corr[np.triu_indices_from(corr, k=1)]
        if upper.size:
            lead_diversity_index = float(np.clip(1.0 - np.mean(np.abs(upper)), 0.0, 1.0))

    rep = ecg_pipeline.representative_lead(processed)
    zero_crossings = float(np.mean(np.diff(np.signbit(rep)).astype(np.float32))) if rep.size > 1 else 0.0
    slope_energy = float(np.mean(np.abs(np.diff(rep)))) if rep.size > 1 else 0.0
    fft_values = np.abs(fft(rep))
    half = np.asarray(fft_values[: max(len(fft_values) // 2, 1)], dtype=np.float64)
    if half.size > 1 and float(np.sum(half)) > 0:
        power = half / float(np.sum(half))
        spectral_entropy = float(
            -np.sum(power * np.log(power + 1e-12)) / np.log(max(len(power), 2))
        )
    else:
        spectral_entropy = 0.0

    rr_mean_ms = float(rr["rr_mean_ms"]) if rr.get("rr_mean_ms") is not None else 0.0
    rr_std_ms = float(rr["rr_std_ms"]) if rr.get("rr_std_ms") is not None else 0.0
    rr_irregularity_index = rr_std_ms / max(rr_mean_ms, 1.0) if rr_mean_ms > 0 else 0.0

    region_name = "Undetermined"
    dominant_region_margin = 0.0
    if usable.shape[0] >= 12:
        groups = {
            "Inferior": [1, 2, 5],
            "Septal": [6, 7],
            "Anterior": [8, 9],
            "Lateral": [0, 4, 10, 11],
        }
        region_scores = {
            name: float(np.mean([lead_strength[idx] for idx in indices if idx < len(lead_strength)]))
            for name, indices in groups.items()
        }
        ordered = sorted(region_scores.items(), key=lambda item: item[1], reverse=True)
        if ordered:
            region_name = ordered[0][0]
            top_score = float(ordered[0][1])
            second_score = float(ordered[1][1]) if len(ordered) > 1 else 0.0
            dominant_region_margin = top_score - second_score

    return {
        "lead_count": float(raw.shape[0]),
        "lead_strength_mean": round(lead_strength_mean, 4),
        "lead_strength_cv": round(float(lead_strength_cv), 4),
        "raw_lead_strength_mean": round(raw_strength_mean, 4),
        "raw_lead_strength_cv": round(float(raw_strength_cv), 4),
        "lead_diversity_index": round(float(lead_diversity_index), 4),
        "zero_crossing_rate": round(float(zero_crossings), 4),
        "slope_energy": round(float(slope_energy), 4),
        "spectral_entropy": round(float(spectral_entropy), 4),
        "rr_irregularity_index": round(float(rr_irregularity_index), 4),
        "baseline_wander_ratio": round(float(quality.get("baseline_wander_ratio", 0.0)), 4),
        "noise_ratio": round(float(quality.get("noise_ratio", 0.0)), 4),
        "clipping_ratio": round(float(quality.get("clipping_ratio", 0.0)), 4),
        "dominant_region_margin": round(float(dominant_region_margin), 4),
        "dominant_region_guess": region_name,
    }


def _butter_bandpass(lowcut: float, highcut: float, fs: float, order: int = 5):
    nyq = 0.5 * fs
    low = lowcut / nyq
    high = highcut / nyq
    return butter(order, [low, high], btype="band")


def _apply_bandpass_filter(
    data: np.ndarray, lowcut: float, highcut: float, fs: float, order: int = 5
) -> np.ndarray:
    b, a = _butter_bandpass(lowcut, highcut, fs, order=order)
    return lfilter(b, a, data, axis=1)


def _normalize_signal_array(signal: np.ndarray, fs: float) -> Tuple[np.ndarray, float]:
    signal = np.asarray(signal, dtype=np.float32)
    if signal.ndim == 1:
        signal = signal.reshape(1, -1)
    if signal.shape[0] > signal.shape[1]:
        signal = signal.T
    filtered = _apply_bandpass_filter(signal, 0.5, 40.0, fs, order=5)
    mean = np.mean(filtered, axis=1, keepdims=True)
    std = np.std(filtered, axis=1, keepdims=True)
    std[std == 0] = 1.0
    normalized = (filtered - mean) / std
    return normalized.astype(np.float32), float(fs)


def _preprocess_ecg(record_path: str, sampling_rate: Optional[float]) -> Tuple[np.ndarray, float]:
    raw_signal, fs, _ = ecg_pipeline.load_wfdb_record(record_path)
    fs = float(sampling_rate or fs)
    return ecg_pipeline.preprocess_signal(raw_signal, fs), fs


def _extract_300_features(signal: np.ndarray, fs: float) -> np.ndarray:
    features: List[float] = []
    for lead in signal:
        features.extend([np.mean(lead), np.std(lead), skew(lead), kurtosis(lead)])
        n = len(lead)
        yf = fft(lead)
        fft_amplitudes = np.abs(yf[0 : n // 2])
        fft_subset = fft_amplitudes[:20]
        if len(fft_subset) < 20:
            fft_subset = np.pad(fft_subset, (0, 20 - len(fft_subset)), "constant")
        features.extend(fft_subset)

    representative_lead = signal[1] if signal.shape[0] > 1 else signal[0]
    peaks, _ = find_peaks(representative_lead, distance=max(int(0.2 * fs), 1), prominence=0.5)
    features.append(len(peaks))

    if len(peaks) > 1:
        rr_intervals = np.diff(peaks) / fs
        diffs = np.diff(rr_intervals)
        pnn50 = (
            float(np.sum(np.abs(diffs) > 0.05) / max(len(diffs), 1)) * 100.0
            if len(diffs) > 0
            else 0.0
        )
        features.extend(
            [
                float(np.mean(rr_intervals)),
                float(np.std(rr_intervals)),
                float(np.sqrt(np.mean(diffs ** 2))) if len(diffs) > 0 else 0.0,
                pnn50,
            ]
        )
    else:
        features.extend([0.0, 0.0, 0.0, 0.0])

    if len(features) < 300:
        features.extend([0.0] * (300 - len(features)))
    return np.array(features[:300], dtype=np.float32)


def _compute_signal_quality(signal: np.ndarray) -> Tuple[float, str]:
    representative = signal[1] if signal.shape[0] > 1 else signal[0]
    std = float(np.std(representative))
    peak = float(np.max(np.abs(representative)))
    nan_ratio = float(np.mean(~np.isfinite(representative)))
    raw_score = 1.0 - min(nan_ratio * 2.0, 1.0)
    raw_score -= 0.25 if std < 0.2 else 0.0
    raw_score -= 0.15 if peak > 6.0 else 0.0
    score = max(0.0, min(raw_score, 1.0))
    if score >= 0.8:
        label = "high"
    elif score >= 0.55:
        label = "medium"
    else:
        label = "low"
    return round(score, 3), label


def _derive_measurements(signal: np.ndarray, fs: float) -> Tuple[Dict[str, MeasurementOut], Dict[str, Any]]:
    representative = ecg_pipeline.representative_lead(signal)
    peaks, _ = find_peaks(representative, distance=max(int(0.2 * fs), 1), prominence=0.5)
    rr_ms: List[float] = []
    bpm = 0
    if len(peaks) > 1:
        rr_intervals = np.diff(peaks) / fs
        rr_ms = [round(float(v * 1000.0), 2) for v in rr_intervals]
        bpm = int(round(60.0 / float(np.mean(rr_intervals))))
        diffs = np.diff(rr_intervals)
        sdnn = float(np.std(rr_intervals) * 1000.0)
        rmssd = float(np.sqrt(np.mean(diffs ** 2)) * 1000.0) if len(diffs) > 0 else 0.0
        pnn50 = (
            float(np.sum(np.abs(diffs) > 0.05) / max(len(diffs), 1)) * 100.0
            if len(diffs) > 0
            else 0.0
        )
    else:
        sdnn = 0.0
        rmssd = 0.0
        pnn50 = 0.0
        bpm = int(round(60.0 * fs / max(len(representative), 1)))

    measurements = {
        "heart_rate": MeasurementOut(name="heart_rate", value=float(bpm), unit="bpm", source="DETECTED"),
        "rr_interval": MeasurementOut(
            name="rr_interval",
            value=float(np.mean(rr_ms)) if rr_ms else None,
            unit="ms",
            source="DETECTED" if rr_ms else "UNAVAILABLE",
        ),
        "sdnn": MeasurementOut(
            name="sdnn",
            value=round(sdnn, 2) if rr_ms else None,
            unit="ms",
            source="MEASURED" if rr_ms else "UNAVAILABLE",
        ),
        "rmssd": MeasurementOut(
            name="rmssd",
            value=round(rmssd, 2) if rr_ms else None,
            unit="ms",
            source="MEASURED" if rr_ms else "UNAVAILABLE",
        ),
        "pnn50": MeasurementOut(
            name="pnn50",
            value=round(pnn50, 2) if rr_ms else None,
            unit="%",
            source="MEASURED" if rr_ms else "UNAVAILABLE",
        ),
        "pr_interval": MeasurementOut(name="pr_interval", value=None, unit="ms", source="UNAVAILABLE"),
        "qrs_duration": MeasurementOut(name="qrs_duration", value=None, unit="ms", source="UNAVAILABLE"),
        "qt_interval": MeasurementOut(name="qt_interval", value=None, unit="ms", source="UNAVAILABLE"),
        "qtc": MeasurementOut(name="qtc", value=None, unit="ms", source="UNAVAILABLE"),
        "st_deviation": MeasurementOut(name="st_deviation", value=None, unit="mV", source="UNAVAILABLE"),
    }
    graph_data = {
        "waveform": [round(float(v), 4) for v in representative[:1000]],
        "rPeaks": [int(v) for v in peaks[:100]],
        "rrIntervalsMs": rr_ms[:100],
    }
    return measurements, graph_data


def _top_signal_leads(signal: np.ndarray, limit: int = 4) -> List[np.ndarray]:
    lead_first = ecg_pipeline.ensure_lead_first(signal)
    ranking: List[Tuple[float, np.ndarray]] = []
    for lead in lead_first:
        strength = float(np.std(lead) + 0.35 * np.max(np.abs(lead)))
        ranking.append((strength, lead))
    ranking.sort(key=lambda item: item[0], reverse=True)
    return [lead for _, lead in ranking[: max(1, limit)]]


def _median_non_null(values: List[Optional[float]]) -> Optional[float]:
    filtered = [float(v) for v in values if v is not None and np.isfinite(float(v))]
    if not filtered:
        return None
    return float(np.median(np.asarray(filtered, dtype=np.float32)))


def _estimate_region_and_coils(signal: np.ndarray, risk: str) -> Tuple[str, List[str]]:
    if risk == "Low":
        return "Undetermined", []
    if signal.shape[0] < 12:
        return "Undetermined", []

    lead_strength = np.asarray(
        [
            float(np.std(lead) + 0.35 * np.max(np.abs(lead)))
            for lead in signal[:12]
        ],
        dtype=np.float32,
    )
    groups = {
        "Inferior": [1, 2, 5],
        "Septal": [6, 7],
        "Anterior": [8, 9],
        "Lateral": [0, 4, 10, 11],
    }
    group_scores = {
        name: float(np.mean([lead_strength[idx] for idx in indices if idx < len(lead_strength)]))
        for name, indices in groups.items()
    }
    ordered = sorted(group_scores.items(), key=lambda item: item[1], reverse=True)
    if not ordered:
        return "Undetermined", []
    top_region, top_score = ordered[0]
    second_score = ordered[1][1] if len(ordered) > 1 else 0.0
    if top_score <= 0.0 or (top_score - second_score) < 0.05:
        return "Undetermined", []
    coil_map = {
        "Anterior": ["C1", "C2"],
        "Lateral": ["C3", "C4"],
        "Inferior": ["C5", "C6"],
        "Septal": ["C7", "C8"],
    }
    return top_region, coil_map.get(top_region, [])


def _predict_ecg(signal: np.ndarray, fs: float) -> Tuple[float, int, np.ndarray]:
    model_bundle = _ensure_model()
    features = _extract_300_features(signal, fs).reshape(1, -1)
    x_imputed = model_bundle.imputer.transform(features)
    x_scaled = model_bundle.qt.transform(x_imputed)
    positive_prob = model_bundle.predict_probability(x_scaled)

    representative = signal[1] if signal.shape[0] > 1 else signal[0]
    peaks, _ = find_peaks(representative, distance=max(int(0.2 * fs), 1), prominence=0.5)
    if len(peaks) > 1:
        rr_intervals = np.diff(peaks) / fs
        bpm = int(round(60.0 / float(np.mean(rr_intervals))))
    else:
        bpm = int(round(60.0 * fs / max(len(representative), 1)))

    return positive_prob, bpm, features[0]


def _image_to_signal_simple(image_path: str, target_width: int = 1000) -> np.ndarray:
    img = Image.open(image_path).convert("L")
    w, h = img.size
    if w != target_width:
        new_h = max(1, int(h * (target_width / max(w, 1))))
        img = img.resize((target_width, new_h))
        w, h = img.size
    arr = np.asarray(img, dtype=np.float32)
    grad = np.abs(np.gradient(arr, axis=0))
    y_indices = np.argmax(grad, axis=0)
    if y_indices.size == 0:
        raise ValueError("No signal found in image")
    signal = (h - 1 - y_indices).astype(np.float32)
    signal -= np.mean(signal)
    std = np.std(signal)
    if std > 0:
        signal /= std
    return signal.reshape(1, -1).astype(np.float32)


def _normalize_lead_signal(signal: np.ndarray) -> np.ndarray:
    arr = np.asarray(signal, dtype=np.float32).copy()
    arr -= float(np.mean(arr))
    std = float(np.std(arr))
    if std > 1e-6:
        arr /= std
    return np.clip(arr, -6.0, 6.0).astype(np.float32)


def _center_lead_signal(signal: np.ndarray) -> np.ndarray:
    arr = np.asarray(signal, dtype=np.float32).copy()
    arr -= float(np.mean(arr))
    return arr.astype(np.float32)


def _resample_signal_1d(signal: np.ndarray, target_width: int) -> np.ndarray:
    if signal.size == target_width:
        return signal.astype(np.float32)
    src_x = np.linspace(0.0, 1.0, num=signal.size, dtype=np.float32)
    dst_x = np.linspace(0.0, 1.0, num=target_width, dtype=np.float32)
    return np.interp(dst_x, src_x, signal).astype(np.float32)


def _extract_trace_from_mask(mask: np.ndarray) -> Optional[np.ndarray]:
    if mask.ndim != 2 or mask.size == 0:
        return None
    h, w = mask.shape
    if h < 8 or w < 32:
        return None
    y_indices: List[int] = []
    last_y = h // 2
    for x in range(w):
        col = np.where(mask[:, x] > 0)[0]
        if col.size == 0:
            y_indices.append(last_y)
            continue
        y = int(np.median(col))
        y_indices.append(y)
        last_y = y
    signal = (h - 1 - np.asarray(y_indices, dtype=np.float32)).astype(np.float32)
    if float(np.std(signal)) < 1e-3:
        return None
    return signal


def _finalize_image_leads(leads: List[np.ndarray], target_width: int) -> Optional[np.ndarray]:
    if len(leads) < 6:
        return None

    prepared: List[np.ndarray] = []
    for lead in leads[:12]:
        lead_resampled = _resample_signal_1d(lead, target_width)
        lead_centered = _center_lead_signal(lead_resampled)
        if float(np.std(lead_centered)) < 0.02:
            continue
        prepared.append(lead_centered)

    if len(prepared) < 6:
        return None

    lead_stds = np.asarray([max(float(np.std(lead)), 1e-6) for lead in prepared], dtype=np.float32)
    global_scale = float(np.median(lead_stds)) if lead_stds.size else 1.0
    if global_scale <= 1e-6:
        global_scale = 1.0

    finalized = [np.clip(lead / global_scale, -8.0, 8.0).astype(np.float32) for lead in prepared]
    if len(finalized) > 12:
        finalized = finalized[:12]
    return np.vstack(finalized).astype(np.float32)


def _extract_standard_layout_multilead(
    trace: np.ndarray,
    row_boundaries: List[int],
    target_width: int,
) -> Optional[np.ndarray]:
    h, w = trace.shape
    usable_rows = len(row_boundaries) - 1
    if usable_rows < 3:
        return None

    row_spans = [(row_boundaries[idx], row_boundaries[idx + 1]) for idx in range(usable_rows)]
    row_spans = sorted(row_spans, key=lambda item: item[1] - item[0], reverse=True)[:4]
    row_spans = sorted(row_spans, key=lambda item: item[0])
    signal_rows = row_spans[:3]

    leads: List[np.ndarray] = []
    col_edges = np.linspace(0, w, 5, dtype=int)
    for top, bottom in signal_rows:
        top = max(top - 4, 0)
        bottom = min(bottom + 4, h)
        if bottom - top < 10:
            continue
        row_mask = trace[top:bottom, :]
        for col_idx in range(4):
            left = int(col_edges[col_idx])
            right = int(col_edges[col_idx + 1])
            if right - left < 24:
                continue
            cell_mask = row_mask[:, left:right]
            signal = _extract_trace_from_mask(cell_mask)
            if signal is None:
                continue
            leads.append(signal)

    return _finalize_image_leads(leads, target_width)


def _extract_multilead_from_image_mask(trace: np.ndarray, target_width: int) -> Optional[np.ndarray]:
    h, w = trace.shape
    row_energy = np.mean(trace > 0, axis=1).astype(np.float32)
    if float(np.max(row_energy, initial=0.0)) <= 0.0:
        return None

    kernel = np.ones(max(5, h // 80), dtype=np.float32)
    kernel /= float(kernel.size)
    smooth_energy = np.convolve(row_energy, kernel, mode="same")
    min_distance = max(h // 8, 18)
    prominence = max(float(np.std(smooth_energy)) * 0.35, 0.002)
    peaks, _ = find_peaks(smooth_energy, distance=min_distance, prominence=prominence)

    if peaks.size < 3:
        return None

    peak_order = sorted(peaks.tolist(), key=lambda idx: smooth_energy[idx], reverse=True)
    selected = sorted(peak_order[: min(4, len(peak_order))])
    if len(selected) < 3:
        return None

    row_boundaries = [0]
    for left_peak, right_peak in zip(selected, selected[1:]):
        row_boundaries.append(int((left_peak + right_peak) // 2))
    row_boundaries.append(h)

    standard_layout = _extract_standard_layout_multilead(trace, row_boundaries, target_width)
    if standard_layout is not None:
        return standard_layout

    leads: List[np.ndarray] = []
    n_cols = 4
    col_edges = np.linspace(0, w, n_cols + 1, dtype=int)
    for row_idx in range(len(selected)):
        top = max(row_boundaries[row_idx] - 6, 0)
        bottom = min(row_boundaries[row_idx + 1] + 6, h)
        if bottom - top < 10:
            continue
        row_mask = trace[top:bottom, :]
        for col_idx in range(n_cols):
            left = int(col_edges[col_idx])
            right = int(col_edges[col_idx + 1])
            if right - left < 24:
                continue
            cell_mask = row_mask[:, left:right]
            cell_signal = _extract_trace_from_mask(cell_mask)
            if cell_signal is None:
                continue
            leads.append(cell_signal)

    if len(leads) > 12:
        ranked = sorted(leads, key=lambda lead: float(np.std(lead)), reverse=True)
        leads = ranked[:12]
    return _finalize_image_leads(leads, target_width)


def _image_to_signal(image_path: str, target_width: int = 1200) -> np.ndarray:
    img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
    if img is None:
        return _image_to_signal_simple(image_path, target_width=target_width)
    h, w = img.shape[:2]
    if w != target_width:
        new_h = max(1, int(h * (target_width / max(w, 1))))
        img = cv2.resize(img, (target_width, new_h), interpolation=cv2.INTER_AREA)
        h, w = img.shape[:2]
    blur = cv2.GaussianBlur(img, (3, 3), 0)
    thr = cv2.adaptiveThreshold(
        blur, 255, cv2.ADAPTIVE_THRESH_MEAN_C, cv2.THRESH_BINARY_INV, 31, 5
    )
    hor_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (max(10, w // 20), 1))
    ver_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (1, max(10, h // 20)))
    hor_lines = cv2.morphologyEx(thr, cv2.MORPH_OPEN, hor_kernel)
    ver_lines = cv2.morphologyEx(thr, cv2.MORPH_OPEN, ver_kernel)
    grid = cv2.bitwise_or(hor_lines, ver_lines)
    trace = cv2.subtract(thr, grid)
    trace = cv2.medianBlur(trace, 3)

    y_indices: List[int] = []
    last_y = h // 2
    for x in range(w):
        col = np.where(trace[:, x] > 0)[0]
        if col.size == 0:
            y_indices.append(last_y)
            continue
        y = int(np.median(col))
        y_indices.append(y)
        last_y = y

    if not y_indices:
        return _image_to_signal_simple(image_path, target_width=target_width)

    multilead = _extract_multilead_from_image_mask(trace, target_width)
    if multilead is not None:
        return multilead

    signal = (h - 1 - np.array(y_indices, dtype=np.float32)).astype(np.float32)
    signal = _normalize_lead_signal(signal)
    if np.std(signal) < 0.05:
        return _image_to_signal_simple(image_path, target_width=target_width)
    return signal.reshape(1, -1).astype(np.float32)


def _write_temp_record(
    signal: np.ndarray, fs: float, record_dir: str, record_name: str = "image_ecg"
) -> str:
    p_signal = signal.T
    wfdb.wrsamp(
        record_name,
        fs=fs,
        units=["mV"] * p_signal.shape[1],
        sig_name=[f"lead{i + 1}" for i in range(p_signal.shape[1])],
        p_signal=p_signal,
        write_dir=record_dir,
    )
    return os.path.join(record_dir, record_name)


def _export_image_to_wfdb_bundle(
    image_path: Path, original_name: str, base_url: Optional[str] = None
) -> WFDBConversionOut:
    signal = _image_to_signal(str(image_path))
    record_id = f"{Path(original_name).stem}_{uuid.uuid4().hex[:10]}"
    export_dir = WFDB_EXPORTS_DIR / record_id
    export_dir.mkdir(parents=True, exist_ok=True)
    record_path = _write_temp_record(signal, fs=100.0, record_dir=str(export_dir), record_name=record_id)
    hea_path = Path(f"{record_path}.hea")
    dat_path = Path(f"{record_path}.dat")
    zip_path = export_dir / f"{record_id}.zip"
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        zf.write(hea_path, arcname=hea_path.name)
        zf.write(dat_path, arcname=dat_path.name)
    created_at = datetime.utcnow().isoformat()
    return WFDBConversionOut(
        conversionId=record_id,
        recordId=record_id,
        heaFileName=hea_path.name,
        datFileName=dat_path.name,
        zipFileName=zip_path.name,
        outputDir=str(export_dir),
        downloadUrl=f"{(base_url or _public_base_url()).rstrip('/')}/wfdb/{record_id}/download",
        createdAt=created_at,
    )


def _serialize_measurements(measurements: Dict[str, MeasurementOut]) -> Dict[str, Any]:
    return {key: value.model_dump() for key, value in measurements.items()}


def _risk_to_classification(risk: str) -> str:
    if risk == "High":
        return "Elevated screening pattern"
    if risk == "Medium":
        return "Moderate screening pattern"
    return "Lower-risk screening pattern"


def _derive_risk_level(
    score: float,
    threshold: float,
    bpm: int,
    signal_quality: float,
    measurements: Dict[str, MeasurementOut],
) -> str:
    sdnn = measurements["sdnn"].value
    rr = measurements["rr_interval"].value
    margin = score - threshold
    if margin >= 0.18:
        return "High"
    if margin >= 0.06:
        return "Medium"
    if margin >= 0.0 and (signal_quality < 0.7 or bpm < 50 or bpm > 115):
        return "Medium"
    if rr is not None and (rr < 450 or rr > 1400):
        return "Medium"
    if sdnn is not None and sdnn > 140:
        return "Medium"
    return "Low"


def _build_findings(
    *,
    classification: str,
    score: float,
    signal_quality_label: str,
    bpm: int,
    region: str,
    measurements: Dict[str, MeasurementOut],
) -> List[str]:
    findings = [
        f"AI-assisted screening result: {classification}",
        f"Model-derived score: {score:.3f}",
        f"Signal quality: {signal_quality_label}",
        f"Detected heart rate: {bpm} bpm",
    ]
    rr = measurements["rr_interval"].value
    if rr is not None:
        findings.append(f"Mean RR interval: {rr:.1f} ms")
    if region != "Undetermined":
        findings.append(f"Dominant signal region estimate: {region}")
    return findings


def _build_recommendations(
    *,
    risk: str,
    signal_quality_label: str,
    bpm: int,
    measurements: Dict[str, MeasurementOut],
) -> List[str]:
    recommendations = [
        "Review the ECG screening result with a qualified clinician.",
        "Correlate the output with symptoms, history, and the original ECG record.",
    ]
    if signal_quality_label != "high":
        recommendations.append("Repeat acquisition after improving electrode/contact quality.")
    if bpm < 50:
        recommendations.append("Confirm bradycardia clinically and compare with prior rhythm strips.")
    elif bpm > 110:
        recommendations.append("Assess tachycardia in context and obtain clinical review.")
    if measurements["sdnn"].value is not None and measurements["sdnn"].value > 140:
        recommendations.append("Review rhythm variability because HRV appears increased in this segment.")
    if risk in {"High", "Medium"}:
        recommendations.append("Prioritize formal medical evaluation and physician review.")
    return recommendations


def _feature_importance_top(features: np.ndarray, limit: int = 8) -> Dict[str, Any]:
    if features.size == 0:
        return {"topFeatures": []}
    abs_values = np.abs(features)
    order = np.argsort(abs_values)[::-1][:limit]
    return {
        "method": "top_feature_magnitudes",
        "topFeatures": [
            {"featureIndex": int(idx), "magnitude": round(float(abs_values[idx]), 6)}
            for idx in order
        ],
    }


def _validate_upload(file_name: str, allowed_extensions: set[str]) -> None:
    suffix = Path(file_name).suffix.lower()
    if suffix not in allowed_extensions:
        raise HTTPException(
            status_code=422,
            detail=f"Unsupported file extension {suffix or '[none]'}.",
        )


def _load_single_signal_file(path: Path) -> tuple[np.ndarray, float, list[str]]:
    suffix = path.suffix.lower()
    if suffix == ".csv":
        data = np.loadtxt(path, delimiter=",", dtype=np.float32)
        arr = np.asarray(data, dtype=np.float32)
        if arr.ndim == 1:
            arr = arr.reshape(1, -1)
        elif arr.ndim == 2 and arr.shape[0] > arr.shape[1]:
            arr = arr.T
        lead_names = [f"lead{i + 1}" for i in range(arr.shape[0])]
        return arr, 100.0, lead_names
    if suffix == ".wav":
        fs, data = wavfile.read(path)
        arr = np.asarray(data, dtype=np.float32)
        if arr.ndim == 1:
            arr = arr.reshape(1, -1)
        else:
            arr = arr.T
        peak = float(np.max(np.abs(arr))) if arr.size else 0.0
        if peak > 0:
            arr = arr / peak
        lead_names = [f"lead{i + 1}" for i in range(arr.shape[0])]
        return arr, float(fs), lead_names
    raise ValueError(f"Single-file loading is not supported for {suffix}")


async def _save_upload(upload: UploadFile, target_path: Path) -> None:
    content = await upload.read()
    if len(content) > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail="Uploaded file is too large")
    target_path.write_bytes(content)


def _analysis_from_db_row(row: sqlite3.Row) -> AnalysisResponse:
    return AnalysisResponse(
        analysisId=row["analysis_uid"],
        recordingId=row["source_filename"],
        patientId=row["patient_id"],
        status=row["status"],
        inputType=row["input_type"],
        classification=row["classification"],
        riskLevel=row["risk_level"],
        region=row["region"],
        confidence=float(row["confidence"]),
        modelScore=float(row["model_score"]),
        bpm=int(row["bpm"]),
        signalQuality=row["signal_quality"],
        signalQualityLabel=row["signal_quality_label"],
        activeCoils=json.loads(row["active_coils_json"]),
        recommendations=json.loads(row["recommendations_json"]),
        findings=json.loads(row["findings_json"]),
        explainability=json.loads(row["explainability_json"]),
        measurements={
            key: MeasurementOut(**value)
            for key, value in json.loads(row["measurements_json"]).items()
        },
        graphData=json.loads(row["graph_data_json"]),
        modelVersion=row["model_version"],
        pipelineVersion=row["pipeline_version"],
        featureVersion=row["feature_version"],
        featureCount=int(row["feature_count"]),
        threshold=float(row["threshold"]),
        createdAt=row["created_at"],
    )


def _save_analysis(
    *,
    patient_id: Optional[int],
    recording_id: Optional[str],
    input_type: str,
    source_filename: Optional[str],
    risk: str,
    classification: str,
    region: str,
    confidence: float,
    bpm: int,
    signal_quality: Optional[float],
    signal_quality_label: Optional[str],
    active_coils: List[str],
    recommendations: List[str],
    findings: List[str],
    explainability: Dict[str, Any],
    measurements: Dict[str, MeasurementOut],
    graph_data: Dict[str, Any],
    metadata: Dict[str, Any],
) -> AnalysisResponse:
    analysis_uid = uuid.uuid4().hex
    created_at = datetime.utcnow().isoformat()
    with _db_connection() as conn:
        conn.execute(
            """
            INSERT INTO analyses (
                analysis_uid, patient_id, input_type, source_filename, status,
                risk_level, classification, region, confidence, model_score,
                bpm, signal_quality, signal_quality_label, active_coils_json,
                recommendations_json, findings_json, explainability_json,
                measurements_json, graph_data_json, model_version,
                pipeline_version, feature_version, feature_count, threshold,
                created_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                analysis_uid,
                patient_id,
                input_type,
                recording_id or source_filename,
                "completed",
                risk,
                classification,
                region,
                confidence,
                confidence,
                bpm,
                signal_quality,
                signal_quality_label,
                json.dumps(active_coils),
                json.dumps(recommendations),
                json.dumps(findings),
                json.dumps(explainability),
                json.dumps(_serialize_measurements(measurements)),
                json.dumps(graph_data),
                metadata["model_version"],
                metadata["pipeline_version"],
                metadata["feature_version"],
                metadata["feature_count"],
                metadata["threshold"],
                created_at,
            ),
        )
        row = conn.execute(
            "SELECT * FROM analyses WHERE analysis_uid = ?",
            (analysis_uid,),
        ).fetchone()
        conn.commit()
    if row is None:
        raise HTTPException(status_code=500, detail="Failed to persist analysis")
    return _analysis_from_db_row(row)


def _run_signal_analysis(
    *,
    raw_signal: np.ndarray,
    processed_signal: np.ndarray,
    fs: float,
    lead_names: Optional[List[str]],
    recording_id: Optional[str],
    patient_id: Optional[int],
    input_type: str,
    source_filename: Optional[str],
) -> AnalysisResponse:
    processed = ecg_pipeline.ensure_lead_first(processed_signal)
    raw = ecg_pipeline.ensure_lead_first(raw_signal)
    rr = ecg_pipeline.compute_rr_hrv(ecg_pipeline.detect_r_peaks(ecg_pipeline.representative_lead(processed), fs), fs)
    bpm = int(round(rr["heart_rate_bpm"])) if rr["heart_rate_bpm"] is not None else 0
    quality = ecg_pipeline.signal_quality_metrics(raw, processed, fs)
    signal_quality = round(float(quality["signal_quality_score"]) / 100.0, 3)
    signal_quality_label = str(quality["noise_level"]).lower()
    measurements, graph_data = _derive_measurements(processed, fs)
    signal_signature = _signal_signature_metrics(raw, processed, fs, quality, rr)
    measurements["heart_rate"] = MeasurementOut(
        name="heart_rate",
        value=float(rr["heart_rate_bpm"]) if rr["heart_rate_bpm"] is not None else None,
        unit="bpm",
        source="DETECTED" if rr["heart_rate_bpm"] is not None else "UNAVAILABLE",
    )
    measurements["rr_interval"] = MeasurementOut(
        name="rr_interval",
        value=float(rr["rr_mean_ms"]) if rr["rr_mean_ms"] is not None else None,
        unit="ms",
        source="DETECTED" if rr["rr_mean_ms"] is not None else "UNAVAILABLE",
    )
    measurements["sdnn"] = MeasurementOut(
        name="sdnn",
        value=float(rr["sdnn_ms"]) if rr["sdnn_ms"] is not None else None,
        unit="ms",
        source="MEASURED" if rr["sdnn_ms"] is not None else "UNAVAILABLE",
    )
    measurements["rmssd"] = MeasurementOut(
        name="rmssd",
        value=float(rr["rmssd_ms"]) if rr["rmssd_ms"] is not None else None,
        unit="ms",
        source="MEASURED" if rr["rmssd_ms"] is not None else "UNAVAILABLE",
    )
    measurements["pnn50"] = MeasurementOut(
        name="pnn50",
        value=float(rr["pnn50_pct"]) if rr["pnn50_pct"] is not None else None,
        unit="%",
        source="MEASURED" if rr["pnn50_pct"] is not None else "UNAVAILABLE",
    )
    candidate_leads = _top_signal_leads(processed, limit=4)
    qrs_candidates: List[Optional[float]] = []
    pr_candidates: List[Optional[float]] = []
    qt_candidates: List[Optional[float]] = []
    qtc_candidates: List[Optional[float]] = []
    st_candidates: List[Optional[float]] = []
    for lead in candidate_leads:
        lead_peaks = ecg_pipeline.detect_r_peaks(lead, fs)
        qrs_candidates.append(ecg_pipeline.estimate_qrs_duration_ms(lead, lead_peaks, fs))
        lead_intervals = ecg_pipeline.estimate_wave_intervals(lead, lead_peaks, fs)
        pr_candidates.append(lead_intervals["pr_interval_ms_estimate"])
        qt_candidates.append(lead_intervals["qt_interval_ms_estimate"])
        qtc_candidates.append(lead_intervals["qtc_bazett_ms_estimate"])
        st_candidates.append(lead_intervals["st_deviation_estimate"])

    qrs_ms = _median_non_null(qrs_candidates)
    pr_ms = _median_non_null(pr_candidates)
    qt_ms = _median_non_null(qt_candidates)
    qtc_ms = _median_non_null(qtc_candidates)
    st_mv = _median_non_null(st_candidates)
    measurements["qrs_duration"] = MeasurementOut(
        name="qrs_duration",
        value=qrs_ms,
        unit="ms",
        source="ESTIMATED" if qrs_ms is not None else "UNAVAILABLE",
    )
    measurements["pr_interval"] = MeasurementOut(
        name="pr_interval",
        value=pr_ms,
        unit="ms",
        source="ESTIMATED" if pr_ms is not None else "UNAVAILABLE",
    )
    measurements["qt_interval"] = MeasurementOut(
        name="qt_interval",
        value=qt_ms,
        unit="ms",
        source="ESTIMATED" if qt_ms is not None else "UNAVAILABLE",
    )
    measurements["qtc"] = MeasurementOut(
        name="qtc",
        value=qtc_ms,
        unit="ms",
        source="ESTIMATED" if qtc_ms is not None else "UNAVAILABLE",
    )
    measurements["st_deviation"] = MeasurementOut(
        name="st_deviation",
        value=st_mv,
        unit="mV",
        source="ESTIMATED" if st_mv is not None else "UNAVAILABLE",
    )
    rhythm_label = ecg_pipeline.classify_rhythm(
        rr.get("heart_rate_bpm"),
        rr.get("rr_std_ms"),
        rr.get("pnn50_pct"),
        float(quality["signal_quality_score"]),
    ) or "Unclassified rhythm pattern"

    features = np.asarray([], dtype=np.float32)
    metadata = _fallback_model_metadata()
    threshold = float(metadata["threshold"])
    model_error: Optional[str] = None
    raw_probability: Optional[float] = None
    inference_mode = "heuristic_fallback"
    if input_type == "image":
        metadata = {
            "model_version": "image_signal_screening_v2",
            "pipeline_version": "image_ecg_signal_only_v2",
            "feature_version": "rule_based_measurement_fusion_v2",
            "feature_count": 0,
            "threshold": 0.52,
        }
        threshold = 0.52
        inference_mode = "image_signal_screening"
        score = _image_signal_screening_score(
            bpm=bpm,
            signal_quality=signal_quality,
            measurements=measurements,
            signal_signature=signal_signature,
        )
    else:
        try:
            model_bundle = _ensure_model()
            features = ecg_pipeline.extract_model_features(processed, fs)
            x_imputed = model_bundle.imputer.transform([features])
            x_scaled = model_bundle.qt.transform(x_imputed)
            probability_details = model_bundle.predict_details(x_scaled)
            raw_probability = float(probability_details["raw_probability"])
            score = float(probability_details["calibrated_probability"])
            metadata = model_bundle.metadata
            threshold = float(model_bundle.threshold)
            inference_mode = "calibrated_model" if probability_details["calibration_applied"] else "raw_model"
        except HTTPException as exc:
            model_error = str(exc.detail)
            score = _heuristic_model_score(
                bpm=bpm,
                signal_quality=signal_quality,
                measurements=measurements,
                signal_signature=signal_signature,
            )

    risk = ecg_pipeline.risk_band(score, threshold)
    region, coils = ecg_pipeline.region_and_coils(processed, risk)
    classification = _risk_to_classification(risk)
    graph_data["signalQuality"] = signal_quality
    graph_data["signalQualityLabel"] = signal_quality_label
    graph_data["leadNames"] = lead_names or []
    graph_data["rhythmLabel"] = rhythm_label
    graph_data["signalSignature"] = signal_signature
    findings = [
        f"AI-assisted screening result: {classification}",
        f"Inference mode: {inference_mode}",
        f"Model-derived score: {score:.3f}",
        f"Rhythm screening: {rhythm_label}",
        f"Signal quality score: {quality['signal_quality_score']:.2f}",
        f"Noise level: {quality['noise_level']}",
    ]
    if raw_probability is not None:
        findings.append(f"Raw probability before calibration: {raw_probability:.3f}")
        findings.append(f"Calibrated probability: {score:.3f}")
    if signal_signature.get("lead_diversity_index", 0.0) > 0:
        findings.append(
            f"Lead diversity index: {signal_signature['lead_diversity_index']:.3f}"
        )
    if signal_signature.get("spectral_entropy", 0.0) > 0:
        findings.append(
            f"Waveform complexity index: {signal_signature['spectral_entropy']:.3f}"
        )
    if model_error:
        findings.append("Fallback signal-based inference was used because the deploy-time model runtime was unavailable.")
    if input_type == "image":
        findings.append("Image upload used signal-only ECG screening because the packaged V15 classifier is validated for WFDB multi-lead records, not paper/screenshot ECG inputs.")
    if recording_id:
        findings.append(f"Recording ID: {recording_id}")
    recommendations = [
        "Review the ECG screening result with a qualified clinician.",
        "Correlate the output with symptoms, history, and the original ECG record.",
        ecg_pipeline.recommended_action(risk, quality["signal_quality_score"]),
    ]

    return _save_analysis(
        patient_id=patient_id,
        recording_id=recording_id,
        input_type=input_type,
        source_filename=source_filename,
        risk=risk,
        classification=classification,
        region=region,
        confidence=score,
        bpm=bpm,
        signal_quality=signal_quality,
        signal_quality_label=signal_quality_label,
        active_coils=coils,
        recommendations=recommendations,
        findings=findings,
        explainability={
            "type": "Feature magnitude ranking",
            "topFeatures": ecg_pipeline.explain_top_features(features),
            "fallbackReason": model_error,
            "inferenceMode": inference_mode,
            "rawProbability": raw_probability,
            "calibratedProbability": score,
        },
        measurements=measurements,
        graph_data=graph_data,
        metadata={
            "model_version": metadata["model_version"],
            "pipeline_version": metadata["pipeline_version"],
            "feature_version": metadata["feature_version"],
            "feature_count": metadata["feature_count"],
            "threshold": threshold,
        },
    )


def _report_priority(risk_level: str) -> str:
    if risk_level == "High":
        return "Urgent review"
    if risk_level == "Medium":
        return "Priority review"
    return "Routine review"


def _report_limitations(analysis: AnalysisResponse) -> List[Dict[str, str]]:
    items: List[Dict[str, str]] = []
    if analysis.signalQualityLabel and analysis.signalQualityLabel.lower() != "high":
        items.append(
            {
                "problem": "Suboptimal signal quality",
                "why": "Noise or reduced contact can affect waveform interpretation and interval estimates.",
            }
        )
    for key in ("pr_interval", "qt_interval", "qtc", "st_deviation"):
        measurement = analysis.measurements.get(key)
        if measurement and measurement.value is None:
            items.append(
                {
                    "problem": f"{measurement.name} unavailable",
                    "why": "This metric was not estimated reliably from the analyzed segment and should be reviewed manually if clinically needed.",
                }
            )
    if not items:
        items.append(
            {
                "problem": "Single-segment review",
                "why": "Trend interpretation remains limited when only one analyzed segment is available.",
            }
        )
    return items[:4]


def _report_findings(analysis: AnalysisResponse) -> List[Dict[str, str]]:
    rows: List[Dict[str, str]] = []
    measurement_map = {
        "Heart rate": analysis.measurements.get("heart_rate"),
        "RR interval": analysis.measurements.get("rr_interval"),
        "SDNN": analysis.measurements.get("sdnn"),
        "RMSSD": analysis.measurements.get("rmssd"),
        "pNN50": analysis.measurements.get("pnn50"),
        "PR interval": analysis.measurements.get("pr_interval"),
        "QRS duration": analysis.measurements.get("qrs_duration"),
        "QT interval": analysis.measurements.get("qt_interval"),
        "QTc": analysis.measurements.get("qtc"),
        "ST deviation": analysis.measurements.get("st_deviation"),
    }
    for label, measurement in measurement_map.items():
        if measurement is None or measurement.value is None:
            continue
        value = f"{round(float(measurement.value), 2)} {measurement.unit or ''}".strip()
        rows.append(
            {
                "finding": label,
                "value": value,
                "source": measurement.source,
                "reliability": "Automated" if measurement.source in {"DETECTED", "MEASURED"} else "Estimated",
                "significance": f"{label} extracted from the analyzed ECG segment.",
                "review": "Review alongside raw ECG and clinical context.",
            }
        )
    rows.insert(
        0,
        {
            "finding": "AI screening classification",
            "value": analysis.classification,
            "source": analysis.modelVersion,
            "reliability": "Model-derived",
            "significance": f"Risk band: {analysis.riskLevel}. Score: {analysis.modelScore * 100.0:.2f}%.",
            "review": "Use as AI-assisted screening output, not standalone diagnosis.",
        },
    )
    rows.insert(
        1,
        {
            "finding": "Signal quality",
            "value": f"{(analysis.signalQuality or 0.0) * 100.0:.1f}%",
            "source": analysis.pipelineVersion,
            "reliability": analysis.signalQualityLabel or "Unavailable",
            "significance": f"Detected quality label: {analysis.signalQualityLabel or 'unknown'}.",
            "review": "Repeat acquisition if clinically important and quality is reduced.",
        },
    )
    return rows[:8]


def _report_next_steps(analysis: AnalysisResponse) -> List[Dict[str, str]]:
    rows: List[Dict[str, str]] = []
    for item in analysis.recommendations:
        rows.append(
            {
                "finding": "Clinical recommendation",
                "next_step": item,
            }
        )
    if not rows:
        rows.append(
            {
                "finding": "Clinical review",
                "next_step": "Review the ECG output with a qualified clinician.",
            }
        )
    return rows[:5]


def _report_context_from_analysis(analysis: AnalysisResponse) -> Dict[str, Any]:
    waveform = np.asarray(analysis.graphData.get("waveform", []), dtype=np.float32)
    if waveform.size == 0:
        waveform = np.zeros(1000, dtype=np.float32)
    lead_names = analysis.graphData.get("leadNames") or [f"Lead {idx + 1}" for idx in range(12)]
    num_leads = max(len(lead_names), 12)
    filtered_signal = np.vstack([waveform] * num_leads).astype(np.float32)
    peaks = np.asarray(analysis.graphData.get("rPeaks", []), dtype=int)
    rr_ms = np.asarray(analysis.graphData.get("rrIntervalsMs", []), dtype=np.float32)
    top_features = []
    for row in analysis.explainability.get("topFeatures", []):
        feature_index = row.get("feature_index", row.get("featureIndex"))
        feature_value = row.get("feature_value", row.get("magnitude"))
        if feature_index is None or feature_value is None:
            continue
        top_features.append(
            {
                "feature_index": int(feature_index),
                "feature_value": float(feature_value),
            }
        )
    signal_quality_pct = None
    if analysis.signalQuality is not None:
        signal_quality_pct = float(analysis.signalQuality) * 100.0 if analysis.signalQuality <= 1.0 else float(analysis.signalQuality)
    st_value = analysis.measurements.get("st_deviation").value if analysis.measurements.get("st_deviation") else None
    context_analysis = {
        "record_id": analysis.recordingId or analysis.analysisId,
        "sampling_rate_hz": 100.0,
        "num_samples": int(waveform.size),
        "num_leads": num_leads,
        "supported_clinical_outputs": {
            "heart_rate_bpm": analysis.measurements.get("heart_rate").value if analysis.measurements.get("heart_rate") else analysis.bpm,
            "rr_interval_ms": analysis.measurements.get("rr_interval").value if analysis.measurements.get("rr_interval") else None,
            "pr_interval_ms_estimate": analysis.measurements.get("pr_interval").value if analysis.measurements.get("pr_interval") else None,
            "qrs_duration_ms_estimate": analysis.measurements.get("qrs_duration").value if analysis.measurements.get("qrs_duration") else None,
            "qt_interval_ms_estimate": analysis.measurements.get("qt_interval").value if analysis.measurements.get("qt_interval") else None,
            "qtc_bazett_ms_estimate": analysis.measurements.get("qtc").value if analysis.measurements.get("qtc") else None,
            "st_deviation_estimate": float(st_value) if st_value is not None else None,
            "heart_rhythm_classification": "Possible irregular rhythm" if analysis.riskLevel in {"High", "Medium"} else "Normal sinus-like rhythm",
            "heart_rate_variability": {
                "sdnn_ms": analysis.measurements.get("sdnn").value if analysis.measurements.get("sdnn") else None,
                "rmssd_ms": analysis.measurements.get("rmssd").value if analysis.measurements.get("rmssd") else None,
                "pnn50_pct": analysis.measurements.get("pnn50").value if analysis.measurements.get("pnn50") else None,
            },
            "signal_quality_score": signal_quality_pct,
            "noise_detection": analysis.signalQualityLabel,
            "baseline_wander_ratio": None,
            "noise_ratio": None,
            "clipping_ratio": None,
        },
        "model_inference": {
            "disease_classification": analysis.classification,
            "pre_stroke_risk_score": float(analysis.modelScore) * 100.0 if analysis.modelScore <= 1.0 else float(analysis.modelScore),
            "model_threshold": float(analysis.threshold),
            "risk_level": analysis.riskLevel,
            "recommended_action": analysis.recommendations[-1] if analysis.recommendations else "Clinical review recommended.",
            "model_name": analysis.modelVersion,
            "inference_mode": analysis.explainability.get("inferenceMode"),
            "raw_probability": analysis.explainability.get("rawProbability"),
            "calibrated_probability": analysis.explainability.get("calibratedProbability"),
            "fallback_reason": analysis.explainability.get("fallbackReason"),
            "explainable_ai": {"top_features": top_features},
        },
    }
    return {
        "analysis": context_analysis,
        "meta": {
            "patient_id": analysis.patientId,
            "lead_names": lead_names,
        },
        "freq_metrics": {"available": False},
        "rr_ms": rr_ms.tolist(),
        "quality_warnings": _report_limitations(analysis),
        "evidence_rows": _report_findings(analysis),
        "next_steps": _report_next_steps(analysis),
        "priority": _report_priority(analysis.riskLevel),
        "raw_signal": filtered_signal,
        "filtered_signal": filtered_signal,
        "rep_filtered": waveform,
        "fs": 100.0,
        "peaks": peaks.tolist(),
        "selected_beat": {"available": False},
        "poincare": {"available": False},
    }


def _build_basic_report_pdf(report_path: Path, analysis: AnalysisResponse) -> None:
    pdf = canvas.Canvas(str(report_path), pagesize=A4)
    width, height = A4
    y = height - 42

    def line(text: str, *, size: int = 10, step: int = 14) -> None:
        nonlocal y
        pdf.setFont("Helvetica", size)
        pdf.drawString(42, y, text[:120])
        y -= step

    pdf.setTitle(f"Cardiac Pre-Ischemia Report - {analysis.analysisId}")
    pdf.setFont("Helvetica-Bold", 18)
    pdf.drawString(42, y, "CARDIAC PRE-ISCHEMIA")
    y -= 22
    pdf.setFont("Helvetica-Bold", 13)
    pdf.drawString(42, y, "AI-Assisted ECG Analysis Report")
    y -= 20

    line(f"Generated: {datetime.utcnow().isoformat()} UTC", size=9, step=12)
    line(f"Analysis ID: {analysis.analysisId}", size=9, step=12)
    line(f"Recording ID: {analysis.recordingId or '-'}", size=9, step=12)
    line(f"Model Version: {analysis.modelVersion}", size=9, step=12)
    line(f"Pipeline Version: {analysis.pipelineVersion}", size=9, step=18)

    pdf.setFont("Helvetica-Bold", 12)
    pdf.drawString(42, y, "Clinical Summary")
    y -= 16
    line(f"Classification: {analysis.classification}")
    line(f"Risk Level: {analysis.riskLevel}")
    line(f"Model Score: {analysis.modelScore * 100.0:.2f}%")
    line(f"Heart Rate: {analysis.bpm} bpm")
    line(
        f"Signal Quality: {((analysis.signalQuality or 0.0) * 100.0):.1f}% ({analysis.signalQualityLabel or 'unknown'})",
        step=18,
    )

    pdf.setFont("Helvetica-Bold", 12)
    pdf.drawString(42, y, "Measurements")
    y -= 16
    for key in ["heart_rate", "rr_interval", "pr_interval", "qrs_duration", "qt_interval", "qtc", "st_deviation", "sdnn", "rmssd", "pnn50"]:
        measurement = analysis.measurements.get(key)
        if measurement is None:
            continue
        value = "-" if measurement.value is None else f"{measurement.value:.2f}"
        unit = measurement.unit or ""
        line(f"{measurement.name}: {value} {unit} [{measurement.source}]")
        if y < 120:
            pdf.showPage()
            y = height - 42

    y -= 4
    pdf.setFont("Helvetica-Bold", 12)
    pdf.drawString(42, y, "Key Findings")
    y -= 16
    for item in analysis.findings[:10]:
        line(f"- {item}", size=9, step=12)
        if y < 120:
            pdf.showPage()
            y = height - 42

    y -= 4
    pdf.setFont("Helvetica-Bold", 12)
    pdf.drawString(42, y, "Recommendations")
    y -= 16
    for item in analysis.recommendations[:8]:
        line(f"- {item}", size=9, step=12)
        if y < 100:
            pdf.showPage()
            y = height - 42

    pdf.save()


def _build_report_file(analysis: AnalysisResponse) -> Path:
    report_uid = uuid.uuid4().hex
    report_path = REPORTS_DIR / f"{report_uid}.pdf"
    try:
        if str(PROJECT_ROOT) not in sys.path:
            sys.path.append(str(PROJECT_ROOT))
        from new_report import generate_report_variant

        context = _report_context_from_analysis(analysis)
        _ = MASTER_REPORT_TEMPLATE
        generate_report_variant(report_path, context, "approved")
    except Exception:
        _build_basic_report_pdf(report_path, analysis)
    return report_path


def _store_report(
    *,
    analysis: AnalysisResponse,
    patient_id: Optional[int],
) -> ReportOut:
    report_uid = uuid.uuid4().hex
    report_file = _build_report_file(analysis)
    created_at = datetime.utcnow().isoformat()
    with _db_connection() as conn:
        conn.execute(
            """
            INSERT INTO reports (report_uid, analysis_uid, patient_id, file_path, created_at)
            VALUES (?, ?, ?, ?, ?)
            """,
            (report_uid, analysis.analysisId, patient_id, str(report_file), created_at),
        )
        conn.commit()
    return ReportOut(
        reportId=report_uid,
        analysisId=analysis.analysisId,
        patientId=patient_id,
        filePath=str(report_file),
        createdAt=created_at,
    )


def _probe_analysis_from_record(record_path: Path) -> ModelProbeRow:
    signal, fs, lead_names = ecg_pipeline.load_wfdb_record(str(record_path))
    processed = ecg_pipeline.preprocess_signal(signal, fs)
    rr = ecg_pipeline.compute_rr_hrv(
        ecg_pipeline.detect_r_peaks(ecg_pipeline.representative_lead(processed), fs), fs
    )
    measurements, _ = _derive_measurements(processed, fs)
    quality = ecg_pipeline.signal_quality_metrics(signal, processed, fs)
    signal_signature = _signal_signature_metrics(signal, processed, fs, quality, rr)
    representative = ecg_pipeline.representative_lead(processed)
    feature_vector = ecg_pipeline.extract_model_features(processed, fs)
    feature_hash = hashlib.sha256(feature_vector.astype(np.float32).tobytes()).hexdigest()

    metadata = _fallback_model_metadata()
    threshold = float(metadata["threshold"])
    raw_probability: Optional[float] = None
    inference_mode = "heuristic_fallback"
    model_error: Optional[str] = None
    try:
        model_bundle = _ensure_model()
        x_imputed = model_bundle.imputer.transform([feature_vector])
        x_scaled = model_bundle.qt.transform(x_imputed)
        probability_details = model_bundle.predict_details(x_scaled)
        raw_probability = float(probability_details["raw_probability"])
        calibrated_probability = float(probability_details["calibrated_probability"])
        threshold = float(model_bundle.threshold)
        metadata = model_bundle.metadata
        inference_mode = "calibrated_model" if probability_details["calibration_applied"] else "raw_model"
    except HTTPException as exc:
        model_error = str(exc.detail)
        calibrated_probability = _heuristic_model_score(
            bpm=int(round(rr["heart_rate_bpm"])) if rr["heart_rate_bpm"] is not None else 0,
            signal_quality=round(float(quality["signal_quality_score"]) / 100.0, 3),
            measurements=measurements,
            signal_signature=signal_signature,
        )

    predicted_class = _risk_to_classification(ecg_pipeline.risk_band(calibrated_probability, threshold))
    if model_error:
        metadata = _fallback_model_metadata()

    return ModelProbeRow(
        recordingId=record_path.stem,
        inputFile=str(record_path),
        signalLength=int(representative.size),
        samplingRate=float(fs),
        channelUsed="representative_lead_dynamic",
        signalMin=float(np.min(representative)) if representative.size else None,
        signalMax=float(np.max(representative)) if representative.size else None,
        signalMean=float(np.mean(representative)) if representative.size else None,
        signalStd=float(np.std(representative)) if representative.size else None,
        validSamples=int(np.sum(np.isfinite(representative))) if representative.size else 0,
        featureCount=int(feature_vector.size),
        featureVectorHash=feature_hash,
        featureMin=float(np.min(feature_vector)) if feature_vector.size else None,
        featureMax=float(np.max(feature_vector)) if feature_vector.size else None,
        featureMean=float(np.mean(feature_vector)) if feature_vector.size else None,
        featureStd=float(np.std(feature_vector)) if feature_vector.size else None,
        heartRate=measurements.get("heart_rate").value if measurements.get("heart_rate") else None,
        rrIntervalMs=measurements.get("rr_interval").value if measurements.get("rr_interval") else None,
        qrsDurationMs=measurements.get("qrs_duration").value if measurements.get("qrs_duration") else None,
        qtcMs=measurements.get("qtc").value if measurements.get("qtc") else None,
        stDeviation=measurements.get("st_deviation").value if measurements.get("st_deviation") else None,
        rawProbability=raw_probability,
        calibratedProbability=float(calibrated_probability),
        threshold=float(threshold),
        predictedClass=predicted_class,
        inferenceMode=inference_mode,
        modelVersion=str(metadata["model_version"]),
    )


@app.get("/debug/model-probe", response_model=ModelProbeOut)
def debug_model_probe(
    directory: Optional[str] = None,
    limit: int = 12,
    user: Dict[str, Any] = Depends(_current_user),
) -> ModelProbeOut:
    _ensure_role(user, ["doctor"])
    allowed_dirs = [
        Path(r"D:\DATA\100"),
        Path(r"D:\DATA\500"),
        BASE_DIR / "generated_wfdb",
    ]
    candidate_dirs: List[Path] = []
    if directory:
        requested = Path(directory).resolve()
        permitted = False
        for allowed in allowed_dirs:
            try:
                requested.relative_to(allowed.resolve())
                permitted = True
                break
            except ValueError:
                continue
        if not permitted:
            raise HTTPException(status_code=403, detail="Requested diagnostic directory is not allowed")
        candidate_dirs.append(requested)
    else:
        candidate_dirs.extend(allowed_dirs)
    record_rows: List[ModelProbeRow] = []
    seen: set[str] = set()
    for base_dir in candidate_dirs:
        if not base_dir.is_dir():
            continue
        for hea_path in sorted(base_dir.rglob("*.hea")):
            record_stem = str(hea_path.with_suffix(""))
            if record_stem in seen:
                continue
            dat_path = hea_path.with_suffix(".dat")
            if not dat_path.is_file():
                continue
            seen.add(record_stem)
            try:
                record_rows.append(_probe_analysis_from_record(hea_path.with_suffix("")))
            except Exception:
                continue
            if len(record_rows) >= max(1, min(limit, 20)):
                break
        if len(record_rows) >= max(1, min(limit, 20)):
            break

    calibrated = np.asarray([row.calibratedProbability for row in record_rows], dtype=np.float64)
    raw_values = [round(float(row.rawProbability), 6) for row in record_rows if row.rawProbability is not None]
    calibrated_values = [round(float(row.calibratedProbability), 6) for row in record_rows]
    feature_hashes = {row.featureVectorHash for row in record_rows if row.featureVectorHash}
    most_common_prediction_count = 0
    if calibrated_values:
        counts: Dict[float, int] = {}
        for value in calibrated_values:
            counts[value] = counts.get(value, 0) + 1
        most_common_prediction_count = max(counts.values())

    return ModelProbeOut(
        total=len(record_rows),
        uniqueFeatureVectors=len(feature_hashes),
        uniqueRawProbabilities=len(set(raw_values)),
        uniqueCalibratedProbabilities=len(set(calibrated_values)),
        probabilityMean=float(np.mean(calibrated)) if calibrated.size else None,
        probabilityStd=float(np.std(calibrated)) if calibrated.size else None,
        probabilityMin=float(np.min(calibrated)) if calibrated.size else None,
        probabilityMax=float(np.max(calibrated)) if calibrated.size else None,
        pctAbove099=float(np.mean(calibrated > 0.99) * 100.0) if calibrated.size else None,
        pctBelow001=float(np.mean(calibrated < 0.01) * 100.0) if calibrated.size else None,
        pctIdenticalPredictions=float((most_common_prediction_count / len(record_rows)) * 100.0) if record_rows else None,
        rows=record_rows,
    )


def _report_trend(patient_id: int) -> Tuple[List[str], List[int], List[str]]:
    with _db_connection() as conn:
        rows = conn.execute(
            """
            SELECT created_at, bpm, risk_level
            FROM analyses
            WHERE patient_id = ?
            ORDER BY created_at DESC
            LIMIT 7
            """,
            (patient_id,),
        ).fetchall()
    if not rows:
        return [], [], []
    rows = list(reversed(rows))
    labels = [row["created_at"][5:10] for row in rows]
    bpm = [int(row["bpm"]) for row in rows]
    risk_levels = [row["risk_level"] for row in rows]
    return labels, bpm, risk_levels


@app.on_event("startup")
def _startup() -> None:
    _ensure_runtime_dirs()
    _init_db()
    global _model_bundle
    try:
        model_dir = _resolve_model_dir()
        if model_dir is not None:
            _ensure_model_files(model_dir)
            _model_bundle = ModelBundle.load(str(model_dir))
    except Exception:
        _model_bundle = None


@app.get("/health", response_model=HealthOut)
def health() -> HealthOut:
    database_status = "ok"
    try:
        with _db_connection() as conn:
            conn.execute("SELECT 1").fetchone()
    except Exception:
        database_status = "error"

    model_status = "not_loaded"
    model_version = None
    pipeline_version = None
    threshold = None
    try:
        model_bundle = _ensure_model()
        model_status = "loaded"
        model_version = model_bundle.metadata["model_version"]
        pipeline_version = model_bundle.metadata["pipeline_version"]
        threshold = float(model_bundle.metadata["threshold"])
    except HTTPException:
        model_status = "not_loaded"

    return HealthOut(
        backend="ok",
        database=database_status,
        model=model_status,
        modelVersion=model_version,
        pipelineVersion=pipeline_version,
        threshold=threshold,
        time=datetime.utcnow().isoformat(),
    )


@app.post("/auth/register", response_model=AuthOut)
def register(payload: AuthIn) -> AuthOut:
    role = payload.role.lower()
    if role not in {"patient", "doctor"}:
        raise HTTPException(status_code=422, detail="Role must be patient or doctor")
    identity_email = _identity_email(payload.mobile, payload.email)
    mobile = _normalize_mobile(payload.mobile)
    if not identity_email and not mobile:
        raise HTTPException(status_code=422, detail="Email or mobile is required")

    created_at = datetime.utcnow().isoformat()
    password_hash = _hash_password(payload.password)
    with _db_connection() as conn:
        try:
            cur = conn.execute(
                """
                INSERT INTO users (email, mobile, password_hash, role, name, specialty, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    identity_email,
                    mobile,
                    password_hash,
                    role,
                    payload.name,
                    payload.specialty,
                    created_at,
                ),
            )
            user_id = cur.lastrowid
            token = _create_token()
            conn.execute(
                "INSERT INTO sessions (token, user_id, created_at) VALUES (?, ?, ?)",
                (token, user_id, created_at),
            )
            conn.commit()
        except sqlite3.IntegrityError as exc:
            raise HTTPException(status_code=409, detail=f"Identity already exists: {exc}")

        if role == "patient" and payload.name:
            existing = conn.execute(
                "SELECT id FROM patients WHERE user_id = ?",
                (user_id,),
            ).fetchone()
            if existing is None:
                conn.execute(
                    """
                    INSERT INTO patients (user_id, created_by_user_id, name, phone, created_at)
                    VALUES (?, ?, ?, ?, ?)
                    """,
                    (user_id, user_id, payload.name, mobile, created_at),
                )
                conn.commit()

    return AuthOut(
        token=token,
        userId=user_id,
        role=role,
        name=payload.name,
        mobile=mobile,
        specialty=payload.specialty,
    )


@app.post("/auth/login", response_model=AuthOut)
def login(payload: AuthIn) -> AuthOut:
    identity_email = _identity_email(payload.mobile, payload.email)
    mobile = _normalize_mobile(payload.mobile)
    password_hash = _hash_password(payload.password)

    with _db_connection() as conn:
        row = conn.execute(
            """
            SELECT id, role, name, mobile, specialty, password_hash
            FROM users
            WHERE (email = ? AND ? IS NOT NULL) OR (mobile = ? AND ? IS NOT NULL)
            LIMIT 1
            """,
            (identity_email, identity_email, mobile, mobile),
        ).fetchone()
        if row is None or row["password_hash"] != password_hash:
            raise HTTPException(status_code=401, detail="Invalid credentials")

        token = _create_token()
        created_at = datetime.utcnow().isoformat()
        conn.execute(
            "INSERT INTO sessions (token, user_id, created_at) VALUES (?, ?, ?)",
            (token, row["id"], created_at),
        )
        conn.commit()

    return AuthOut(
        token=token,
        userId=row["id"],
        role=row["role"],
        name=row["name"],
        mobile=row["mobile"],
        specialty=row["specialty"],
    )


@app.post("/auth/forgot-password", response_model=ForgotPasswordOut)
def forgot_password(payload: ForgotPasswordIn) -> ForgotPasswordOut:
    identity_email = _identity_email(payload.mobile, payload.email)
    mobile = _normalize_mobile(payload.mobile)
    request_uid = uuid.uuid4().hex
    created_at = datetime.utcnow().isoformat()
    with _db_connection() as conn:
        user = conn.execute(
            """
            SELECT id
            FROM users
            WHERE (email = ? AND ? IS NOT NULL) OR (mobile = ? AND ? IS NOT NULL)
            LIMIT 1
            """,
            (identity_email, identity_email, mobile, mobile),
        ).fetchone()
        conn.execute(
            """
            INSERT INTO password_reset_requests (request_uid, user_id, email, mobile, status, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                request_uid,
                int(user["id"]) if user else None,
                identity_email,
                mobile,
                "recorded",
                created_at,
            ),
        )
        conn.commit()
    return ForgotPasswordOut(
        requestId=request_uid,
        status="recorded",
        message="Reset request recorded. Delivery workflow is not configured on this local backend.",
    )


@app.get("/auth/me", response_model=AuthOut)
def auth_me(user: Dict[str, Any] = Depends(_current_user)) -> AuthOut:
    return AuthOut(
        token="",
        userId=user["id"],
        role=user["role"],
        name=user["name"],
        mobile=user["mobile"],
        specialty=user["specialty"],
    )


@app.post("/patients", response_model=PatientOut)
def create_patient(payload: PatientIn, user: Dict[str, Any] = Depends(_current_user)) -> PatientOut:
    created_at = datetime.utcnow().isoformat()
    patient_user_id = user["id"] if user["role"] == "patient" else None
    with _db_connection() as conn:
        cur = conn.execute(
            """
            INSERT INTO patients (user_id, created_by_user_id, name, age, gender, phone, notes, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                patient_user_id,
                user["id"],
                payload.name,
                payload.age,
                payload.gender,
                payload.phone,
                payload.notes,
                created_at,
            ),
        )
        patient_id = cur.lastrowid
        conn.commit()
    return PatientOut(
        id=patient_id,
        userId=patient_user_id,
        createdByUserId=user["id"],
        name=payload.name,
        age=payload.age,
        gender=payload.gender,
        phone=payload.phone,
        notes=payload.notes,
        createdAt=created_at,
    )


def _assert_patient_access(user: Dict[str, Any], patient_row: sqlite3.Row) -> None:
    if user["role"] == "doctor":
        return
    if patient_row["user_id"] == user["id"] or patient_row["created_by_user_id"] == user["id"]:
        return
    raise HTTPException(status_code=403, detail="Not authorized for this patient")


@app.get("/patients", response_model=List[PatientOut])
def list_patients(user: Dict[str, Any] = Depends(_current_user)) -> List[PatientOut]:
    with _db_connection() as conn:
        if user["role"] == "doctor":
            rows = conn.execute(
                """
                SELECT id, user_id, created_by_user_id, name, age, gender, phone, notes, created_at
                FROM patients
                ORDER BY id DESC
                """
            ).fetchall()
        else:
            rows = conn.execute(
                """
                SELECT id, user_id, created_by_user_id, name, age, gender, phone, notes, created_at
                FROM patients
                WHERE user_id = ? OR created_by_user_id = ?
                ORDER BY id DESC
                """,
                (user["id"], user["id"]),
            ).fetchall()
    return [
        PatientOut(
            id=row["id"],
            userId=row["user_id"],
            createdByUserId=row["created_by_user_id"],
            name=row["name"],
            age=row["age"],
            gender=row["gender"],
            phone=row["phone"],
            notes=row["notes"],
            createdAt=row["created_at"],
        )
        for row in rows
    ]


@app.get("/patients/{patient_id}", response_model=PatientOut)
def get_patient(patient_id: int, user: Dict[str, Any] = Depends(_current_user)) -> PatientOut:
    with _db_connection() as conn:
        row = conn.execute(
            """
            SELECT id, user_id, created_by_user_id, name, age, gender, phone, notes, created_at
            FROM patients WHERE id = ?
            """,
            (patient_id,),
        ).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Patient not found")
    _assert_patient_access(user, row)
    return PatientOut(
        id=row["id"],
        userId=row["user_id"],
        createdByUserId=row["created_by_user_id"],
        name=row["name"],
        age=row["age"],
        gender=row["gender"],
        phone=row["phone"],
        notes=row["notes"],
        createdAt=row["created_at"],
    )


@app.put("/patients/{patient_id}", response_model=PatientOut)
def update_patient(
    patient_id: int,
    payload: PatientIn,
    user: Dict[str, Any] = Depends(_current_user),
) -> PatientOut:
    with _db_connection() as conn:
        row = conn.execute(
            "SELECT * FROM patients WHERE id = ?",
            (patient_id,),
        ).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail="Patient not found")
        _assert_patient_access(user, row)
        conn.execute(
            """
            UPDATE patients
            SET name = ?, age = ?, gender = ?, phone = ?, notes = ?
            WHERE id = ?
            """,
            (
                payload.name,
                payload.age,
                payload.gender,
                payload.phone,
                payload.notes,
                patient_id,
            ),
        )
        conn.commit()
    return get_patient(patient_id, user)


@app.get("/patients/{patient_id}/history", response_model=List[AnalysisHistoryItem])
def patient_history(patient_id: int, user: Dict[str, Any] = Depends(_current_user)) -> List[AnalysisHistoryItem]:
    with _db_connection() as conn:
        patient = conn.execute("SELECT * FROM patients WHERE id = ?", (patient_id,)).fetchone()
        if patient is None:
            raise HTTPException(status_code=404, detail="Patient not found")
        _assert_patient_access(user, patient)
        rows = conn.execute(
            """
            SELECT analysis_uid, patient_id, created_at, input_type, risk_level,
                   classification, model_score, bpm, signal_quality, model_version
            FROM analyses
            WHERE patient_id = ?
            ORDER BY created_at DESC
            """,
            (patient_id,),
        ).fetchall()
    return [
        AnalysisHistoryItem(
            analysisId=row["analysis_uid"],
            patientId=row["patient_id"],
            createdAt=row["created_at"],
            inputType=row["input_type"],
            riskLevel=row["risk_level"],
            classification=row["classification"],
            modelScore=float(row["model_score"]),
            bpm=int(row["bpm"]),
            signalQuality=row["signal_quality"],
            modelVersion=row["model_version"],
        )
        for row in rows
    ]


@app.get("/patients/{patient_id}/trends", response_model=PatientTrendOut)
def patient_trends(patient_id: int, user: Dict[str, Any] = Depends(_current_user)) -> PatientTrendOut:
    history = patient_history(patient_id, user)
    avg_bpm = round(sum(item.bpm for item in history) / len(history), 2) if history else None
    qualities = [item.signalQuality for item in history if item.signalQuality is not None]
    avg_quality = round(sum(qualities) / len(qualities), 3) if qualities else None
    trend = [
        TrendPoint(
            analysisId=item.analysisId,
            createdAt=item.createdAt,
            bpm=item.bpm,
            riskLevel=item.riskLevel,
            signalQuality=item.signalQuality,
            modelScore=item.modelScore,
        )
        for item in history[:20]
    ]
    return PatientTrendOut(
        patientId=patient_id,
        totalAnalyses=len(history),
        avgBpm=avg_bpm,
        avgSignalQuality=avg_quality,
        trend=trend,
    )


@app.post("/analyze_image", response_model=AnalysisResponse)
async def analyze_image(
    file: UploadFile = File(...),
    patientId: Optional[int] = None,
    user: Optional[Dict[str, Any]] = Depends(_current_user_optional),
) -> AnalysisResponse:
    _validate_upload(file.filename or "upload", ALLOWED_IMAGE_EXTENSIONS)
    with tempfile.TemporaryDirectory() as tmpdir:
        out_path = Path(tmpdir) / Path(file.filename or "image.png").name
        await _save_upload(file, out_path)
        try:
            raw_signal = _image_to_signal(str(out_path))
            processed_signal = ecg_pipeline.preprocess_signal(raw_signal, 100.0)
            fs = 100.0
        except Exception as exc:
            raise HTTPException(status_code=400, detail=f"Image analysis failed: {exc}")
    return _run_signal_analysis(
        raw_signal=raw_signal,
        processed_signal=processed_signal,
        fs=fs,
        lead_names=[f"lead{i + 1}" for i in range(raw_signal.shape[0])],
        recording_id=Path(file.filename or "image").stem,
        patient_id=patientId,
        input_type="image",
        source_filename=file.filename,
    )


@app.post("/analyze_files", response_model=AnalysisResponse)
async def analyze_files(
    files: List[UploadFile] = File(...),
    patientId: Optional[int] = None,
    user: Optional[Dict[str, Any]] = Depends(_current_user_optional),
) -> AnalysisResponse:
    if not files:
        raise HTTPException(status_code=400, detail="No files uploaded")
    with tempfile.TemporaryDirectory() as tmpdir:
        saved_files: List[Path] = []
        for upload in files:
            _validate_upload(upload.filename or "upload", ALLOWED_SIGNAL_EXTENSIONS)
            target = Path(tmpdir) / Path(upload.filename or "signal.dat").name
            await _save_upload(upload, target)
            saved_files.append(target)

        hea_bases = {path.stem for path in saved_files if path.suffix.lower() == ".hea"}
        dat_bases = {path.stem for path in saved_files if path.suffix.lower() == ".dat"}
        matching = sorted(hea_bases.intersection(dat_bases))
        if matching:
            record_path = str(Path(tmpdir) / matching[0])
            try:
                raw_signal, fs, lead_names = ecg_pipeline.load_wfdb_record(record_path)
                processed_signal = ecg_pipeline.preprocess_signal(raw_signal, fs)
            except Exception as exc:
                raise HTTPException(status_code=400, detail=f"ECG load failed: {exc}")
            recording_id = matching[0]
        elif len(saved_files) == 1 and saved_files[0].suffix.lower() in {".csv", ".wav"}:
            try:
                raw_signal, fs, lead_names = _load_single_signal_file(saved_files[0])
                processed_signal = ecg_pipeline.preprocess_signal(raw_signal, fs)
            except Exception as exc:
                raise HTTPException(status_code=400, detail=f"Signal load failed: {exc}")
            recording_id = saved_files[0].stem
        else:
            wfdb_names = [path.name for path in saved_files if path.suffix.lower() in {".hea", ".dat"}]
            if wfdb_names:
                raise HTTPException(
                    status_code=422,
                    detail=(
                        "WFDB analysis needs both .hea and .dat for the same record. "
                        "If you selected only one file, keep the sibling file in the same folder on desktop "
                        "so the app can auto-attach it, or upload the complete pair."
                    ),
                )
            raise HTTPException(
                status_code=422,
                detail="Upload a supported ECG source: matching .hea+.dat, or a single .csv/.wav file.",
            )
    return _run_signal_analysis(
        raw_signal=raw_signal,
        processed_signal=processed_signal,
        fs=fs,
        lead_names=lead_names,
        recording_id=recording_id,
        patient_id=patientId,
        input_type="wfdb" if matching else saved_files[0].suffix.lower().replace(".", ""),
        source_filename=", ".join(path.name for path in saved_files),
    )


@app.post("/ecg/image", response_model=AnalysisResponse)
async def ecg_image(
    file: UploadFile = File(...),
    patientId: Optional[int] = None,
    user: Optional[Dict[str, Any]] = Depends(_current_user_optional),
) -> AnalysisResponse:
    return await analyze_image(file=file, patientId=patientId, user=user)


@app.post("/ecg/file", response_model=AnalysisResponse)
async def ecg_file(
    files: List[UploadFile] = File(...),
    patientId: Optional[int] = None,
    user: Optional[Dict[str, Any]] = Depends(_current_user_optional),
) -> AnalysisResponse:
    return await analyze_files(files=files, patientId=patientId, user=user)


@app.post("/ecg/convert-image-to-wfdb", response_model=WFDBConversionOut)
async def convert_image_to_wfdb(
    request: Request, file: UploadFile = File(...)
) -> WFDBConversionOut:
    _validate_upload(file.filename or "upload", ALLOWED_IMAGE_EXTENSIONS)
    with tempfile.TemporaryDirectory() as tmpdir:
        out_path = Path(tmpdir) / Path(file.filename or "image.png").name
        await _save_upload(file, out_path)
        try:
            return _export_image_to_wfdb_bundle(
                out_path,
                file.filename or "image.png",
                base_url=_public_base_url(request),
            )
        except Exception as exc:
            raise HTTPException(status_code=400, detail=f"WFDB conversion failed: {exc}")


@app.get("/wfdb/{conversion_id}/download")
def download_wfdb_bundle(conversion_id: str) -> FileResponse:
    export_dir = WFDB_EXPORTS_DIR / conversion_id
    zip_path = export_dir / f"{conversion_id}.zip"
    if not zip_path.is_file():
        raise HTTPException(status_code=404, detail="WFDB export not found")
    return FileResponse(zip_path, media_type="application/zip", filename=zip_path.name)


@app.get("/ecg/{analysis_id}", response_model=AnalysisResponse)
def get_ecg_result(
    analysis_id: str, user: Optional[Dict[str, Any]] = Depends(_current_user_optional)
) -> AnalysisResponse:
    return get_analysis(analysis_id, user)


@app.post("/analysis/ecg", response_model=AnalysisStatusOut)
def analysis_entry_stub() -> AnalysisStatusOut:
    raise HTTPException(
        status_code=405,
        detail="Use /ecg/image or /ecg/file for ECG uploads in the current backend.",
    )


@app.get("/analysis/{analysis_id}", response_model=AnalysisResponse)
def get_analysis(
    analysis_id: str, user: Optional[Dict[str, Any]] = Depends(_current_user_optional)
) -> AnalysisResponse:
    with _db_connection() as conn:
        row = conn.execute(
            "SELECT * FROM analyses WHERE analysis_uid = ?",
            (analysis_id,),
        ).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Analysis not found")
    return _analysis_from_db_row(row)


@app.get("/analysis/{analysis_id}/status", response_model=AnalysisStatusOut)
def get_analysis_status(
    analysis_id: str, user: Optional[Dict[str, Any]] = Depends(_current_user_optional)
) -> AnalysisStatusOut:
    with _db_connection() as conn:
        row = conn.execute(
            "SELECT analysis_uid, status, created_at, model_version, pipeline_version FROM analyses WHERE analysis_uid = ?",
            (analysis_id,),
        ).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Analysis not found")
    return AnalysisStatusOut(
        analysisId=row["analysis_uid"],
        status=row["status"],
        createdAt=row["created_at"],
        modelVersion=row["model_version"],
        pipelineVersion=row["pipeline_version"],
    )


@app.post("/monitoring/start", response_model=MonitoringSessionOut)
def monitoring_start(
    payload: MonitoringStartIn, user: Dict[str, Any] = Depends(_current_user)
) -> MonitoringSessionOut:
    session_uid = uuid.uuid4().hex
    started_at = datetime.utcnow().isoformat()
    with _db_connection() as conn:
        conn.execute(
            """
            INSERT INTO monitoring_sessions (session_uid, patient_id, mode, status, notes, started_at, stopped_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (session_uid, payload.patientId, payload.mode, "running", payload.notes, started_at, None),
        )
        conn.commit()
    return MonitoringSessionOut(
        sessionId=session_uid,
        patientId=payload.patientId,
        mode=payload.mode,
        status="running",
        notes=payload.notes,
        startedAt=started_at,
        stoppedAt=None,
    )


@app.post("/monitoring/stop", response_model=MonitoringSessionOut)
def monitoring_stop(
    payload: MonitoringStopIn, user: Dict[str, Any] = Depends(_current_user)
) -> MonitoringSessionOut:
    stopped_at = datetime.utcnow().isoformat()
    with _db_connection() as conn:
        row = conn.execute(
            "SELECT * FROM monitoring_sessions WHERE session_uid = ?",
            (payload.sessionId,),
        ).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail="Monitoring session not found")
        conn.execute(
            """
            UPDATE monitoring_sessions
            SET status = ?, notes = ?, stopped_at = ?
            WHERE session_uid = ?
            """,
            ("stopped", payload.notes or row["notes"], stopped_at, payload.sessionId),
        )
        conn.commit()
        updated = conn.execute(
            "SELECT * FROM monitoring_sessions WHERE session_uid = ?",
            (payload.sessionId,),
        ).fetchone()
    return MonitoringSessionOut(
        sessionId=updated["session_uid"],
        patientId=updated["patient_id"],
        mode=updated["mode"],
        status=updated["status"],
        notes=updated["notes"],
        startedAt=updated["started_at"],
        stoppedAt=updated["stopped_at"],
    )


@app.get("/monitoring/{patient_id}", response_model=List[MonitoringSessionOut])
def monitoring_for_patient(
    patient_id: int, user: Dict[str, Any] = Depends(_current_user)
) -> List[MonitoringSessionOut]:
    with _db_connection() as conn:
        rows = conn.execute(
            """
            SELECT * FROM monitoring_sessions
            WHERE patient_id = ?
            ORDER BY started_at DESC
            """,
            (patient_id,),
        ).fetchall()
    return [
        MonitoringSessionOut(
            sessionId=row["session_uid"],
            patientId=row["patient_id"],
            mode=row["mode"],
            status=row["status"],
            notes=row["notes"],
            startedAt=row["started_at"],
            stoppedAt=row["stopped_at"],
        )
        for row in rows
    ]


@app.post("/emergency", response_model=EmergencyOut)
def emergency(payload: EmergencyIn) -> EmergencyOut:
    created_at = datetime.utcnow().isoformat()
    with _db_connection() as conn:
        cur = conn.execute(
            """
            INSERT INTO emergencies (patient_name, latitude, longitude, created_at)
            VALUES (?, ?, ?, ?)
            """,
            (payload.patientName, payload.latitude, payload.longitude, created_at),
        )
        conn.commit()
        emergency_id = cur.lastrowid
    return EmergencyOut(
        id=emergency_id,
        patientName=payload.patientName,
        latitude=payload.latitude,
        longitude=payload.longitude,
        createdAt=created_at,
    )


@app.get("/emergencies", response_model=List[EmergencyOut])
def list_emergencies(user: Dict[str, Any] = Depends(_current_user)) -> List[EmergencyOut]:
    with _db_connection() as conn:
        rows = conn.execute(
            "SELECT id, patient_name, latitude, longitude, created_at FROM emergencies ORDER BY id DESC"
        ).fetchall()
    return [
        EmergencyOut(
            id=row["id"],
            patientName=row["patient_name"],
            latitude=row["latitude"],
            longitude=row["longitude"],
            createdAt=row["created_at"],
        )
        for row in rows
    ]


@app.get("/stats", response_model=StatsOut)
def stats(user: Dict[str, Any] = Depends(_current_user)) -> StatsOut:
    with _db_connection() as conn:
        patients = conn.execute("SELECT COUNT(*) AS count FROM patients").fetchone()["count"]
        emergencies = conn.execute("SELECT COUNT(*) AS count FROM emergencies").fetchone()["count"]
        messages = conn.execute("SELECT COUNT(*) AS count FROM messages").fetchone()["count"]
    return StatsOut(patients=patients, emergencies=emergencies, messages=messages)


@app.get("/messages", response_model=List[MessageOut])
def list_messages(patientId: int, user: Dict[str, Any] = Depends(_current_user)) -> List[MessageOut]:
    with _db_connection() as conn:
        rows = conn.execute(
            """
            SELECT id, patient_id, sender_role, sender_name, text, created_at
            FROM messages
            WHERE patient_id = ?
            ORDER BY id DESC
            LIMIT 50
            """,
            (patientId,),
        ).fetchall()
    return [
        MessageOut(
            id=row["id"],
            patientId=row["patient_id"],
            senderRole=row["sender_role"],
            senderName=row["sender_name"],
            text=row["text"],
            createdAt=row["created_at"],
        )
        for row in rows
    ]


@app.post("/messages", response_model=MessageOut)
def create_message(payload: MessageIn, user: Dict[str, Any] = Depends(_current_user)) -> MessageOut:
    created_at = datetime.utcnow().isoformat()
    with _db_connection() as conn:
        cur = conn.execute(
            """
            INSERT INTO messages (patient_id, sender_role, sender_name, text, created_at)
            VALUES (?, ?, ?, ?, ?)
            """,
            (payload.patientId, payload.senderRole, payload.senderName, payload.text, created_at),
        )
        conn.commit()
        message_id = cur.lastrowid
    return MessageOut(
        id=message_id,
        patientId=payload.patientId,
        senderRole=payload.senderRole,
        senderName=payload.senderName,
        text=payload.text,
        createdAt=created_at,
    )


@app.get("/appointments", response_model=List[AppointmentOut])
def list_appointments(
    patientId: Optional[int] = None,
    user: Dict[str, Any] = Depends(_current_user),
) -> List[AppointmentOut]:
    query = """
        SELECT id, patient_id, doctor_name, when_at, status, notes, created_at
        FROM appointments
    """
    params: List[Any] = []
    if patientId is not None:
        query += " WHERE patient_id = ?"
        params.append(patientId)
    query += " ORDER BY id DESC"
    with _db_connection() as conn:
        rows = conn.execute(query, params).fetchall()
    return [
        AppointmentOut(
            id=row["id"],
            patientId=row["patient_id"],
            doctorName=row["doctor_name"],
            when=row["when_at"],
            status=row["status"],
            notes=row["notes"],
            createdAt=row["created_at"],
        )
        for row in rows
    ]


@app.post("/appointments", response_model=AppointmentOut)
def create_appointment(
    payload: AppointmentIn, user: Dict[str, Any] = Depends(_current_user)
) -> AppointmentOut:
    created_at = datetime.utcnow().isoformat()
    with _db_connection() as conn:
        cur = conn.execute(
            """
            INSERT INTO appointments (patient_id, doctor_name, when_at, status, notes, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                payload.patientId,
                payload.doctorName,
                payload.when,
                payload.status,
                payload.notes,
                created_at,
            ),
        )
        appointment_id = cur.lastrowid
        conn.commit()
    return AppointmentOut(
        id=appointment_id,
        patientId=payload.patientId,
        doctorName=payload.doctorName,
        when=payload.when,
        status=payload.status,
        notes=payload.notes,
        createdAt=created_at,
    )


@app.post("/reports/generate", response_model=ReportOut)
def generate_report(
    payload: GenerateReportIn,
    user: Optional[Dict[str, Any]] = Depends(_current_user_optional),
) -> ReportOut:
    if not payload.analysisId and payload.patientId is None:
        raise HTTPException(status_code=422, detail="analysisId or patientId is required")
    analysis: Optional[AnalysisResponse] = None
    if payload.analysisId:
        analysis = get_analysis(payload.analysisId, user)
    elif payload.patientId is not None:
        history = patient_history(payload.patientId, user)
        if not history:
            raise HTTPException(status_code=404, detail="No analyses found for this patient")
        analysis = get_analysis(history[0].analysisId, user)
    if analysis is None:
        raise HTTPException(status_code=404, detail="Analysis not found")
    report = _store_report(analysis=analysis, patient_id=analysis.patientId)
    labels, bpm, risk_levels = _report_trend(analysis.patientId or 0) if analysis.patientId else ([], [], [])
    report.labels = labels
    report.bpm = bpm
    report.riskLevels = risk_levels
    return report


@app.get("/reports/patient/{patient_id}", response_model=ReportOut)
def get_patient_report(
    patient_id: int, user: Optional[Dict[str, Any]] = Depends(_current_user_optional)
) -> ReportOut:
    history = patient_history(patient_id, user)
    if not history:
        raise HTTPException(status_code=404, detail="No analyses found for this patient")
    latest_analysis = get_analysis(history[0].analysisId, user)
    with _db_connection() as conn:
        row = conn.execute(
            """
            SELECT report_uid, analysis_uid, patient_id, file_path, created_at
            FROM reports
            WHERE patient_id = ?
            ORDER BY created_at DESC
            LIMIT 1
            """,
            (patient_id,),
        ).fetchone()
    if row is None:
        report = _store_report(analysis=latest_analysis, patient_id=patient_id)
    else:
        report = ReportOut(
            reportId=row["report_uid"],
            analysisId=row["analysis_uid"],
            patientId=row["patient_id"],
            filePath=row["file_path"],
            createdAt=row["created_at"],
        )
    labels, bpm, risk_levels = _report_trend(patient_id)
    report.labels = labels
    report.bpm = bpm
    report.riskLevels = risk_levels
    return report


@app.get("/reports/{report_id}", response_model=ReportOut)
def get_report(
    report_id: str, user: Optional[Dict[str, Any]] = Depends(_current_user_optional)
) -> ReportOut:
    with _db_connection() as conn:
        row = conn.execute(
            "SELECT report_uid, analysis_uid, patient_id, file_path, created_at FROM reports WHERE report_uid = ?",
            (report_id,),
        ).fetchone()
    if row is None and report_id.isdigit():
        return get_patient_report(int(report_id), user)
    if row is None:
        raise HTTPException(status_code=404, detail="Report not found")
    labels, bpm, risk_levels = _report_trend(row["patient_id"] or 0) if row["patient_id"] else ([], [], [])
    return ReportOut(
        reportId=row["report_uid"],
        analysisId=row["analysis_uid"],
        patientId=row["patient_id"],
        filePath=row["file_path"],
        createdAt=row["created_at"],
        labels=labels,
        bpm=bpm,
        riskLevels=risk_levels,
    )


@app.get("/reports/{report_id}/download")
def download_report(
    report_id: str, user: Optional[Dict[str, Any]] = Depends(_current_user_optional)
) -> FileResponse:
    report = get_report(report_id, user)
    file_path = Path(report.filePath)
    if not file_path.is_file():
        raise HTTPException(status_code=404, detail="Report file not found")
    return FileResponse(file_path, media_type="application/pdf", filename=file_path.name)


@app.get("/reports/export")
def export_report(
    user: Optional[Dict[str, Any]] = Depends(_current_user_optional)
) -> StreamingResponse:
    with _db_connection() as conn:
        row = conn.execute(
            """
            SELECT analysis_uid
            FROM analyses
            ORDER BY created_at DESC
            LIMIT 1
            """
        ).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="No analysis available to export")
    analysis = get_analysis(row["analysis_uid"], user)
    report = _store_report(analysis=analysis, patient_id=analysis.patientId)
    file_path = Path(report.filePath)
    buffer = io.BytesIO(file_path.read_bytes())
    return StreamingResponse(
        buffer,
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename={file_path.name}"},
    )


if (WEB_BUILD_DIR / "assets").is_dir():
    app.mount("/assets", StaticFiles(directory=WEB_BUILD_DIR / "assets"), name="web-assets")


@app.get("/", include_in_schema=False)
def serve_web_root() -> FileResponse:
    index_path = WEB_BUILD_DIR / "index.html"
    if not index_path.is_file():
        raise HTTPException(status_code=404, detail="Web build not found")
    return FileResponse(
        index_path,
        headers={
            "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
            "Pragma": "no-cache",
            "Expires": "0",
        },
    )


@app.get("/{full_path:path}", include_in_schema=False)
def serve_web_or_asset(full_path: str) -> FileResponse:
    index_path = WEB_BUILD_DIR / "index.html"
    if not index_path.is_file():
        raise HTTPException(status_code=404, detail="Web build not found")

    requested = (WEB_BUILD_DIR / full_path).resolve()
    try:
        requested.relative_to(WEB_BUILD_DIR.resolve())
    except ValueError as exc:
        raise HTTPException(status_code=404, detail="Asset not found") from exc

    if requested.is_file():
        return FileResponse(requested)

    blocked_prefixes = {
        "auth",
        "patients",
        "emergencies",
        "messages",
        "appointments",
        "dashboard",
        "analyze_image",
        "analyze_files",
        "ecg",
        "wfdb",
        "analyses",
        "reports",
        "health",
    }
    first_segment = full_path.split("/", 1)[0]
    if "." in full_path or first_segment in blocked_prefixes:
        raise HTTPException(status_code=404, detail="Resource not found")
    return FileResponse(
        index_path,
        headers={
            "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
            "Pragma": "no-cache",
            "Expires": "0",
        },
    )
