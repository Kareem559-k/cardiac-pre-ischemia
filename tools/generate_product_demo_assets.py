from __future__ import annotations

import math
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont


OUT_VIDEO = Path(r"D:\STEM\CARDIAC_PRE_ISCHEMIA_PRODUCT_DEMO.mp4")
OUT_STORYBOARD = Path(r"D:\STEM\CARDIAC_PRE_ISCHEMIA_STORYBOARD.md")

WIDTH = 1280
HEIGHT = 720
FPS = 30


SCENES = [
    {
        "id": "01",
        "title": "Opening Identity",
        "duration": 6,
        "headline": "CARDIAC PRE-ISCHEMIA",
        "subheadline": "AI-Assisted ECG Analysis for Early Cardiac Ischemia Risk Screening",
        "status": "Verified product identity",
        "source": "Verified from Flutter web build strings",
        "narration": "Cardiac Pre-Ischemia is a research prototype for AI-assisted ECG screening and early-risk review.",
        "accent": (54, 198, 255),
        "type": "opening",
    },
    {
        "id": "02",
        "title": "Clinical Problem",
        "duration": 8,
        "headline": "Investigating subtle ECG patterns before critical cardiac deterioration",
        "subheadline": "Research-oriented screening support, not autonomous diagnosis",
        "status": "Scientific framing only",
        "source": "Project positioning + user requirements",
        "narration": "The system is designed to inspect ECG patterns associated with elevated cardiac risk and support clinical review.",
        "accent": (70, 224, 255),
        "type": "problem",
    },
    {
        "id": "03",
        "title": "Wearable Layer",
        "duration": 8,
        "headline": "Wearable ECG acquisition layer",
        "subheadline": "Prototype / planned integration",
        "status": "Prototype",
        "source": "Existing live monitoring screen + project architecture",
        "narration": "A wearable ECG layer can acquire signals and route them to the mobile workflow. Physical integration is presented as a prototype layer where needed.",
        "accent": (64, 196, 255),
        "type": "wearable",
    },
    {
        "id": "04",
        "title": "Application Entry",
        "duration": 10,
        "headline": "Mobile application workflow",
        "subheadline": "Welcome, role selection, login, and secure access",
        "status": "Verified UI flow",
        "source": "Flutter pages: Splash, Login, Register, RoleSelection",
        "narration": "Users enter through a structured workflow that supports both patient and doctor access.",
        "accent": (54, 198, 255),
        "type": "app",
    },
    {
        "id": "05",
        "title": "ECG Input",
        "duration": 8,
        "headline": "ECG input pathways",
        "subheadline": "WFDB files, images, conversion workflow, and wearable-oriented entry points",
        "status": "Verified backend + UI flow",
        "source": "Endpoints /analyze_files, /analyze_image, /ecg/convert-image-to-wfdb",
        "narration": "The platform accepts ECG files and ECG images, with conversion and upload flows exposed in the application and backend.",
        "accent": (72, 219, 251),
        "type": "input",
    },
    {
        "id": "06",
        "title": "ECG Visualization",
        "duration": 9,
        "headline": "Waveform-first review experience",
        "subheadline": "ECG waveform, motion, and visual review framing",
        "status": "Verified UI pattern",
        "source": "Patient live screen + analysis UI",
        "narration": "Signals are presented visually so the user can inspect the ECG before and after automated analysis.",
        "accent": (95, 209, 255),
        "type": "waveform",
    },
    {
        "id": "07",
        "title": "AI Pipeline",
        "duration": 10,
        "headline": "Verified backend analysis pipeline",
        "subheadline": "Raw ECG to preprocessing, feature extraction, model inference, and risk output",
        "status": "Verified backend",
        "source": "main.py + ecg_pipeline.py + /health",
        "narration": "The backend runs a structured ECG pipeline, then sends the processed result into the deployed model and risk-assessment output path.",
        "accent": (51, 214, 159),
        "type": "pipeline",
    },
    {
        "id": "08",
        "title": "Analysis Output",
        "duration": 9,
        "headline": "Model-backed result screen",
        "subheadline": "Classification, quality indicators, measurements, and recommendations",
        "status": "Verified backend schema",
        "source": "AnalysisResponse fields in backend",
        "narration": "When analysis completes, the application can display classification, signal quality, ECG measurements, and review recommendations.",
        "accent": (255, 198, 109),
        "type": "results",
    },
    {
        "id": "09",
        "title": "Scientific Graphs",
        "duration": 8,
        "headline": "Graphs and waveform context",
        "subheadline": "Waveform, intervals, peaks, trend context, and report visuals",
        "status": "Verified report/analysis context",
        "source": "graphData + report context builder",
        "narration": "Graph-rich visuals help translate analysis into interpretable signal context for research and review.",
        "accent": (122, 155, 255),
        "type": "graphs",
    },
    {
        "id": "10",
        "title": "Clinical-Style PDF Report",
        "duration": 10,
        "headline": "Automated PDF reporting",
        "subheadline": "Patient summary, ECG findings, AI result, graphs, and next steps",
        "status": "Verified report generator",
        "source": "Endpoints /reports/generate and approved report layout",
        "narration": "A structured PDF report is generated to support physician-ready review and presentation use.",
        "accent": (255, 107, 129),
        "type": "report",
    },
    {
        "id": "11",
        "title": "Doctor Workflow",
        "duration": 9,
        "headline": "Doctor-side review workflow",
        "subheadline": "Patient list, reports, history, and analysis review",
        "status": "Verified pages + backend",
        "source": "DoctorDashboard, DoctorReportsPage, patient endpoints",
        "narration": "On the doctor side, the system supports patient tracking, report access, and review-oriented navigation.",
        "accent": (51, 214, 159),
        "type": "doctor",
    },
    {
        "id": "12",
        "title": "Patient Follow-Up",
        "duration": 8,
        "headline": "Patient-side follow-up",
        "subheadline": "History, reports, appointments, messages, and monitoring access",
        "status": "Verified pages + endpoints",
        "source": "PatientHome, history/reports/messages/appointments backend routes",
        "narration": "The patient workflow supports follow-up, prior reports, communication, and future monitoring sessions.",
        "accent": (54, 198, 255),
        "type": "patient",
    },
    {
        "id": "13",
        "title": "Complete System Architecture",
        "duration": 8,
        "headline": "Wearable to clinician review",
        "subheadline": "ECG -> App -> Backend -> AI -> Report -> Doctor review",
        "status": "Verified + prototype mix",
        "source": "Frontend + backend + project architecture",
        "narration": "The complete ecosystem connects signal capture, mobile workflows, backend analysis, reporting, and clinician-facing review.",
        "accent": (86, 214, 255),
        "type": "architecture",
    },
    {
        "id": "14",
        "title": "Final Shot",
        "duration": 6,
        "headline": "CARDIAC PRE-ISCHEMIA",
        "subheadline": "From ECG signals to intelligent early-risk screening",
        "status": "Verified product identity",
        "source": "Project identity",
        "narration": "Cardiac Pre-Ischemia transforms ECG signals into structured insight for early-risk screening and clinical review support.",
        "accent": (54, 198, 255),
        "type": "finale",
    },
]


def font(size: int, bold: bool = False):
    paths = [
        r"C:\Windows\Fonts\bahnschrift.ttf",
        r"C:\Windows\Fonts\arialbd.ttf" if bold else r"C:\Windows\Fonts\arial.ttf",
        r"C:\Windows\Fonts\segoeui.ttf",
    ]
    for path in paths:
        try:
            return ImageFont.truetype(path, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


F_TITLE = font(44, True)
F_HEAD = font(34, True)
F_SUB = font(22, False)
F_TEXT = font(18, False)
F_SMALL = font(15, False)
F_LABEL = font(16, True)


def rr(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def draw_bg(draw, t):
    bg = (7, 17, 28)
    draw.rectangle((0, 0, WIDTH, HEIGHT), fill=bg)
    for x in range(0, WIDTH, 38):
        alpha = 28 if x % 76 == 0 else 14
        draw.line((x, 0, x, HEIGHT), fill=(18, 39, 58, alpha), width=1)
    for y in range(0, HEIGHT, 38):
        alpha = 28 if y % 76 == 0 else 14
        draw.line((0, y, WIDTH, y), fill=(18, 39, 58, alpha), width=1)
    orb_shift = int(math.sin(t * 0.7) * 12)
    draw.ellipse((900 + orb_shift, -120, 1260 + orb_shift, 240), fill=(10, 55, 82))
    draw.ellipse((-120, 430 - orb_shift, 220, 820 - orb_shift), fill=(11, 42, 53))


def pulse_wave(draw, x0, y0, w, h, color, phase, thick=4):
    pts = []
    for i in range(w):
        t = phase + i / w * 6.6 * math.pi
        base = math.sin(t) * 0.12 + math.sin(t * 0.42) * 0.08
        mod = (i + int(phase * 30)) % 220
        spike = 0.0
        if 72 <= mod <= 82:
            spike = 1.22 - abs(mod - 77) / 4.0
        y = y0 + h / 2 - (base + spike) * h * 0.36
        pts.append((x0 + i, y))
    draw.line(pts, fill=color, width=thick)


def draw_device(draw, x, y, w, h, scene, p):
    rr(draw, (x, y, x + w, y + h), 42, (11, 23, 35))
    rr(draw, (x + 16, y + 16, x + w - 16, y + h - 16), 34, (248, 251, 255))
    rr(draw, (x + w / 2 - 82, y + 28, x + w / 2 + 82, y + 42), 9, (15, 25, 37))
    accent = scene["accent"]
    dark_accent = tuple(max(0, c - 70) for c in accent)

    rr(draw, (x + 32, y + 72, x + w - 32, y + 148), 22, (255, 255, 255), outline=(225, 234, 243))
    draw.text((x + 56, y + 94), "Cardiac Pre-Ischemia", font=F_LABEL, fill=(15, 31, 51))
    draw.text((x + 56, y + 118), scene["title"], font=F_SMALL, fill=dark_accent)

    rr(draw, (x + 32, y + 170, x + w - 32, y + 410), 28, (255, 255, 255), outline=(225, 234, 243))
    rr(draw, (x + 56, y + 196, x + w - 56, y + 318), 18, (243, 248, 252))
    pulse_wave(draw, x + 72, y + 214, w - 144, 84, accent, p * 4.7)
    draw.text((x + 56, y + 336), scene["headline"][:38], font=F_SMALL, fill=(15, 31, 51))
    draw.text((x + 56, y + 360), scene["subheadline"][:52], font=F_SMALL, fill=(98, 117, 137))

    metric_titles = ["Workflow", "Status", "Source"]
    metric_values = [
        scene["status"].replace("Verified ", ""),
        "Verified" if "Verified" in scene["status"] else "Prototype",
        "Project data",
    ]
    mx = x + 32
    my = y + 432
    mw = (w - 80) / 3
    for i, (mt, mv) in enumerate(zip(metric_titles, metric_values)):
        left = mx + i * (mw + 8)
        rr(draw, (left, my, left + mw, my + 86), 18, tuple(c + 10 for c in accent), outline=accent)
        draw.text((left + 14, my + 12), mt, font=F_SMALL, fill=(245, 249, 255))
        draw.text((left + 14, my + 42), mv[:18], font=F_LABEL, fill=(255, 255, 255))


def card(draw, x, y, w, h, title, text, accent):
    rr(draw, (x, y, x + w, y + h), 26, (9, 21, 34), outline=(30, 56, 77))
    rr(draw, (x + 20, y + 18, x + 122, y + 48), 15, accent, outline=accent)
    draw.text((x + 34, y + 25), title, font=F_SMALL, fill=(255, 255, 255))
    draw.multiline_text((x + 24, y + 68), text, font=F_TEXT, fill=(225, 237, 246), spacing=5)


def create_frame(scene, local_p):
    img = Image.new("RGB", (WIDTH, HEIGHT), (7, 17, 28))
    draw = ImageDraw.Draw(img)
    draw_bg(draw, local_p * 2.5)
    accent = scene["accent"]
    accent_dark = tuple(max(0, c - 55) for c in accent)

    draw.text((68, 62), scene["headline"], font=F_TITLE, fill=(245, 250, 255))
    draw.text((70, 126), scene["subheadline"], font=F_SUB, fill=(169, 189, 206))

    rr(draw, (70, 170, 236, 206), 18, accent, outline=accent)
    draw.text((92, 179), f"SCENE {scene['id']}", font=F_SMALL, fill=(255, 255, 255))

    if scene["type"] in {"opening", "finale"}:
        pulse_wave(draw, 100, 292, 1080, 120, accent, local_p * 6.0, 5)
        rr(draw, (82, 430, 582, 578), 34, (10, 25, 39), outline=(30, 58, 78))
        draw.text((114, 464), "Research positioning", font=F_LABEL, fill=accent)
        draw.multiline_text(
            (114, 502),
            "AI-assisted screening\nSupport for clinical review\nNot a replacement for physicians",
            font=F_TEXT,
            fill=(226, 239, 246),
            spacing=6,
        )
        rr(draw, (640, 430, 1180, 578), 34, (10, 25, 39), outline=(30, 58, 78))
        draw.text((670, 464), "Source", font=F_LABEL, fill=accent)
        draw.multiline_text((670, 502), scene["source"], font=F_TEXT, fill=(226, 239, 246), spacing=6)
    elif scene["type"] == "problem":
        card(draw, 70, 210, 450, 220, "Clinical Aim", "Investigate subtle ECG patterns that may support early review of elevated cardiac-ischemia risk.", accent)
        rr(draw, (610, 210, 1170, 590), 38, (10, 24, 38), outline=(30, 58, 78))
        draw.text((662, 250), "HEART  ->  ECG  ->  REVIEW", font=F_LABEL, fill=accent)
        pulse_wave(draw, 650, 328, 450, 120, accent, local_p * 5.4, 4)
        draw.text((650, 484), "Research screening system", font=F_HEAD, fill=(245, 250, 255))
        draw.text((650, 530), "Scientifically responsible framing only", font=F_SUB, fill=(169, 189, 206))
    elif scene["type"] == "wearable":
        rr(draw, (90, 210, 480, 600), 42, (10, 25, 39), outline=(30, 58, 78))
        draw.text((138, 248), "Wearable ECG layer", font=F_HEAD, fill=(245, 250, 255))
        draw.text((138, 300), "Prototype / planned integration", font=F_SUB, fill=accent)
        for idx, txt in enumerate(["ECG sensors", "Signal acquisition", "Wireless transmission"]):
            y = 370 + idx * 70
            rr(draw, (136, y, 416, y + 48), 16, (15, 36, 55), outline=accent)
            draw.text((158, y + 13), txt, font=F_TEXT, fill=(230, 239, 246))
        rr(draw, (620, 190, 1120, 610), 46, (248, 251, 255), outline=(225, 234, 243))
        draw.ellipse((760, 250, 980, 470), outline=accent_dark, width=5)
        draw.line((825, 295, 825, 425), fill=accent_dark, width=8)
        draw.line((915, 295, 915, 425), fill=accent_dark, width=8)
        draw.line((825, 340, 915, 340), fill=accent_dark, width=8)
        draw.text((710, 520), "Architecture shown honestly as prototype", font=F_TEXT, fill=(99, 118, 138))
    elif scene["type"] in {"app", "input", "waveform", "results", "graphs", "doctor", "patient"}:
        draw_device(draw, 670, 42, 520, 636, scene, local_p)
        card(draw, 68, 226, 520, 158, "Verification", f"Status: {scene['status']}\nSource: {scene['source']}", accent)
        card(draw, 68, 408, 520, 220, "Narration cue", scene["narration"], accent)
    elif scene["type"] == "pipeline":
        flow = [
            "Raw ECG",
            "Preprocessing",
            "Feature extraction",
            "Model inference",
            "Risk output",
            "Report context",
        ]
        x = 92
        for idx, step in enumerate(flow):
            rr(draw, (x, 280, x + 150, 348), 24, accent if idx in {1, 3} else (12, 28, 44), outline=accent)
            draw.text((x + 20, 304), step, font=F_SMALL, fill=(255, 255, 255))
            if idx < len(flow) - 1:
                draw.line((x + 150, 314, x + 190, 314), fill=accent, width=4)
            x += 190
        card(draw, 90, 420, 480, 166, "Backend verification", "Health endpoint confirms loaded model and pipeline.\nModel: ECG_MODEL_V15_FINAL\nPipeline: wfdb_v15_verified_inference", accent)
        card(draw, 700, 420, 480, 166, "Implemented paths", "WFDB loading\nImage-to-signal extraction\nAnalysis storage\nPDF report generation", accent)
    elif scene["type"] == "report":
        rr(draw, (710, 110, 1110, 630), 22, (255, 255, 255), outline=(226, 234, 243))
        draw.text((748, 150), "Cardiac Pre-Ischemia Analysis Report", font=F_LABEL, fill=(15, 31, 51))
        row_y = 206
        for label, value in [
            ("Patient", "Demo patient"),
            ("Source", "Verified backend report flow"),
            ("Summary", "ECG review + AI-assisted output"),
            ("Graphs", "Waveform / context visuals"),
            ("Next steps", "Clinical review recommended"),
        ]:
            draw.text((748, row_y), label, font=F_SMALL, fill=(94, 114, 135))
            draw.text((900, row_y), value, font=F_SMALL, fill=(20, 35, 50))
            draw.line((744, row_y + 26, 1080, row_y + 26), fill=(229, 235, 241), width=1)
            row_y += 56
        card(draw, 72, 230, 540, 270, "Report generation", "The backend exposes report generation, patient report retrieval, and downloadable PDF output tied to analysis sessions.", accent)
    elif scene["type"] == "architecture":
        layers = [
            "Wearable / prototype layer",
            "ECG input",
            "Mobile app",
            "Backend API",
            "Signal processing",
            "AI model",
            "PDF report",
            "Doctor review",
        ]
        y = 180
        for step in layers:
            rr(draw, (430, y, 850, y + 42), 18, (12, 28, 44), outline=accent)
            draw.text((460, y + 12), step, font=F_TEXT, fill=(242, 248, 252))
            if y < 180 + (len(layers) - 1) * 60:
                draw.line((640, y + 42, 640, y + 60), fill=accent, width=4)
            y += 60
        draw.text((94, 570), "Verified application workflow + honest prototype framing", font=F_SUB, fill=(193, 211, 225))

    rr(draw, (68, 650, 410, 690), 16, (11, 27, 41), outline=(27, 51, 70))
    draw.text((84, 663), f"Verification: {scene['status']}", font=F_SMALL, fill=(212, 227, 238))
    rr(draw, (980, 650, 1212, 690), 16, accent, outline=accent)
    draw.text((1000, 663), "RESEARCH PROTOTYPE", font=F_SMALL, fill=(255, 255, 255))

    return np.array(img)


def render_video():
    OUT_VIDEO.parent.mkdir(parents=True, exist_ok=True)
    writer = cv2.VideoWriter(str(OUT_VIDEO), cv2.VideoWriter_fourcc(*"mp4v"), FPS, (WIDTH, HEIGHT))
    if not writer.isOpened():
        raise RuntimeError("Unable to open output video writer")

    transition = 0.45
    for scene in SCENES:
        frames = int(scene["duration"] * FPS)
        for i in range(frames):
            p = i / max(1, frames - 1)
            frame = create_frame(scene, p)
            writer.write(cv2.cvtColor(frame, cv2.COLOR_RGB2BGR))
        t_frames = int(transition * FPS)
        if scene is not SCENES[-1]:
            next_scene = SCENES[SCENES.index(scene) + 1]
            for i in range(t_frames):
                a = i / max(1, t_frames - 1)
                f1 = create_frame(scene, 1.0)
                f2 = create_frame(next_scene, 0.0)
                blend = (f1 * (1 - a) + f2 * a).astype(np.uint8)
                writer.write(cv2.cvtColor(blend, cv2.COLOR_RGB2BGR))
    writer.release()


def write_storyboard():
    lines = [
        "# CARDIAC PRE-ISCHEMIA Storyboard",
        "",
        "Generated on 2026-08-10",
        "",
        "| Scene | Duration (s) | Screen / Action | Narration | Visual Elements | Source of Data / Result | Verification Status |",
        "|---|---:|---|---|---|---|---|",
    ]
    for scene in SCENES:
        screen = f"{scene['title']} - {scene['headline']}"
        visuals = scene["subheadline"].replace("|", "/")
        lines.append(
            f"| {scene['id']} | {scene['duration']} | {screen} | {scene['narration']} | {visuals} | {scene['source']} | {scene['status']} |"
        )
    lines.extend(
        [
            "",
            "## Verification Notes",
            "",
            "- Frontend pages verified in project code: Login, Register, GuidedDemoPage, RoleSelectionPage, AnalysisHubPage, DoctorDashboard, PatientHome, PatientLiveScreen, PatientReportsPage, DoctorReportsPage, PatientHistoryPage, SessionLogPage.",
            "- Backend health verified on 2026-08-10: model loaded, database ok, pipeline ok.",
            "- Backend analysis/report features verified in code and API surface: image analysis, WFDB/file analysis, image-to-WFDB conversion, analysis retrieval, report generation, report download, patient history, patient trends, appointments, messages, monitoring, emergency logging.",
            "- Wearable integration is presented honestly as a prototype/planned integration layer where direct physical coupling is not fully demonstrated in this environment.",
            "- No fabricated diagnostic claims were added. The video language keeps the system framed as AI-assisted screening and research support.",
        ]
    )
    OUT_STORYBOARD.write_text("\n".join(lines), encoding="utf-8")


def main():
    write_storyboard()
    render_video()
    print(OUT_VIDEO)
    print(OUT_STORYBOARD)


if __name__ == "__main__":
    main()
