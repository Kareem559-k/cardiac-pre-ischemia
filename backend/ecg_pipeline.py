from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Optional

import joblib
import numpy as np
import wfdb
from scipy.fft import fft
from scipy.signal import butter, filtfilt, find_peaks, iirnotch, peak_widths
from scipy.stats import kurtosis, skew


EXPECTED_FEATURES = 300
DEFAULT_FS = 100.0
LOW_CUTOFF_HZ = 0.5
HIGH_CUTOFF_HZ = 40.0
FILTER_ORDER = 3


@dataclass
class ArtifactBundle:
    model_version: str
    model: Any
    imputer: Any
    scaler: Any
    threshold: float
    package_dir: Path
    metadata: dict[str, Any]


def model_paths(model_dir: Path) -> dict[str, Path]:
    return {
        "model": model_dir / "model_v15_final.pkl",
        "imputer": model_dir / "imputer_v15_final.pkl",
        "scaler": model_dir / "scaler_v15_final.pkl",
        "threshold": model_dir / "threshold_v15_final.npy",
        "metadata": model_dir / "model_metadata.json",
        "feature_schema": model_dir / "feature_schema.json",
        "preprocessing": model_dir / "preprocessing_config.json",
        "validation": model_dir / "validation_results.json",
    }


def load_bundle(model_dir: Path) -> ArtifactBundle:
    paths = model_paths(model_dir)
    metadata = json.loads(paths["metadata"].read_text(encoding="utf-8"))
    return ArtifactBundle(
        model_version=metadata["model_version"],
        model=joblib.load(paths["model"]),
        imputer=joblib.load(paths["imputer"]),
        scaler=joblib.load(paths["scaler"]),
        threshold=float(np.load(paths["threshold"])),
        package_dir=model_dir,
        metadata=metadata,
    )


def ensure_lead_first(signal: np.ndarray) -> np.ndarray:
    arr = np.asarray(signal, dtype=np.float32)
    if arr.ndim == 1:
        return arr.reshape(1, -1)
    if arr.ndim != 2:
        raise ValueError("Signal must be 1D or 2D.")
    if arr.shape[0] <= arr.shape[1]:
        return arr
    return arr.T


def load_wfdb_record(record_path: str | Path) -> tuple[np.ndarray, float, list[str]]:
    record = wfdb.rdrecord(str(record_path))
    signal = np.asarray(record.p_signal, dtype=np.float32)
    if signal.ndim != 2:
        raise ValueError("WFDB signal is expected to be 2D.")
    lead_names = list(getattr(record, "sig_name", []) or [])
    return signal.T, float(record.fs), lead_names


def _butter_bandpass(lowcut: float, highcut: float, fs: float, order: int = FILTER_ORDER):
    nyquist = 0.5 * fs
    low = lowcut / nyquist
    high = highcut / nyquist
    return butter(order, [low, high], btype="band")


def _apply_bandpass(signal: np.ndarray, fs: float) -> np.ndarray:
    b, a = _butter_bandpass(LOW_CUTOFF_HZ, HIGH_CUTOFF_HZ, fs)
    return filtfilt(b, a, signal, axis=-1)


def _apply_notch(signal: np.ndarray, fs: float, freq: float = 50.0, quality: float = 30.0) -> np.ndarray:
    if fs <= (2 * freq):
        return signal
    b, a = iirnotch(freq, quality, fs)
    return filtfilt(b, a, signal, axis=-1)


def preprocess_signal(signal: np.ndarray, fs: float, apply_notch: bool = True) -> np.ndarray:
    lead_first = ensure_lead_first(signal)
    filtered = _apply_bandpass(lead_first, fs)
    if apply_notch:
        filtered = _apply_notch(filtered, fs)
    mean = filtered.mean(axis=1, keepdims=True)
    std = filtered.std(axis=1, keepdims=True)
    std[std == 0] = 1.0
    return ((filtered - mean) / std).astype(np.float32)


def representative_lead(signal: np.ndarray, fs: float | None = None) -> np.ndarray:
    lead_first = ensure_lead_first(signal)
    if lead_first.shape[0] == 1:
        return lead_first[0]

    effective_fs = float(fs) if fs and fs > 0 else DEFAULT_FS
    best_idx = 0
    best_score = -np.inf
    for idx, lead in enumerate(lead_first):
        lead_std = float(np.std(lead))
        if lead_std <= 1e-6:
            continue
        peaks, props = find_peaks(
            lead,
            distance=max(int(0.25 * effective_fs), 1),
            prominence=max(0.30 * lead_std, 0.12),
        )
        peak_count = float(len(peaks))
        peak_prom = float(np.mean(props["prominences"])) if len(peaks) and "prominences" in props else 0.0
        abs_amp = float(np.max(np.abs(lead))) if lead.size else 0.0
        score = (peak_count * 0.45) + (peak_prom * 1.7) + (lead_std * 0.9) + (abs_amp * 0.35)
        if score > best_score:
            best_score = score
            best_idx = idx
    return lead_first[best_idx]


def detect_r_peaks(signal_1d: np.ndarray, fs: float) -> np.ndarray:
    distance = max(int(0.25 * fs), 1)
    prominence = max(0.35 * float(np.std(signal_1d)), 0.15)
    peaks, _ = find_peaks(signal_1d, distance=distance, prominence=prominence)
    return peaks.astype(int)


def compute_rr_hrv(peaks: np.ndarray, fs: float) -> dict[str, float | None]:
    if len(peaks) < 2:
        return {
            "heart_rate_bpm": None,
            "rr_mean_ms": None,
            "rr_std_ms": None,
            "sdnn_ms": None,
            "rmssd_ms": None,
            "pnn50_pct": None,
        }
    rr_sec = np.diff(peaks) / fs
    rr_diff_sec = np.diff(rr_sec)
    heart_rate = 60.0 / np.mean(rr_sec) if np.mean(rr_sec) > 0 else None
    pnn50 = float(np.mean(np.abs(rr_diff_sec) > 0.05) * 100.0) if len(rr_diff_sec) else 0.0
    rmssd = float(np.sqrt(np.mean(rr_diff_sec**2))) * 1000.0 if len(rr_diff_sec) else 0.0
    return {
        "heart_rate_bpm": float(heart_rate) if heart_rate is not None else None,
        "rr_mean_ms": float(np.mean(rr_sec) * 1000.0),
        "rr_std_ms": float(np.std(rr_sec) * 1000.0),
        "sdnn_ms": float(np.std(rr_sec) * 1000.0),
        "rmssd_ms": rmssd,
        "pnn50_pct": pnn50,
    }


def estimate_qrs_duration_ms(signal_1d: np.ndarray, peaks: np.ndarray, fs: float) -> float | None:
    if len(peaks) < 2:
        return None
    widths, _, _, _ = peak_widths(signal_1d, peaks, rel_height=0.5)
    if len(widths) == 0:
        return None
    return float(np.median(widths) / fs * 1000.0)


def _nearest_baseline_index(
    signal_1d: np.ndarray, start: int, end: int, baseline: float, threshold: float
) -> Optional[int]:
    start = max(0, start)
    end = min(len(signal_1d), end)
    for idx in range(start, end):
        if abs(float(signal_1d[idx]) - baseline) <= threshold:
            return idx
    return None


def estimate_wave_intervals(signal_1d: np.ndarray, peaks: np.ndarray, fs: float) -> dict[str, Any]:
    if len(peaks) < 3:
        return {
            "pr_interval_ms_estimate": None,
            "qt_interval_ms_estimate": None,
            "qtc_bazett_ms_estimate": None,
            "st_deviation_estimate": None,
            "p_wave_detection": None,
            "t_wave_detection": None,
            "interval_method": "Unavailable: insufficient beats for waveform interval estimation.",
        }

    signal_1d = np.asarray(signal_1d, dtype=np.float32)
    signal_ptp = float(np.ptp(signal_1d)) + 1e-6
    baseline_threshold = max(0.04 * signal_ptp, 0.03)
    pr_values: list[float] = []
    qt_values: list[float] = []
    qtc_values: list[float] = []
    st_values: list[float] = []
    p_positions: list[int] = []
    t_positions: list[int] = []

    for i in range(1, len(peaks) - 1):
        r = int(peaks[i])
        prev_r = int(peaks[i - 1])
        next_r = int(peaks[i + 1])
        rr_sec = (next_r - r) / fs
        if rr_sec <= 0:
            continue
        baseline_start = max(prev_r + int(0.06 * fs), 0)
        baseline_end = max(r - int(0.10 * fs), baseline_start + 2)
        baseline_window = signal_1d[baseline_start:baseline_end]
        baseline = float(np.median(baseline_window)) if len(baseline_window) else 0.0

        p_start = max(r - int(0.28 * fs), 0)
        p_end = max(r - int(0.08 * fs), p_start + 2)
        p_window = signal_1d[p_start:p_end]
        if len(p_window) < 3:
            continue
        p_rel = int(np.argmax(np.abs(p_window - baseline)))
        p_peak = p_start + p_rel
        p_amp = abs(float(signal_1d[p_peak]) - baseline)
        if p_amp < 0.05 * signal_ptp:
            continue
        p_onset = None
        for idx in range(p_peak, p_start, -1):
            if abs(float(signal_1d[idx]) - baseline) <= baseline_threshold:
                p_onset = idx
                break
        if p_onset is None:
            p_onset = p_start

        qrs_left = max(r - int(0.08 * fs), 0)
        qrs_right = min(r + int(0.10 * fs), len(signal_1d))
        qrs_window = signal_1d[qrs_left:qrs_right]
        qrs_dev = np.abs(qrs_window - baseline)
        above = np.where(qrs_dev >= max(0.08 * signal_ptp, baseline_threshold))[0]
        if len(above) == 0:
            continue
        qrs_onset = qrs_left + int(above[0])
        qrs_end = qrs_left + int(above[-1])
        if qrs_end <= qrs_onset:
            continue

        t_start = min(r + int(0.10 * fs), len(signal_1d) - 2)
        t_end = min(r + int(0.50 * fs), len(signal_1d))
        t_window = signal_1d[t_start:t_end]
        if len(t_window) < 3:
            continue
        t_rel = int(np.argmax(np.abs(t_window - baseline)))
        t_peak = t_start + t_rel
        t_amp = abs(float(signal_1d[t_peak]) - baseline)
        if t_amp < 0.05 * signal_ptp:
            continue
        t_end_idx = _nearest_baseline_index(
            signal_1d,
            start=t_peak,
            end=min(t_peak + int(0.22 * fs), len(signal_1d)),
            baseline=baseline,
            threshold=baseline_threshold,
        )
        if t_end_idx is None:
            continue

        st_index = min(qrs_end + int(0.08 * fs), len(signal_1d) - 1)
        st_deviation = float(signal_1d[st_index] - baseline)

        pr_ms = (qrs_onset - p_onset) / fs * 1000.0
        qt_ms = (t_end_idx - qrs_onset) / fs * 1000.0
        qtc_ms = qt_ms / np.sqrt(rr_sec)

        if 60 <= pr_ms <= 320:
            pr_values.append(pr_ms)
        if 200 <= qt_ms <= 600:
            qt_values.append(qt_ms)
            qtc_values.append(qtc_ms)
        if abs(st_deviation) <= 2.5 * signal_ptp:
            st_values.append(st_deviation)

        p_positions.append(p_peak)
        t_positions.append(t_peak)

    return {
        "pr_interval_ms_estimate": float(np.median(pr_values)) if pr_values else None,
        "qt_interval_ms_estimate": float(np.median(qt_values)) if qt_values else None,
        "qtc_bazett_ms_estimate": float(np.median(qtc_values)) if qtc_values else None,
        "st_deviation_estimate": float(np.median(st_values)) if st_values else None,
        "p_wave_detection": {
            "count": int(len(p_positions)),
            "indices": [int(x) for x in p_positions[:30]],
        }
        if p_positions
        else None,
        "t_wave_detection": {
            "count": int(len(t_positions)),
            "indices": [int(x) for x in t_positions[:30]],
        }
        if t_positions
        else None,
        "interval_method": "Estimated from waveform heuristics on the representative lead; experimental and not clinically validated.",
    }


def signal_quality_metrics(raw_signal: np.ndarray, processed_signal: np.ndarray, fs: float) -> dict[str, Any]:
    raw = ensure_lead_first(raw_signal)
    processed = ensure_lead_first(processed_signal)
    rep_raw = representative_lead(raw, fs)
    rep_proc = representative_lead(processed, fs)

    kernel = max(int(fs * 0.8), 3)
    if kernel % 2 == 0:
        kernel += 1
    baseline = np.convolve(rep_raw, np.ones(kernel) / kernel, mode="same")
    baseline_ratio = float(np.std(baseline) / (np.std(rep_raw) + 1e-8))
    noise_component = rep_raw - rep_proc
    noise_ratio = float(np.std(noise_component) / (np.std(rep_raw) + 1e-8))
    raw_peak = float(np.max(np.abs(rep_raw))) if rep_raw.size else 0.0
    clipping_ratio = float(np.mean(np.abs(rep_raw) >= 0.99 * raw_peak)) if raw_peak > 0 else 0.0
    nan_ratio = float(np.mean(~np.isfinite(rep_raw)))

    score = 100.0
    score -= min(noise_ratio * 50.0, 35.0)
    score -= min(baseline_ratio * 35.0, 30.0)
    score -= clipping_ratio * 100.0
    score -= nan_ratio * 100.0
    score = float(np.clip(score, 0.0, 100.0))

    quality_reasons: list[str] = []
    if baseline_ratio > 0.35:
        quality_reasons.append("elevated baseline wander")
    if noise_ratio > 0.45:
        quality_reasons.append("high-frequency noise contamination")
    if clipping_ratio > 0.02:
        quality_reasons.append("possible clipping or saturation")
    if nan_ratio > 0.0:
        quality_reasons.append("missing or invalid samples detected")

    if score >= 80:
        noise_level = "Low"
    elif score >= 55:
        noise_level = "Medium"
    else:
        noise_level = "High"
        if not quality_reasons:
            quality_reasons.append("overall signal quality below reliable interval-analysis threshold")

    return {
        "signal_quality_score": round(score, 2),
        "signal_quality_class": noise_level.upper(),
        "noise_level": noise_level,
        "baseline_wander_ratio": round(baseline_ratio, 4),
        "noise_ratio": round(noise_ratio, 4),
        "clipping_ratio": round(clipping_ratio, 4),
        "nan_ratio": round(nan_ratio, 4),
        "quality_reasons": quality_reasons,
    }


def classify_rhythm(
    hr_bpm: float | None, rr_std_ms: float | None, pnn50_pct: float | None, quality_score: float
) -> Optional[str]:
    if hr_bpm is None:
        return None
    if quality_score < 50:
        return "Uncertain rhythm due to low signal quality"
    if hr_bpm < 60:
        return "Bradycardic rhythm"
    if hr_bpm > 100:
        return "Tachycardic rhythm"
    if (rr_std_ms is not None and rr_std_ms > 120) or (pnn50_pct is not None and pnn50_pct > 20):
        return "Irregular rhythm detected"
    return "Regular rhythm pattern"


def extract_model_features(signal: np.ndarray, fs: float) -> np.ndarray:
    lead_first = ensure_lead_first(signal)
    features: list[float] = []
    for lead in lead_first:
        features.extend(
            [
                float(np.mean(lead)),
                float(np.std(lead)),
                float(skew(lead)),
                float(kurtosis(lead)),
            ]
        )
        n = len(lead)
        fft_values = fft(lead)
        fft_amplitudes = np.abs(fft_values[: n // 2])
        fft_subset = fft_amplitudes[:20]
        if len(fft_subset) < 20:
            fft_subset = np.pad(fft_subset, (0, 20 - len(fft_subset)), mode="constant")
        features.extend(float(x) for x in fft_subset)

    rep = representative_lead(lead_first, fs)
    peaks = detect_r_peaks(rep, fs)
    features.append(float(len(peaks)))
    rr = compute_rr_hrv(peaks, fs)
    if rr["rr_mean_ms"] is None:
        features.extend([0.0, 0.0, 0.0, 0.0])
    else:
        features.extend(
            [
                float(rr["rr_mean_ms"]) / 1000.0,
                float(rr["rr_std_ms"]) / 1000.0,
                float(rr["rmssd_ms"]) / 1000.0,
                float(rr["pnn50_pct"]),
            ]
        )

    if len(features) < EXPECTED_FEATURES:
        features.extend([0.0] * (EXPECTED_FEATURES - len(features)))
    return np.asarray(features[:EXPECTED_FEATURES], dtype=np.float32)


def predict_probability(model_artifact: Any, transformed_features: np.ndarray) -> float:
    if hasattr(model_artifact, "predict_proba"):
        return float(model_artifact.predict_proba(transformed_features)[0, 1])
    if isinstance(model_artifact, dict):
        stack_model = model_artifact.get("stack_model")
        platt_scaler = model_artifact.get("platt_scaler")
        if stack_model is None or platt_scaler is None:
            raise ValueError("Model dictionary is missing stack_model or platt_scaler.")
        raw_prob = np.clip(float(stack_model.predict_proba(transformed_features)[0, 1]), 1e-6, 1.0 - 1e-6)
        logit = np.log(raw_prob / (1.0 - raw_prob))
        return float(platt_scaler.predict_proba(np.array([[logit]], dtype=np.float64))[0, 1])
    raise TypeError("Unsupported model artifact type.")


def risk_band(probability: float, threshold: float) -> str:
    low_cut = max(0.20, threshold - 0.20)
    if probability < low_cut:
        return "Low"
    if probability < threshold:
        return "Medium"
    return "High"


def recommended_action(risk_level: str, quality_score: float) -> str:
    if quality_score < 50:
        return "Repeat acquisition and check electrode contact."
    if risk_level == "Low":
        return "Continue monitoring."
    if risk_level == "Medium":
        return "Review ECG trend and consider clinician follow-up."
    return "Immediate clinical evaluation recommended."


def explain_top_features(feature_vector: np.ndarray, count: int = 5) -> list[dict[str, float]]:
    idx = np.argsort(np.abs(feature_vector))[::-1][:count]
    return [{"feature_index": int(i), "feature_value": float(feature_vector[i])} for i in idx]


def region_and_coils(signal: np.ndarray, risk_level: str) -> tuple[str, list[str]]:
    if risk_level == "Low":
        return "Undetermined", []
    lead_first = ensure_lead_first(signal)
    if lead_first.shape[0] < 12:
        return "Undetermined", []
    lead_strength = np.asarray(
        [float(np.std(lead) + 0.35 * np.max(np.abs(lead))) for lead in lead_first[:12]],
        dtype=np.float32,
    )
    groups = {
        "Inferior": [1, 2, 5],
        "Septal": [6, 7],
        "Anterior": [8, 9],
        "Lateral": [0, 4, 10, 11],
    }
    scores = {
        name: float(np.mean([lead_strength[idx] for idx in indices if idx < len(lead_strength)]))
        for name, indices in groups.items()
    }
    ordered = sorted(scores.items(), key=lambda item: item[1], reverse=True)
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


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()
