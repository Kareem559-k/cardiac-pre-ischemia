from __future__ import annotations

from datetime import datetime
from typing import Any

import numpy as np


def _fmt(value: object, suffix: str = "", digits: int = 2) -> str:
    if value is None:
        return "-"
    if isinstance(value, (int, np.integer)):
        return f"{int(value)}{suffix}"
    if isinstance(value, (float, np.floating)):
        if not np.isfinite(float(value)):
            return "-"
        return f"{float(value):.{digits}f}{suffix}"
    return str(value)


def _quality_status(score: float | None) -> str:
    if score is None:
        return "-"
    if score >= 80:
        return "GOOD"
    if score >= 55:
        return "FAIR"
    return "POOR"


def _duration(samples: int | None, fs: float | None) -> str:
    if not samples or not fs:
        return "-"
    total = int(round(samples / fs))
    return f"{total // 60:02d}:{total % 60:02d}"


def _screening_status(risk_level: str | None) -> str:
    if risk_level == "Low":
        return "NORMAL"
    if risk_level == "Medium":
        return "MONITOR"
    if risk_level == "High":
        return "ELEVATED"
    return "-"


def build_report_data(context: dict[str, Any]) -> dict[str, Any]:
    analysis = context["analysis"]
    meta = context.get("meta", {})
    freq = context.get("freq_metrics", {})
    rr_ms = np.asarray(context.get("rr_ms", []), dtype=np.float32)
    warnings = list(context.get("quality_warnings", []))
    evidence_rows = list(context.get("evidence_rows", []))
    next_steps = list(context.get("next_steps", []))
    priority = context.get("priority", "-")

    clinical = analysis.get("supported_clinical_outputs", {})
    model = analysis.get("model_inference", {})

    patient_information = {
        "patient_id": meta.get("patient_id"),
        "age": meta.get("age"),
        "sex": meta.get("sex"),
    }
    recording_information = {
        "recording_id": analysis.get("record_id"),
        "recording_date": meta.get("recording_date"),
        "recording_time": meta.get("recording_time"),
        "duration": _duration(
            analysis.get("num_samples"), analysis.get("sampling_rate_hz")
        ),
        "sampling_rate_hz": analysis.get("sampling_rate_hz"),
        "num_leads": analysis.get("num_leads"),
        "lead_names": list(meta.get("lead_names") or []),
        "signal_quality": clinical.get("signal_quality_score"),
        "signal_quality_status": _quality_status(
            clinical.get("signal_quality_score")
        ),
    }
    measurements = {
        "heart_rate_bpm": clinical.get("heart_rate_bpm"),
        "rr_interval_ms": clinical.get("rr_interval_ms"),
        "pr_interval_ms_estimate": clinical.get("pr_interval_ms_estimate"),
        "qrs_duration_ms_estimate": clinical.get("qrs_duration_ms_estimate"),
        "qt_interval_ms_estimate": clinical.get("qt_interval_ms_estimate"),
        "qtc_bazett_ms_estimate": clinical.get("qtc_bazett_ms_estimate"),
        "st_deviation_estimate": clinical.get("st_deviation_estimate"),
        "heart_rhythm_classification": clinical.get(
            "heart_rhythm_classification"
        ),
    }
    hrv = {
        "sdnn_ms": clinical.get("heart_rate_variability", {}).get("sdnn_ms"),
        "rmssd_ms": clinical.get("heart_rate_variability", {}).get("rmssd_ms"),
        "pnn50_pct": clinical.get("heart_rate_variability", {}).get("pnn50_pct"),
        "rr_series_ms": rr_ms.tolist(),
    }
    signal_quality = {
        "score": clinical.get("signal_quality_score"),
        "status": _quality_status(clinical.get("signal_quality_score")),
        "noise_level": clinical.get("noise_detection"),
        "baseline_wander_ratio": clinical.get("baseline_wander_ratio"),
        "noise_ratio": clinical.get("noise_ratio"),
        "clipping_ratio": clinical.get("clipping_ratio"),
    }
    frequency_analysis = {
        "available": bool(freq.get("available")),
        "spectral_entropy": freq.get("spectral_entropy"),
        "dominant_frequency_hz": freq.get("dominant_frequency_hz"),
        "band_energy": dict(freq.get("band_energy", {})),
        "freqs": list(freq.get("freqs", [])),
        "power": list(freq.get("power", [])),
    }
    explainability = {
        "top_features": list(
            model.get("explainable_ai", {}).get("top_features", [])
        ),
    }
    ai_result = {
        "classification": model.get("disease_classification"),
        "model_score_pct": model.get("pre_stroke_risk_score"),
        "decision_threshold": model.get("model_threshold"),
        "screening_status": _screening_status(model.get("risk_level")),
        "recommended_action": model.get("recommended_action"),
        "model_name": model.get("model_name"),
        "inference_mode": model.get("inference_mode"),
        "raw_probability": model.get("raw_probability"),
        "calibrated_probability": model.get("calibrated_probability"),
        "fallback_reason": model.get("fallback_reason"),
    }

    clinical_summary = [
        f"Overall result: {_fmt(ai_result['classification'])} ({_fmt(ai_result['model_score_pct'], '%')}).",
        f"Inference mode: {_fmt(ai_result['inference_mode'])}; raw probability {_fmt(ai_result['raw_probability'])}; calibrated {_fmt(ai_result['calibrated_probability'])}.",
        f"Signal reliability: {recording_information['signal_quality_status']} ({_fmt(signal_quality['score'])}).",
        f"Main findings: HR {_fmt(measurements['heart_rate_bpm'], ' BPM')}, rhythm {_fmt(measurements['heart_rhythm_classification'])}, QRS {_fmt(measurements['qrs_duration_ms_estimate'], ' ms')}.",
        f"Next action: {_fmt(ai_result['recommended_action'])}.",
    ]

    case_summary_en = " ".join(
        [
            f"This ECG case is currently categorized as {_fmt(model.get('risk_level'))} risk with model score {_fmt(ai_result['model_score_pct'], '%')}.",
            f"Estimated heart rate is {_fmt(measurements['heart_rate_bpm'], ' BPM')}.",
            (
                "Key automated markers include "
                + ", ".join(
                    [
                        part
                        for part in [
                            f"QRS {_fmt(measurements['qrs_duration_ms_estimate'], ' ms')}"
                            if measurements.get("qrs_duration_ms_estimate")
                            is not None
                            else None,
                            f"QTc {_fmt(measurements['qtc_bazett_ms_estimate'], ' ms')}"
                            if measurements.get("qtc_bazett_ms_estimate")
                            is not None
                            else None,
                            f"ST {_fmt(measurements['st_deviation_estimate'])}"
                            if measurements.get("st_deviation_estimate") is not None
                            else None,
                        ]
                        if part
                    ]
                )
                + "."
            ),
            f"Recommended action: {_fmt(ai_result['recommended_action'])}.",
        ]
    )

    risk_label_ar = {
        "High": "مرتفع",
        "Medium": "متوسط",
        "Low": "منخفض",
    }.get(str(model.get("risk_level") or ""), _fmt(model.get("risk_level")))

    case_summary_ar = " ".join(
        [
            f"تُصنَّف هذه الحالة حاليًا كمستوى خطورة {risk_label_ar} مع درجة نموذجية {_fmt(ai_result['model_score_pct'], '%')}.",
            f"معدل القلب التقديري هو {_fmt(measurements['heart_rate_bpm'], ' نبضة/دقيقة')}.",
            (
                "أهم المؤشرات الآلية تشمل "
                + "، ".join(
                    [
                        part
                        for part in [
                            f"QRS {_fmt(measurements['qrs_duration_ms_estimate'], ' مللي ثانية')}"
                            if measurements.get("qrs_duration_ms_estimate")
                            is not None
                            else None,
                            f"QTc {_fmt(measurements['qtc_bazett_ms_estimate'], ' مللي ثانية')}"
                            if measurements.get("qtc_bazett_ms_estimate")
                            is not None
                            else None,
                            f"ST {_fmt(measurements['st_deviation_estimate'])}"
                            if measurements.get("st_deviation_estimate") is not None
                            else None,
                        ]
                        if part
                    ]
                )
                + "."
            ),
            f"الإجراء المقترح التالي: {_fmt(ai_result['recommended_action'])}.",
        ]
    )

    return {
        "generated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "patient_information": patient_information,
        "recording_information": recording_information,
        "measurements": measurements,
        "hrv": hrv,
        "signal_quality": signal_quality,
        "frequency_analysis": frequency_analysis,
        "wavelet_analysis": {"available": False},
        "ai_result": ai_result,
        "explainability": explainability,
        "findings": evidence_rows,
        "recommendations": next_steps,
        "limitations": warnings,
        "priority": priority,
        "clinical_summary": clinical_summary,
        "case_summary_en": case_summary_en,
        "case_summary_ar": case_summary_ar,
    }
