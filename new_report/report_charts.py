from __future__ import annotations

import io
from typing import Any

import numpy as np
from matplotlib.figure import Figure

PRIMARY = "#12384c"
ACCENT = "#2b7a78"
SUCCESS = "#2f855a"
WARNING = "#b7791f"
DANGER = "#c53030"
TEXT_MUTED = "#58707a"
GRID_MINOR = "#e2ebef"


def _png_bytes(fig: Figure) -> bytes:
    buf = io.BytesIO()
    fig.savefig(buf, format="png", dpi=180, bbox_inches="tight")
    return buf.getvalue()


def build_report_charts(context: dict[str, Any], report_data: dict[str, Any]) -> dict[str, bytes]:
    charts: dict[str, bytes] = {}
    raw_signal = context.get("raw_signal")
    filtered_signal = context.get("filtered_signal")
    rep_filtered = context.get("rep_filtered")
    fs = context.get("fs")
    peaks = np.asarray(context.get("peaks", []), dtype=int)
    rr_ms = np.asarray(context.get("rr_ms", []), dtype=np.float32)
    poincare = context.get("poincare", {})
    selected_beat = context.get("selected_beat", {})
    lead_names = report_data["recording_information"].get("lead_names", [])
    freq = report_data["frequency_analysis"]

    if filtered_signal is not None and fs:
        filtered = np.asarray(filtered_signal)
        max_leads = min(int(filtered.shape[0]), 12)
        n = min(filtered.shape[1], int(fs * 10))
        t = np.arange(n) / fs
        fig = Figure(figsize=(10.6, 7.4), facecolor="white")
        for idx in range(max_leads):
            ax = fig.add_subplot(6, 2, idx + 1)
            ax.plot(t, filtered[idx][:n], color=PRIMARY, linewidth=0.8)
            ax.set_title(lead_names[idx] if idx < len(lead_names) else f"Lead {idx+1}", fontsize=8, loc="left")
            ax.grid(color=GRID_MINOR, linewidth=0.5)
            ax.tick_params(labelsize=6)
            if idx < max_leads - 2:
                ax.set_xticklabels([])
            else:
                ax.set_xlabel("s", fontsize=6)
            ax.set_ylabel("a.u.", fontsize=6)
        fig.tight_layout(h_pad=0.8, w_pad=0.6)
        charts["main_ecg"] = _png_bytes(fig)

    if rep_filtered is not None and fs:
        rep = np.asarray(rep_filtered)
        n = min(len(rep), int(fs * 10))
        t = np.arange(n) / fs
        vis = peaks[peaks < n]
        hr = (60000.0 / rr_ms).astype(np.float32) if len(rr_ms) else np.array([], dtype=np.float32)
        fig = Figure(figsize=(10, 5.8), facecolor="white")
        ax1 = fig.add_subplot(221)
        ax1.plot(t, rep[:n], color=PRIMARY, linewidth=1.0)
        if len(vis):
            ax1.scatter(vis / fs, rep[vis], color=DANGER, s=10)
        ax1.set_title("Rhythm Strip", fontsize=10)
        ax1.set_xlabel("Time (s)")
        ax1.set_ylabel("Amplitude")
        ax1.grid(color=GRID_MINOR)
        ax2 = fig.add_subplot(222)
        if len(hr):
            ax2.plot(np.arange(len(hr)), hr, color=ACCENT, linewidth=1.0)
        ax2.set_title("Heart-Rate Trend", fontsize=10)
        ax2.set_xlabel("Beat Index")
        ax2.set_ylabel("BPM")
        ax2.grid(color=GRID_MINOR)
        ax3 = fig.add_subplot(223)
        if len(rr_ms):
            ax3.plot(np.arange(len(rr_ms)), rr_ms, color=PRIMARY, linewidth=1.0)
        ax3.set_title("RR Tachogram", fontsize=10)
        ax3.set_xlabel("Beat Index")
        ax3.set_ylabel("RR (ms)")
        ax3.grid(color=GRID_MINOR)
        ax4 = fig.add_subplot(224)
        ax4.plot(t, rep[:n], color=TEXT_MUTED, linewidth=0.9)
        if len(vis):
            ax4.scatter(vis / fs, rep[vis], color=DANGER, s=12)
        ax4.set_title("R-Peak Visualization", fontsize=10)
        ax4.set_xlabel("Time (s)")
        ax4.set_ylabel("Amplitude")
        ax4.grid(color=GRID_MINOR)
        fig.tight_layout()
        charts["supporting_graphs"] = _png_bytes(fig)

        fig2 = Figure(figsize=(10, 5.8), facecolor="white")
        hr = (60000.0 / rr_ms).astype(np.float32) if len(rr_ms) else np.array([], dtype=np.float32)
        ax1 = fig2.add_subplot(221)
        if len(hr):
            ax1.plot(np.arange(len(hr)), hr, color=PRIMARY, linewidth=1.0)
        ax1.set_title("Heart-Rate Trend", fontsize=10)
        ax1.grid(color=GRID_MINOR)
        ax2 = fig2.add_subplot(222)
        if len(rr_ms):
            ax2.plot(np.arange(len(rr_ms)), rr_ms, color=ACCENT, linewidth=1.0)
        ax2.set_title("RR Tachogram", fontsize=10)
        ax2.grid(color=GRID_MINOR)
        ax3 = fig2.add_subplot(223)
        if len(hr):
            ax3.hist(hr, bins=min(12, max(4, len(hr) // 2)), color=ACCENT, alpha=0.85)
        ax3.set_title("Heart-Rate Distribution", fontsize=10)
        ax3.grid(axis="y", color=GRID_MINOR)
        ax4 = fig2.add_subplot(224)
        if poincare.get("available"):
            ax4.scatter(poincare["x"], poincare["y"], color=PRIMARY, s=12, alpha=0.8)
        ax4.set_title("Poincare Plot", fontsize=10)
        ax4.grid(color=GRID_MINOR)
        fig2.tight_layout()
        charts["hrv_graphs"] = _png_bytes(fig2)

    if selected_beat.get("available") and fs:
        clinical = report_data["measurements"]
        signal = np.array(selected_beat["signal"])
        x = (np.array(selected_beat["x"]) - selected_beat["left"]) / fs
        fig = Figure(figsize=(10, 5.2), facecolor="white")
        ax1 = fig.add_subplot(121)
        ax1.plot(x, signal, color=PRIMARY, linewidth=1.2)
        center = (selected_beat["center"] - selected_beat["left"]) / fs
        ax1.axvline(center, color=DANGER, linestyle="--", linewidth=1.0)
        ax1.set_title("Representative Beat", fontsize=10)
        ax1.grid(color=GRID_MINOR)
        ax2 = fig.add_subplot(122)
        labels = ["PR", "QRS", "QT", "QTc"]
        values = [
            clinical.get("pr_interval_ms_estimate"),
            clinical.get("qrs_duration_ms_estimate"),
            clinical.get("qt_interval_ms_estimate"),
            clinical.get("qtc_bazett_ms_estimate"),
        ]
        valid = [(l, v) for l, v in zip(labels, values) if v is not None]
        if valid:
            ax2.bar([row[0] for row in valid], [float(row[1]) for row in valid], color=[ACCENT, PRIMARY, WARNING, DANGER][: len(valid)])
        ax2.set_title("Interval Overview", fontsize=10)
        ax2.grid(axis="y", color=GRID_MINOR)
        fig.tight_layout()
        charts["morphology"] = _png_bytes(fig)

    if freq.get("available"):
        freqs = np.asarray(freq.get("freqs", []), dtype=np.float32)
        power = np.asarray(freq.get("power", []), dtype=np.float32)
        bands = freq.get("band_energy", {})
        fig = Figure(figsize=(10, 5.2), facecolor="white")
        ax1 = fig.add_subplot(121)
        ax1.plot(freqs, power, color=PRIMARY, linewidth=1.0)
        ax1.set_title("Power Spectral Density", fontsize=10)
        ax1.set_xlabel("Frequency (Hz)")
        ax1.set_ylabel("Power")
        ax1.grid(color=GRID_MINOR)
        ax2 = fig.add_subplot(122)
        ax2.bar(list(bands.keys()), list(bands.values()), color=ACCENT)
        ax2.set_title("Frequency Spectrum Energy", fontsize=10)
        ax2.grid(axis="y", color=GRID_MINOR)
        fig.tight_layout()
        charts["frequency"] = _png_bytes(fig)

    model = report_data["ai_result"]
    score = model.get("model_score_pct")
    threshold = model.get("decision_threshold")
    if score is not None and threshold is not None:
        fig = Figure(figsize=(6.2, 2.2), facecolor="white")
        ax = fig.add_subplot(111)
        ax.set_xlim(0, 100)
        ax.set_ylim(0, 1)
        ax.hlines(0.5, 0, 100, color=GRID_MINOR, linewidth=4)
        ax.vlines(float(threshold) * 100.0, 0.2, 0.8, color=WARNING, linewidth=2)
        ax.scatter([float(score)], [0.5], color=DANGER if float(score) >= float(threshold) * 100.0 else SUCCESS, s=70)
        ax.set_yticks([])
        ax.set_xlabel("Model score scale (%)")
        ax.set_title("AI Score vs Threshold", fontsize=10)
        fig.tight_layout()
        charts["threshold"] = _png_bytes(fig)

    if report_data["explainability"].get("top_features"):
        features = report_data["explainability"]["top_features"]
        fig = Figure(figsize=(6.5, 3.0), facecolor="white")
        ax = fig.add_subplot(111)
        labels = [f"F{row['feature_index']}" for row in features][::-1]
        values = [abs(row["feature_value"]) for row in features][::-1]
        ax.barh(labels, values, color=ACCENT)
        ax.set_title("Feature Importance", fontsize=10)
        ax.grid(axis="x", color=GRID_MINOR)
        fig.tight_layout()
        charts["explainability"] = _png_bytes(fig)

    clinical = report_data["measurements"]
    quality = report_data["signal_quality"]
    interval_pairs = [
        ("PR", clinical.get("pr_interval_ms_estimate")),
        ("QRS", clinical.get("qrs_duration_ms_estimate")),
        ("QT", clinical.get("qt_interval_ms_estimate")),
        ("QTc", clinical.get("qtc_bazett_ms_estimate")),
    ]
    interval_pairs = [(label, float(value)) for label, value in interval_pairs if value is not None]
    quality_pairs = [
        ("Signal", quality.get("score")),
        ("Baseline", quality.get("baseline_wander_ratio")),
        ("Noise", quality.get("noise_ratio")),
        ("Clipping", quality.get("clipping_ratio")),
    ]
    quality_pairs = [
        (label, float(value))
        for label, value in quality_pairs
        if value is not None and np.isfinite(float(value))
    ]
    if interval_pairs or quality_pairs:
        fig = Figure(figsize=(10, 4.6), facecolor="white")
        ax1 = fig.add_subplot(121)
        if interval_pairs:
            ax1.bar(
                [label for label, _ in interval_pairs],
                [value for _, value in interval_pairs],
                color=[PRIMARY, ACCENT, WARNING, DANGER][: len(interval_pairs)],
            )
        ax1.set_title("Interval Metrics", fontsize=10)
        ax1.set_ylabel("Milliseconds")
        ax1.grid(axis="y", color=GRID_MINOR)
        ax2 = fig.add_subplot(122)
        if quality_pairs:
            ax2.bar(
                [label for label, _ in quality_pairs],
                [value for _, value in quality_pairs],
                color=[ACCENT, PRIMARY, WARNING, DANGER][: len(quality_pairs)],
            )
        ax2.set_title("Signal Quality Metrics", fontsize=10)
        ax2.grid(axis="y", color=GRID_MINOR)
        fig.tight_layout()
        charts["clinical_metrics"] = _png_bytes(fig)

    raw_probability = model.get("raw_probability")
    calibrated_probability = model.get("calibrated_probability")
    threshold_probability = model.get("decision_threshold")
    score_probability = model.get("model_score_pct")
    risk_pairs = [
        ("Raw Prob.", raw_probability * 100.0 if raw_probability is not None else None),
        ("Calibrated", calibrated_probability * 100.0 if calibrated_probability is not None else None),
        ("Threshold", threshold_probability * 100.0 if threshold_probability is not None else None),
        ("Risk Score", score_probability if score_probability is not None else None),
    ]
    risk_pairs = [
        (label, float(value))
        for label, value in risk_pairs
        if value is not None and np.isfinite(float(value))
    ]
    if risk_pairs:
        fig = Figure(figsize=(6.6, 3.0), facecolor="white")
        ax = fig.add_subplot(111)
        labels = [label for label, _ in risk_pairs][::-1]
        values = [value for _, value in risk_pairs][::-1]
        colors_list = [DANGER if value >= 70 else WARNING if value >= 40 else ACCENT for value in values]
        ax.barh(labels, values, color=colors_list)
        ax.set_xlim(0, 100)
        ax.set_title("AI Risk Profile", fontsize=10)
        ax.set_xlabel("Percent scale")
        ax.grid(axis="x", color=GRID_MINOR)
        fig.tight_layout()
        charts["risk_profile"] = _png_bytes(fig)

    return charts
