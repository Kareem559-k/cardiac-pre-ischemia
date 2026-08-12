from __future__ import annotations

import io
from pathlib import Path
from typing import Any

import numpy as np
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import Image, PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from .report_charts import build_report_charts
from .report_data import build_report_data

PRIMARY = "#12384c"
ACCENT = "#2b7a78"
TEXT_MUTED = "#58707a"
BORDER = "#d6e2e8"
BG_SOFT = "#f7fbfc"
HEADER_BG = "#eaf2f5"


def _font_names() -> tuple[str, str]:
    regular = "Helvetica"
    bold = "Helvetica-Bold"
    try:
        font_root = Path(__file__).resolve().parent.parent / "backend" / ".venv" / "Lib" / "site-packages" / "matplotlib" / "mpl-data" / "fonts" / "ttf"
        regular_path = font_root / "DejaVuSans.ttf"
        bold_path = font_root / "DejaVuSans-Bold.ttf"
        if regular_path.exists() and bold_path.exists():
            if "DejaVuSans" not in pdfmetrics.getRegisteredFontNames():
                pdfmetrics.registerFont(TTFont("DejaVuSans", str(regular_path)))
            if "DejaVuSans-Bold" not in pdfmetrics.getRegisteredFontNames():
                pdfmetrics.registerFont(TTFont("DejaVuSans-Bold", str(bold_path)))
            regular = "DejaVuSans"
            bold = "DejaVuSans-Bold"
    except Exception:
        pass
    return regular, bold


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


def _styles() -> dict[str, ParagraphStyle]:
    styles = getSampleStyleSheet()
    regular_font, bold_font = _font_names()
    return {
        "title": ParagraphStyle("title", parent=styles["Heading1"], fontName=bold_font, fontSize=16, textColor=colors.HexColor(PRIMARY), spaceAfter=4),
        "subtitle": ParagraphStyle("subtitle", parent=styles["Heading2"], fontName=bold_font, fontSize=10.5, textColor=colors.HexColor(TEXT_MUTED), spaceAfter=4),
        "section": ParagraphStyle("section", parent=styles["Heading3"], fontName=bold_font, fontSize=10.2, textColor=colors.HexColor(PRIMARY), spaceBefore=4, spaceAfter=3),
        "body": ParagraphStyle("body", parent=styles["BodyText"], fontName=regular_font, fontSize=8.0, leading=9.2, textColor=colors.black),
        "tiny": ParagraphStyle("tiny", parent=styles["BodyText"], fontName=regular_font, fontSize=7.1, leading=8.2, textColor=colors.HexColor(TEXT_MUTED)),
    }


def _styled(table: Table, header_bg: str = HEADER_BG, fontsize: int = 8, padding: int = 4) -> Table:
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor(header_bg)),
                ("BOX", (0, 0), (-1, -1), 0.5, colors.HexColor(BORDER)),
                ("INNERGRID", (0, 0), (-1, -1), 0.5, colors.HexColor(BORDER)),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("FONTSIZE", (0, 0), (-1, -1), fontsize),
                ("LEFTPADDING", (0, 0), (-1, -1), padding),
                ("RIGHTPADDING", (0, 0), (-1, -1), padding),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]
        )
    )
    return table


def _header(story: list[object], title_style: ParagraphStyle, subtitle_style: ParagraphStyle, body_style: ParagraphStyle, report_data: dict[str, Any], variant_name: str) -> None:
    story.extend(
        [
            Paragraph("CARDIAC PRE-STROKE", title_style),
            Paragraph("AI-ASSISTED ECG ANALYSIS", subtitle_style),
            Paragraph(f"Generated: {report_data['generated_at']} | Layout: {variant_name}", body_style),
            Spacer(1, 3),
        ]
    )


def _patient_table(patient: dict[str, Any], recording: dict[str, Any], small: bool = False) -> Table:
    widths = [25 * mm, 50 * mm, 25 * mm, 50 * mm] if small else [30 * mm, 58 * mm, 30 * mm, 58 * mm]
    rows = [
        ["Patient ID", patient.get("patient_id") or "-", "Recording ID", recording.get("recording_id") or "-"],
        ["Age", patient.get("age") or "-", "Sex", patient.get("sex") or "-",],
        ["Date", recording.get("recording_date") or "-", "Duration", recording.get("duration") or "-"],
        ["Sampling Rate", _fmt(recording.get("sampling_rate_hz"), " Hz", 0), "Number of Leads", _fmt(recording.get("num_leads"))],
        ["Signal Quality", recording.get("signal_quality_status") or "-", "", ""],
    ]
    return _styled(Table(rows, colWidths=widths), header_bg="#ffffff")


def _summary_box(report_data: dict[str, Any], body_style: ParagraphStyle) -> Table:
    box = Table([[Paragraph("<br/>".join(report_data["clinical_summary"][:4]), body_style)]], colWidths=[184 * mm])
    box.setStyle(
        TableStyle(
            [
                ("BOX", (0, 0), (-1, -1), 0.5, colors.HexColor(BORDER)),
                ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor(BG_SOFT)),
                ("PADDING", (0, 0), (-1, -1), 6),
            ]
        )
    )
    return box


def _measurement_rows(measurements: dict[str, Any]) -> list[list[str]]:
    rows = [["Parameter", "Result", "Status"]]
    for label, key, unit in [
        ("Heart Rate", "heart_rate_bpm", " BPM"),
        ("PR", "pr_interval_ms_estimate", " ms"),
        ("QRS", "qrs_duration_ms_estimate", " ms"),
        ("QT", "qt_interval_ms_estimate", " ms"),
        ("QTc", "qtc_bazett_ms_estimate", " ms"),
        ("ST", "st_deviation_estimate", ""),
    ]:
        value = measurements.get(key)
        if value is None:
            continue
        status = "Automated" if label in {"Heart Rate", "QRS"} else "Automated / Verify"
        rows.append([label, _fmt(value, unit, 4 if label == "ST" else 2), status])
    return rows


def _ai_rows(ai: dict[str, Any]) -> list[list[str]]:
    return [
        ["Metric", "Value"],
        ["Classification", ai.get("classification") or "-"],
        ["Model Score", _fmt(ai.get("model_score_pct"), "%")],
        ["Threshold", _fmt(ai.get("decision_threshold"), "", 3)],
        ["Screening Status", ai.get("screening_status") or "-"],
    ]


def _findings_rows(findings: list[dict[str, str]], limit: int = 6) -> list[list[str]]:
    rows = [["Finding", "Evidence", "Importance"]]
    for row in findings[:limit]:
        rows.append([row["finding"], row["value"], row["reliability"]])
    return rows


def _recommendation_rows(recommendations: list[dict[str, str]], limit: int = 5) -> list[list[str]]:
    rows = [["Finding", "Action"]]
    for row in recommendations[:limit]:
        rows.append([row["finding"], row["next_step"]])
    if len(rows) == 1:
        rows.append(["Clinical review", "Review ECG in context with clinician assessment."])
    return rows


def _phys_rows(measurements: dict[str, Any], hrv: dict[str, Any]) -> list[list[str]]:
    rr = np.asarray(hrv.get("rr_series_ms", []), dtype=float)
    hr_low = (60000.0 / np.max(rr)) if len(rr) else None
    hr_high = (60000.0 / np.min(rr)) if len(rr) else None
    rr_sd = float(np.std(rr)) if len(rr) else None
    return [
        ["Parameter", "Result", "Unit"],
        ["Heart Rate", _fmt(measurements.get("heart_rate_bpm")), "BPM"],
        ["HR Range", f"{_fmt(hr_low)} - {_fmt(hr_high)}", "BPM"],
        ["Mean RR", _fmt(measurements.get("rr_interval_ms")), "ms"],
        ["RR SD", _fmt(rr_sd), "ms"],
        ["SDNN", _fmt(hrv.get("sdnn_ms")), "ms"],
        ["RMSSD", _fmt(hrv.get("rmssd_ms")), "ms"],
        ["pNN50", _fmt(hrv.get("pnn50_pct")), "%"],
    ]


def _interval_rows(measurements: dict[str, Any]) -> list[list[str]]:
    rows = [["Parameter", "Value", "Source", "Reliability"]]
    for label, key in [
        ("PR", "pr_interval_ms_estimate"),
        ("QRS", "qrs_duration_ms_estimate"),
        ("QT", "qt_interval_ms_estimate"),
        ("QTc", "qtc_bazett_ms_estimate"),
        ("ST", "st_deviation_estimate"),
    ]:
        value = measurements.get(key)
        if value is None:
            continue
        rows.append(
            [
                label,
                _fmt(value, " ms" if label != "ST" else "", 4 if label == "ST" else 2),
                "Existing pipeline",
                "Automated" if label == "QRS" else "Heuristic / Experimental",
            ]
        )
    return rows


def _quality_rows(quality: dict[str, Any]) -> list[list[str]]:
    return [
        ["Metric", "Value"],
        ["Signal Quality", _fmt(quality.get("score"))],
        ["Noise Level", quality.get("noise_level") or "-"],
        ["Baseline Wander", _fmt(quality.get("baseline_wander_ratio"))],
        ["Noise Ratio", _fmt(quality.get("noise_ratio"))],
        ["Clipping Ratio", _fmt(quality.get("clipping_ratio"))],
    ]


def _frequency_rows(frequency: dict[str, Any]) -> list[list[str]]:
    return [
        ["Metric", "Value"],
        ["Spectral Entropy", _fmt(frequency.get("spectral_entropy"))],
        ["Dominant Frequency", _fmt(frequency.get("dominant_frequency_hz"), " Hz")],
        ["0.5-4 Hz Energy", _fmt(frequency.get("band_energy", {}).get("0.5-4 Hz"))],
        ["4-15 Hz Energy", _fmt(frequency.get("band_energy", {}).get("4-15 Hz"))],
        ["15-40 Hz Energy", _fmt(frequency.get("band_energy", {}).get("15-40 Hz"))],
    ]


def _evidence_rows(findings: list[dict[str, str]], limit: int = 8) -> list[list[str]]:
    rows = [["Finding", "Observed Value", "Evidence", "Significance", "Review"]]
    for row in findings[:limit]:
        rows.append([row["finding"], row["value"], row["source"], row["significance"], row["review"]])
    return rows


def _limitations_rows(limitations: list[dict[str, str]]) -> list[list[str]]:
    rows = [["Limitation", "Impact"]]
    for row in limitations[:4]:
        rows.append([row["problem"], row["why"]])
    rows.append(["Research prototype", "Not a diagnostic medical device."])
    return rows


def _assessment_block(ai: dict[str, Any], findings: list[dict[str, str]], priority: str) -> Table:
    left = _styled(Table([["OVERALL RESULT"], [f"{ai.get('classification') or '-'} | {_fmt(ai.get('model_score_pct'), '%')} | {priority}"]], colWidths=[88 * mm]), header_bg="#f4f8fa")
    right = _styled(Table([["MAIN FACTORS"]] + [[row["finding"]] for row in findings[:5]], colWidths=[88 * mm]), header_bg="#f4f8fa")
    return Table([[left, right]], colWidths=[92 * mm, 92 * mm])


def _medical_note_rows(measurements: dict[str, Any], ai: dict[str, Any], quality: dict[str, Any]) -> list[list[str]]:
    notes = [["Focus", "Clinical note"]]
    hr = measurements.get("heart_rate_bpm")
    qtc = measurements.get("qtc_bazett_ms_estimate")
    qrs = measurements.get("qrs_duration_ms_estimate")
    st = measurements.get("st_deviation_estimate")
    signal = quality.get("score")
    if hr is not None:
        if float(hr) > 100:
            notes.append(["Heart rate", f"Rate is elevated at {_fmt(hr, ' bpm')} and should be interpreted with rhythm context."])
        elif float(hr) < 60:
            notes.append(["Heart rate", f"Rate is below 60 bpm at {_fmt(hr, ' bpm')}; correlate with symptoms and baseline."])
        else:
            notes.append(["Heart rate", f"Rate is within an expected resting range at {_fmt(hr, ' bpm')}."])
    if qrs is not None:
        notes.append(["QRS", f"Automated QRS estimate is {_fmt(qrs, ' ms')}; compare with morphology and conduction pattern."])
    if qtc is not None:
        notes.append(["QTc", f"QTc estimate is {_fmt(qtc, ' ms')} and should be verified clinically before interpretation."])
    if st is not None:
        notes.append(["ST segment", f"Estimated ST deviation is {_fmt(st)}; confirm on raw ECG and lead distribution."])
    if signal is not None:
        notes.append(["Signal quality", f"Signal quality score is {_fmt(signal)} with noise label {quality.get('noise_level') or '-'}."])
    notes.append(["AI output", f"Model classification is {ai.get('classification') or '-'} with score {_fmt(ai.get('model_score_pct'), '%')}."])
    return notes[:7]


def _clinical_interpretation_rows(measurements: dict[str, Any], ai: dict[str, Any], quality: dict[str, Any], findings: list[dict[str, str]]) -> list[list[str]]:
    rows = [["Section", "Interpretation"]]
    rows.append(
        [
            "Overall impression",
            f"Current AI-assisted screening output is {ai.get('classification') or '-'} with risk band {ai.get('screening_status') or '-'} and score {_fmt(ai.get('model_score_pct'), '%')}.",
        ]
    )
    hr = measurements.get("heart_rate_bpm")
    if hr is not None:
        rows.append(
            [
                "Rate interpretation",
                "Tachycardic pattern requires rhythm correlation."
                if float(hr) > 100
                else "Lower-rate pattern should be correlated with symptoms."
                if float(hr) < 60
                else "Rate does not independently suggest marked instability.",
            ]
        )
    qtc = measurements.get("qtc_bazett_ms_estimate")
    if qtc is not None:
        rows.append(
            [
                "Repolarization review",
                f"QTc estimate is {_fmt(qtc, ' ms')}; verify on raw tracing before any clinical escalation.",
            ]
        )
    st = measurements.get("st_deviation_estimate")
    if st is not None:
        rows.append(
            [
                "ST review",
                f"Estimated ST deviation is {_fmt(st)} and should be interpreted in lead context rather than isolation.",
            ]
        )
    rows.append(
        [
            "Signal confidence",
            f"Signal quality is {_fmt(quality.get('score'))} with noise label {quality.get('noise_level') or '-'}; lower quality reduces confidence in finer interval interpretation.",
        ]
    )
    if findings:
        rows.append(
            [
                "Primary evidence",
                findings[0].get("finding") or "-",
            ]
        )
    return rows[:7]


def _build_story_summary_focus(report_data: dict[str, Any], charts: dict[str, bytes]) -> list[object]:
    s = _styles()
    patient = report_data["patient_information"]
    recording = report_data["recording_information"]
    measurements = report_data["measurements"]
    hrv = report_data["hrv"]
    quality = report_data["signal_quality"]
    frequency = report_data["frequency_analysis"]
    ai = report_data["ai_result"]
    findings = report_data["findings"]
    recommendations = report_data["recommendations"]
    limitations = report_data["limitations"]

    story: list[object] = []
    _header(story, s["title"], s["subtitle"], s["body"], report_data, "Summary Focus")
    story.extend([Paragraph("PATIENT / RECORDING INFORMATION", s["section"]), _patient_table(patient, recording), Spacer(1, 4)])
    story.extend([Paragraph("CLINICAL SUMMARY", s["section"]), _summary_box(report_data, s["body"]), Spacer(1, 4)])
    if "main_ecg" in charts:
        story.extend([Paragraph("MAIN ECG VISUALIZATION", s["section"]), Image(io.BytesIO(charts["main_ecg"]), width=184 * mm, height=88 * mm), Spacer(1, 3)])
    lower_left = _styled(Table(_measurement_rows(measurements), colWidths=[30 * mm, 30 * mm, 34 * mm]))
    lower_mid = _styled(Table(_ai_rows(ai), colWidths=[32 * mm, 34 * mm]))
    lower_right = _styled(Table(_findings_rows(findings, 4), colWidths=[34 * mm, 36 * mm, 18 * mm]), fontsize=7)
    story.extend([Table([[lower_left, lower_mid, lower_right]], colWidths=[96 * mm, 66 * mm, 22 * mm]), Spacer(1, 4)])
    story.extend([Paragraph("RECOMMENDED NEXT STEPS", s["section"]), _styled(Table(_recommendation_rows(recommendations, 4), colWidths=[58 * mm, 126 * mm]))])

    story.append(PageBreak())
    story.extend([Paragraph("DETAILED ECG ANALYSIS", s["title"]), Spacer(1, 3)])
    if "supporting_graphs" in charts:
        story.extend([Paragraph("SUPPORTING ECG GRAPHS", s["section"]), Image(io.BytesIO(charts["supporting_graphs"]), width=184 * mm, height=76 * mm), Spacer(1, 3)])
    top_detail = Table(
        [[_styled(Table(_phys_rows(measurements, hrv), colWidths=[44 * mm, 28 * mm, 18 * mm])), _styled(Table(_interval_rows(measurements), colWidths=[22 * mm, 24 * mm, 42 * mm, 34 * mm]))]],
        colWidths=[92 * mm, 92 * mm],
    )
    top_detail.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
    story.extend([top_detail, Spacer(1, 4)])
    if "hrv_graphs" in charts:
        story.extend([Paragraph("HEART RATE / HRV", s["section"]), Image(io.BytesIO(charts["hrv_graphs"]), width=184 * mm, height=72 * mm), Spacer(1, 3)])
    bottom_detail_items: list[object] = [Paragraph("SIGNAL QUALITY", s["section"]), _styled(Table(_quality_rows(quality), colWidths=[72 * mm, 40 * mm]))]
    if "frequency" in charts:
        freq_block = Table([[Image(io.BytesIO(charts["frequency"]), width=108 * mm, height=52 * mm), _styled(Table(_frequency_rows(frequency), colWidths=[46 * mm, 30 * mm]))]], colWidths=[112 * mm, 72 * mm])
        freq_block.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
        bottom_detail_items.extend([Spacer(1, 3), Paragraph("FREQUENCY ANALYSIS", s["section"]), freq_block])
    story.extend(bottom_detail_items)

    story.append(PageBreak())
    story.extend([Paragraph("AI & EVIDENCE ANALYSIS", s["title"]), Spacer(1, 3)])
    ai_table = _styled(Table(_ai_rows(ai), colWidths=[56 * mm, 34 * mm]))
    threshold = Image(io.BytesIO(charts["threshold"]), width=90 * mm, height=30 * mm) if "threshold" in charts else _styled(Table([["Score", _fmt(ai.get("model_score_pct"), "%")], ["Threshold", _fmt(ai.get("decision_threshold"), "", 3)]], colWidths=[40 * mm, 40 * mm]))
    story.extend([Table([[ai_table, threshold]], colWidths=[92 * mm, 92 * mm]), Spacer(1, 4)])
    if "explainability" in charts:
        story.extend([Paragraph("MODEL EXPLAINABILITY", s["section"]), Image(io.BytesIO(charts["explainability"]), width=150 * mm, height=48 * mm), Spacer(1, 3)])
    story.extend([Paragraph("EVIDENCE SUMMARY", s["section"]), _styled(Table(_evidence_rows(findings, 7), colWidths=[34 * mm, 24 * mm, 28 * mm, 52 * mm, 46 * mm]), fontsize=7), Spacer(1, 3)])
    story.extend([Paragraph("LIMITATIONS", s["section"]), _styled(Table(_limitations_rows(limitations), colWidths=[60 * mm, 124 * mm])) , Spacer(1, 3)])
    story.extend([Paragraph("OVERALL ASSESSMENT", s["section"]), _assessment_block(ai, findings, report_data["priority"]), Spacer(1, 3)])
    story.extend([Paragraph("CLINICAL DISCLAIMER", s["section"]), Paragraph("Research-use AI-assisted ECG screening report. Not a medical diagnosis. Automated interval and model outputs require independent clinical review.", s["tiny"])])

    if "morphology" in charts:
        story.append(PageBreak())
        story.extend([Paragraph("ADDITIONAL ECG VISUALIZATION", s["title"]), Spacer(1, 3), Paragraph("ECG MORPHOLOGY", s["section"]), Image(io.BytesIO(charts["morphology"]), width=184 * mm, height=74 * mm)])
    return story


def _build_story_graph_first(report_data: dict[str, Any], charts: dict[str, bytes]) -> list[object]:
    s = _styles()
    patient = report_data["patient_information"]
    recording = report_data["recording_information"]
    measurements = report_data["measurements"]
    hrv = report_data["hrv"]
    quality = report_data["signal_quality"]
    frequency = report_data["frequency_analysis"]
    ai = report_data["ai_result"]
    findings = report_data["findings"]
    recommendations = report_data["recommendations"]
    limitations = report_data["limitations"]

    story: list[object] = []
    _header(story, s["title"], s["subtitle"], s["body"], report_data, "Graph First")
    top_row = Table([[ _patient_table(patient, recording, small=True), _styled(Table(_ai_rows(ai), colWidths=[34 * mm, 40 * mm])) ]], colWidths=[106 * mm, 78 * mm])
    top_row.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
    story.extend([top_row, Spacer(1, 4), Paragraph("CLINICAL SUMMARY", s["section"]), _summary_box(report_data, s["body"]), Spacer(1, 4)])
    if "main_ecg" in charts:
        story.extend([Paragraph("12-LEAD ECG OVERVIEW", s["section"]), Image(io.BytesIO(charts["main_ecg"]), width=184 * mm, height=98 * mm), Spacer(1, 3)])
    if "supporting_graphs" in charts:
        story.extend([Paragraph("RHYTHM / RR / R-PEAKS", s["section"]), Image(io.BytesIO(charts["supporting_graphs"]), width=184 * mm, height=58 * mm), Spacer(1, 3)])
    story.extend([Paragraph("RECOMMENDED NEXT STEPS", s["section"]), _styled(Table(_recommendation_rows(recommendations, 4), colWidths=[58 * mm, 126 * mm]))])

    story.append(PageBreak())
    story.extend([Paragraph("DETAILED ECG ANALYSIS", s["title"]), Spacer(1, 3)])
    upper = Table(
        [[_styled(Table(_measurement_rows(measurements), colWidths=[30 * mm, 26 * mm, 34 * mm])), _styled(Table(_phys_rows(measurements, hrv), colWidths=[40 * mm, 22 * mm, 18 * mm])), _styled(Table(_quality_rows(quality), colWidths=[34 * mm, 22 * mm]))]],
        colWidths=[74 * mm, 82 * mm, 28 * mm],
    )
    upper.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
    story.extend([upper, Spacer(1, 4)])
    if "hrv_graphs" in charts:
        story.extend([Paragraph("HEART RATE / HRV ANALYSIS", s["section"]), Image(io.BytesIO(charts["hrv_graphs"]), width=184 * mm, height=78 * mm), Spacer(1, 3)])
    story.extend([Paragraph("ECG INTERVAL ANALYSIS", s["section"]), _styled(Table(_interval_rows(measurements), colWidths=[24 * mm, 24 * mm, 46 * mm, 50 * mm])), Spacer(1, 3)])
    if "morphology" in charts:
        story.extend([Paragraph("REPRESENTATIVE MORPHOLOGY", s["section"]), Image(io.BytesIO(charts["morphology"]), width=184 * mm, height=56 * mm)])

    story.append(PageBreak())
    story.extend([Paragraph("AI & EVIDENCE ANALYSIS", s["title"]), Spacer(1, 3)])
    if "threshold" in charts:
        story.extend([Paragraph("DECISION THRESHOLD GRAPH", s["section"]), Image(io.BytesIO(charts["threshold"]), width=110 * mm, height=34 * mm), Spacer(1, 3)])
    story.extend([Paragraph("KEY FINDINGS", s["section"]), _styled(Table(_findings_rows(findings, 6), colWidths=[58 * mm, 52 * mm, 26 * mm])), Spacer(1, 3)])
    story.extend([Paragraph("EVIDENCE TABLE", s["section"]), _styled(Table(_evidence_rows(findings, 6), colWidths=[34 * mm, 24 * mm, 26 * mm, 56 * mm, 44 * mm]), fontsize=7), Spacer(1, 3)])
    if "frequency" in charts:
        freq_block = Table([[Image(io.BytesIO(charts["frequency"]), width=104 * mm, height=48 * mm), _styled(Table(_frequency_rows(frequency), colWidths=[48 * mm, 30 * mm]))]], colWidths=[108 * mm, 76 * mm])
        freq_block.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
        story.extend([Paragraph("FREQUENCY DOMAIN", s["section"]), freq_block, Spacer(1, 3)])
    story.extend([Paragraph("OVERALL ASSESSMENT", s["section"]), _assessment_block(ai, findings, report_data["priority"]), Spacer(1, 3)])
    story.extend([Paragraph("LIMITATIONS", s["section"]), _styled(Table(_limitations_rows(limitations), colWidths=[60 * mm, 124 * mm]))])

    if "explainability" in charts:
        story.append(PageBreak())
        story.extend([Paragraph("ADDITIONAL MODEL VISUALIZATION", s["title"]), Spacer(1, 3), Paragraph("MODEL EXPLAINABILITY", s["section"]), Image(io.BytesIO(charts["explainability"]), width=160 * mm, height=56 * mm), Spacer(1, 4), Paragraph("CLINICAL DISCLAIMER", s["section"]), Paragraph("Research-use AI-assisted ECG screening report. Model-derived scores are not standalone diagnoses.", s["tiny"])])
    return story


def _build_story_lab_compact(report_data: dict[str, Any], charts: dict[str, bytes]) -> list[object]:
    s = _styles()
    patient = report_data["patient_information"]
    recording = report_data["recording_information"]
    measurements = report_data["measurements"]
    hrv = report_data["hrv"]
    quality = report_data["signal_quality"]
    frequency = report_data["frequency_analysis"]
    ai = report_data["ai_result"]
    findings = report_data["findings"]
    recommendations = report_data["recommendations"]
    limitations = report_data["limitations"]

    story: list[object] = []
    _header(story, s["title"], s["subtitle"], s["body"], report_data, "Lab Compact")
    story.extend([Paragraph("PAGE 1 CLINICAL SUMMARY", s["section"]), _patient_table(patient, recording), Spacer(1, 3), _summary_box(report_data, s["body"]), Spacer(1, 3)])
    summary_tables = Table(
        [[_styled(Table(_measurement_rows(measurements), colWidths=[28 * mm, 26 * mm, 36 * mm])),
          _styled(Table(_ai_rows(ai), colWidths=[34 * mm, 42 * mm])),
          _styled(Table(_findings_rows(findings, 5), colWidths=[30 * mm, 28 * mm, 20 * mm]), fontsize=7)]],
        colWidths=[90 * mm, 76 * mm, 18 * mm],
    )
    summary_tables.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
    story.extend([summary_tables, Spacer(1, 3)])
    if "main_ecg" in charts:
        story.extend([Paragraph("MAIN ECG", s["section"]), Image(io.BytesIO(charts["main_ecg"]), width=184 * mm, height=78 * mm), Spacer(1, 3)])
    story.extend([Paragraph("RECOMMENDED ACTION", s["section"]), _styled(Table(_recommendation_rows(recommendations, 4), colWidths=[56 * mm, 128 * mm]))])

    story.append(PageBreak())
    story.extend([Paragraph("PAGE 2 DETAILED ECG ANALYSIS", s["title"]), Spacer(1, 3)])
    if "supporting_graphs" in charts:
        story.extend([Image(io.BytesIO(charts["supporting_graphs"]), width=184 * mm, height=66 * mm), Spacer(1, 3)])
    detail_top = Table(
        [[_styled(Table(_phys_rows(measurements, hrv), colWidths=[42 * mm, 22 * mm, 18 * mm])),
          _styled(Table(_interval_rows(measurements), colWidths=[22 * mm, 24 * mm, 38 * mm, 42 * mm]))]],
        colWidths=[84 * mm, 100 * mm],
    )
    detail_top.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
    story.extend([detail_top, Spacer(1, 3)])
    if "hrv_graphs" in charts and "frequency" in charts:
        lower = Table([[Image(io.BytesIO(charts["hrv_graphs"]), width=90 * mm, height=54 * mm), Image(io.BytesIO(charts["frequency"]), width=90 * mm, height=54 * mm)]], colWidths=[92 * mm, 92 * mm])
        story.extend([lower, Spacer(1, 3)])
    elif "hrv_graphs" in charts:
        story.extend([Image(io.BytesIO(charts["hrv_graphs"]), width=184 * mm, height=62 * mm), Spacer(1, 3)])
    story.extend([_styled(Table(_quality_rows(quality), colWidths=[72 * mm, 40 * mm]))])

    story.append(PageBreak())
    story.extend([Paragraph("PAGE 3 AI / EVIDENCE / REVIEW", s["title"]), Spacer(1, 3)])
    if "threshold" in charts or "explainability" in charts:
        top_cells: list[object] = []
        if "threshold" in charts:
            top_cells.append(Image(io.BytesIO(charts["threshold"]), width=88 * mm, height=30 * mm))
        else:
            top_cells.append(_styled(Table([["Score", _fmt(ai.get("model_score_pct"), "%")], ["Threshold", _fmt(ai.get("decision_threshold"), "", 3)]], colWidths=[40 * mm, 40 * mm])))
        if "explainability" in charts:
            top_cells.append(Image(io.BytesIO(charts["explainability"]), width=88 * mm, height=44 * mm))
        else:
            top_cells.append(_styled(Table(_ai_rows(ai), colWidths=[42 * mm, 42 * mm])))
        top = Table([[top_cells[0], top_cells[1]]], colWidths=[92 * mm, 92 * mm])
        top.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
        story.extend([top, Spacer(1, 3)])
    story.extend([Paragraph("EVIDENCE SUMMARY", s["section"]), _styled(Table(_evidence_rows(findings, 7), colWidths=[34 * mm, 24 * mm, 28 * mm, 52 * mm, 46 * mm]), fontsize=7), Spacer(1, 3)])
    story.extend([Paragraph("OVERALL ASSESSMENT", s["section"]), _assessment_block(ai, findings, report_data["priority"]), Spacer(1, 3)])
    story.extend([Paragraph("LIMITATIONS", s["section"]), _styled(Table(_limitations_rows(limitations), colWidths=[60 * mm, 124 * mm])), Spacer(1, 3)])
    story.extend([Paragraph("CLINICAL DISCLAIMER", s["section"]), Paragraph("Research-use AI-assisted ECG screening report. Use alongside clinician review and raw ECG inspection.", s["tiny"])])

    if "morphology" in charts:
        story.append(PageBreak())
        story.extend([Paragraph("OPTIONAL PAGE 4", s["title"]), Spacer(1, 3), Paragraph("ECG MORPHOLOGY", s["section"]), Image(io.BytesIO(charts["morphology"]), width=184 * mm, height=72 * mm)])
    return story


VARIANT_BUILDERS = {
    "summary_focus": _build_story_summary_focus,
    "graph_first": _build_story_graph_first,
    "lab_compact": _build_story_lab_compact,
}


def _build_story_approved(report_data: dict[str, Any], charts: dict[str, bytes]) -> list[object]:
    s = _styles()
    patient = report_data["patient_information"]
    recording = report_data["recording_information"]
    measurements = report_data["measurements"]
    hrv = report_data["hrv"]
    quality = report_data["signal_quality"]
    frequency = report_data["frequency_analysis"]
    ai = report_data["ai_result"]
    findings = report_data["findings"]
    recommendations = report_data["recommendations"]
    limitations = report_data["limitations"]
    case_summary_en = report_data.get("case_summary_en", "")
    case_summary_ar = report_data.get("case_summary_ar", "")

    story: list[object] = []
    _header(story, s["title"], s["subtitle"], s["body"], report_data, "Approved")

    top_row = Table(
        [[_patient_table(patient, recording, small=True), _styled(Table(_ai_rows(ai), colWidths=[34 * mm, 40 * mm]))]],
        colWidths=[106 * mm, 78 * mm],
    )
    top_row.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
    story.extend([top_row, Spacer(1, 4)])
    story.extend([Paragraph("EXECUTIVE SUMMARY", s["section"]), _summary_box(report_data, s["body"]), Spacer(1, 4)])

    summary_kpis = Table(
        [[
            _styled(Table(_measurement_rows(measurements)[:4], colWidths=[26 * mm, 24 * mm, 32 * mm])),
            _styled(Table(_findings_rows(findings, 4), colWidths=[42 * mm, 32 * mm, 16 * mm]), fontsize=7),
        ]],
        colWidths=[84 * mm, 100 * mm],
    )
    summary_kpis.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
    story.extend([summary_kpis, Spacer(1, 3)])
    story.extend([Paragraph("RECOMMENDED NEXT STEPS", s["section"]), _styled(Table(_recommendation_rows(recommendations, 4), colWidths=[58 * mm, 126 * mm]))])

    story.append(PageBreak())
    story.extend([Paragraph("DETAILED ECG ANALYSIS", s["title"]), Spacer(1, 3)])
    if "main_ecg" in charts:
        story.extend([Paragraph("MAIN ECG VISUALIZATION", s["section"]), Image(io.BytesIO(charts["main_ecg"]), width=184 * mm, height=98 * mm), Spacer(1, 3)])
    if "supporting_graphs" in charts:
        story.extend([Paragraph("SUPPORTING ECG GRAPHS", s["section"]), Image(io.BytesIO(charts["supporting_graphs"]), width=184 * mm, height=74 * mm), Spacer(1, 3)])
    if "morphology" in charts:
        story.extend([Paragraph("REPRESENTATIVE MORPHOLOGY", s["section"]), Image(io.BytesIO(charts["morphology"]), width=184 * mm, height=62 * mm), Spacer(1, 3)])
    story.extend(
        [
            Paragraph("VISUAL INTERPRETATION NOTES", s["section"]),
            _styled(Table(_medical_note_rows(measurements, ai, quality), colWidths=[38 * mm, 146 * mm]), fontsize=7),
        ]
    )

    story.append(PageBreak())
    story.extend([Paragraph("HRV + INTERVAL + AI VISUALS", s["title"]), Spacer(1, 3)])
    if "hrv_graphs" in charts:
        story.extend([Paragraph("HEART RATE / HRV ANALYSIS", s["section"]), Image(io.BytesIO(charts["hrv_graphs"]), width=184 * mm, height=80 * mm), Spacer(1, 3)])
    if "interval_profile" in charts:
        story.extend([Paragraph("INTERVAL PROFILE", s["section"]), Image(io.BytesIO(charts["interval_profile"]), width=184 * mm, height=70 * mm), Spacer(1, 3)])
    if "physiology_ai" in charts:
        story.extend([Paragraph("AI / PHYSIOLOGY VISUALS", s["section"]), Image(io.BytesIO(charts["physiology_ai"]), width=184 * mm, height=72 * mm), Spacer(1, 3)])
    elif "clinical_metrics" in charts:
        story.extend([Paragraph("CLINICAL METRICS OVERVIEW", s["section"]), Image(io.BytesIO(charts["clinical_metrics"]), width=184 * mm, height=68 * mm), Spacer(1, 3)])
    if "risk_profile" in charts or "threshold" in charts:
        ai_visuals: list[object] = []
        if "risk_profile" in charts:
            ai_visuals.append(Image(io.BytesIO(charts["risk_profile"]), width=88 * mm, height=42 * mm))
        if "threshold" in charts:
            ai_visuals.append(Image(io.BytesIO(charts["threshold"]), width=88 * mm, height=30 * mm))
        if len(ai_visuals) == 2:
            ai_panel = Table([[ai_visuals[0], ai_visuals[1]]], colWidths=[92 * mm, 92 * mm])
            ai_panel.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
            story.extend([Paragraph("AI DECISION VISUALS", s["section"]), ai_panel])
        elif ai_visuals:
            story.extend([Paragraph("AI DECISION VISUALS", s["section"]), ai_visuals[0]])

    story.append(PageBreak())
    story.extend([Paragraph("AI & EVIDENCE ANALYSIS", s["title"]), Spacer(1, 3)])
    ai_table = _styled(Table(_ai_rows(ai), colWidths=[56 * mm, 34 * mm]))
    threshold = Image(io.BytesIO(charts["threshold"]), width=88 * mm, height=30 * mm) if "threshold" in charts else _styled(Table([["Score", _fmt(ai.get("model_score_pct"), "%")], ["Threshold", _fmt(ai.get("decision_threshold"), "", 3)]], colWidths=[40 * mm, 40 * mm]))
    risk_profile = Image(io.BytesIO(charts["risk_profile"]), width=88 * mm, height=40 * mm) if "risk_profile" in charts else _styled(Table([["Raw", _fmt(ai.get("raw_probability"))], ["Calibrated", _fmt(ai.get("calibrated_probability"))]], colWidths=[40 * mm, 40 * mm]))
    top_ai = Table([[ai_table, Table([[threshold], [risk_profile]], colWidths=[88 * mm])]], colWidths=[92 * mm, 92 * mm])
    top_ai.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
    story.extend([top_ai, Spacer(1, 3)])

    if "explainability" in charts:
        story.extend([Paragraph("MODEL EXPLAINABILITY", s["section"]), Image(io.BytesIO(charts["explainability"]), width=164 * mm, height=52 * mm), Spacer(1, 3)])

    story.extend([Paragraph("EVIDENCE SUMMARY", s["section"]), _styled(Table(_evidence_rows(findings, 7), colWidths=[34 * mm, 24 * mm, 28 * mm, 52 * mm, 46 * mm]), fontsize=7), Spacer(1, 3)])
    story.extend([Paragraph("OVERALL ASSESSMENT", s["section"]), _assessment_block(ai, findings, report_data["priority"]), Spacer(1, 3)])

    story.append(PageBreak())
    story.extend([Paragraph("CLINICAL INTERPRETATION SHEET", s["title"]), Spacer(1, 3)])
    if "physiology_ai" in charts:
        story.extend([Paragraph("PHYSIOLOGY / AI OVERVIEW", s["section"]), Image(io.BytesIO(charts["physiology_ai"]), width=184 * mm, height=72 * mm), Spacer(1, 3)])
    if "interval_profile" in charts:
        story.extend([Paragraph("INTERVAL REVIEW VISUALS", s["section"]), Image(io.BytesIO(charts["interval_profile"]), width=184 * mm, height=70 * mm), Spacer(1, 3)])
    story.extend(
        [
            Paragraph("CLINICAL INTERPRETATION", s["section"]),
            _styled(Table(_clinical_interpretation_rows(measurements, ai, quality, findings), colWidths=[42 * mm, 142 * mm]), fontsize=7),
            Spacer(1, 3),
            Paragraph("LIMITATIONS", s["section"]),
            _styled(Table(_limitations_rows(limitations), colWidths=[60 * mm, 124 * mm])),
            Spacer(1, 3),
            Paragraph("CASE SUMMARY / ملخص الحالة", s["section"]),
            _styled(
                Table(
                    [
                        ["English", case_summary_en or "-"],
                        ["Arabic", case_summary_ar or "-"],
                    ],
                    colWidths=[28 * mm, 156 * mm],
                ),
                header_bg="#ffffff",
            ),
            Spacer(1, 3),
            Paragraph("CLINICAL DISCLAIMER", s["section"]),
            Paragraph("Research-use AI-assisted ECG screening report. Automated measurements and model-derived scores require independent clinical review.", s["tiny"]),
        ]
    )
    return story


VARIANT_BUILDERS["approved"] = _build_story_approved


def generate_report_variant(report_path: Path, context: dict[str, Any], variant: str) -> dict[str, Any]:
    if variant not in VARIANT_BUILDERS:
        raise ValueError(f"Unknown report variant: {variant}")
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_data = build_report_data(context)
    charts = build_report_charts(context, report_data)
    story = VARIANT_BUILDERS[variant](report_data, charts)
    doc = SimpleDocTemplate(str(report_path), pagesize=A4, rightMargin=12 * mm, leftMargin=12 * mm, topMargin=10 * mm, bottomMargin=10 * mm)
    doc.build(story)
    return {"variant": variant, "report_path": str(report_path), "charts": sorted(charts.keys())}


def generate_report_variants(output_dir: Path, file_stem: str, context: dict[str, Any]) -> list[dict[str, Any]]:
    output_dir.mkdir(parents=True, exist_ok=True)
    results: list[dict[str, Any]] = []
    for variant in VARIANT_BUILDERS:
        target = output_dir / f"{file_stem}_{variant}.pdf"
        results.append(generate_report_variant(target, context, variant))
    return results
