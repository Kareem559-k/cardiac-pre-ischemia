from __future__ import annotations

import math
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont


WIDTH = 1280
HEIGHT = 720
FPS = 30
OUTPUT = Path(r"D:\STEM\cardiac_pre_ischemia_demo.mp4")


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        r"C:\Windows\Fonts\bahnschrift.ttf",
        r"C:\Windows\Fonts\arialbd.ttf" if bold else r"C:\Windows\Fonts\arial.ttf",
        r"C:\Windows\Fonts\segoeui.ttf",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


FONT_TITLE = load_font(46, bold=True)
FONT_SUB = load_font(24)
FONT_TEXT = load_font(20)
FONT_SMALL = load_font(16)
FONT_BOLD = load_font(22, bold=True)


SCENES = [
    {
        "title": "Cardiac Pre-Ischemia",
        "subtitle": "Secure login and physician-grade ECG workflow",
        "label": "1. Welcome & Sign-In",
        "bullets": ["Role-based access", "Fast patient onboarding", "Protected medical workflow"],
        "accent": (54, 198, 255),
    },
    {
        "title": "Doctor Dashboard",
        "subtitle": "Active patients, alerts, and review queue in one screen",
        "label": "2. Doctor Control Center",
        "bullets": ["Live patient list", "High-risk alerts", "Pending ECG reviews"],
        "accent": (51, 214, 159),
    },
    {
        "title": "Live ECG Monitoring",
        "subtitle": "Real-time waveform, BPM, and signal quality tracking",
        "label": "3. Wearable ECG Stream",
        "bullets": ["Waveform feed", "Heart rate 78 BPM", "Signal quality 97%"],
        "accent": (255, 198, 109),
    },
    {
        "title": "AI Clinical Analysis",
        "subtitle": "Model confidence, extracted metrics, and case-level risk scoring",
        "label": "4. AI Interpretation",
        "bullets": ["AI confidence 96.8%", "Risk level: Medium", "Clinical summary ready"],
        "accent": (255, 107, 129),
    },
    {
        "title": "PDF Report Generation",
        "subtitle": "Shareable medical report with charts, findings, and recommendations",
        "label": "5. Final Case Report",
        "bullets": ["Doctor-ready PDF", "Charts and tables", "Exported instantly"],
        "accent": (122, 155, 255),
    },
]


def rounded_rect(draw: ImageDraw.ImageDraw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def draw_waveform(draw: ImageDraw.ImageDraw, x0, y0, w, h, accent, phase):
    points = []
    for i in range(w):
        t = (i / w) * 6.5 * math.pi + phase
        base = math.sin(t) * 0.14 + math.sin(t * 0.35) * 0.08
        spike = 0.0
        mod = (i + int(phase * 20)) % 230
        if 76 <= mod <= 83:
            spike = 1.1 - abs(mod - 79) / 4.5
        y = y0 + h / 2 - (base + spike) * (h * 0.34)
        points.append((x0 + i, y))
    draw.line(points, fill=accent, width=4)


def draw_metric(draw, x, y, w, h, title, value, accent):
    rounded_rect(draw, (x, y, x + w, y + h), 18, (255, 255, 255), outline=(220, 231, 242))
    draw.text((x + 18, y + 14), title, font=FONT_SMALL, fill=(99, 118, 138))
    draw.text((x + 18, y + 40), value, font=FONT_BOLD, fill=accent)


def draw_phone_mockup(scene, progress):
    img = Image.new("RGB", (WIDTH, HEIGHT), (245, 249, 253))
    draw = ImageDraw.Draw(img)

    accent = scene["accent"]
    accent_dark = tuple(max(0, c - 70) for c in accent)

    for gx in range(0, WIDTH, 36):
        draw.line((gx, 0, gx, HEIGHT), fill=(229, 237, 245), width=1)
    for gy in range(0, HEIGHT, 36):
        draw.line((0, gy, WIDTH, gy), fill=(229, 237, 245), width=1)

    draw.ellipse((WIDTH - 270, -120, WIDTH - 20, 120), fill=(225, 243, 255))
    draw.ellipse((-130, HEIGHT - 220, 150, HEIGHT + 30), fill=(231, 248, 242))

    phone_x = 340
    phone_y = 40
    phone_w = 600
    phone_h = 640

    rounded_rect(draw, (phone_x, phone_y, phone_x + phone_w, phone_y + phone_h), 42, (15, 27, 40))
    rounded_rect(draw, (phone_x + 18, phone_y + 18, phone_x + phone_w - 18, phone_y + phone_h - 18), 34, (250, 252, 255))
    rounded_rect(draw, (phone_x + 215, phone_y + 26, phone_x + 385, phone_y + 42), 9, (19, 30, 44))

    draw.text((86, 78), "Cardiac Pre-Ischemia", font=FONT_TITLE, fill=(15, 31, 51))
    draw.text((86, 132), "AI-powered wearable ECG monitoring demo", font=FONT_SUB, fill=(91, 110, 130))

    left_y = 210
    draw.text((86, left_y), scene["label"], font=FONT_BOLD, fill=accent_dark)
    draw.text((86, left_y + 44), scene["title"], font=FONT_TITLE, fill=(15, 31, 51))
    draw.text((86, left_y + 104), scene["subtitle"], font=FONT_SUB, fill=(99, 118, 138))

    bullet_y = left_y + 170
    for bullet in scene["bullets"]:
        draw.ellipse((92, bullet_y + 7, 104, bullet_y + 19), fill=accent)
        draw.text((118, bullet_y), bullet, font=FONT_TEXT, fill=(29, 45, 62))
        bullet_y += 44

    rounded_rect(draw, (86, 500, 282, 552), 26, accent, outline=accent)
    draw.text((126, 515), "Watch Demo", font=FONT_BOLD, fill=(255, 255, 255))

    rounded_rect(draw, (phone_x + 46, phone_y + 74, phone_x + phone_w - 46, phone_y + 150), 26, (255, 255, 255), outline=(225, 234, 243))
    draw.text((phone_x + 70, phone_y + 96), scene["title"], font=FONT_BOLD, fill=(15, 31, 51))
    draw.text((phone_x + 70, phone_y + 126), scene["label"], font=FONT_SMALL, fill=accent_dark)

    card_x = phone_x + 46
    card_y = phone_y + 176
    card_w = phone_w - 92
    card_h = 248
    rounded_rect(draw, (card_x, card_y, card_x + card_w, card_y + card_h), 28, (255, 255, 255), outline=(225, 234, 243))

    graph_x = card_x + 26
    graph_y = card_y + 30
    graph_w = card_w - 52
    graph_h = 112
    rounded_rect(draw, (graph_x, graph_y, graph_x + graph_w, graph_y + graph_h), 18, (243, 249, 253))
    draw_waveform(draw, graph_x + 18, graph_y + 10, graph_w - 36, graph_h - 20, accent, progress * 4.8)

    draw_metric(draw, card_x + 26, card_y + 160, 150, 68, "Heartbeat", "78 BPM", accent_dark)
    draw_metric(draw, card_x + 192, card_y + 160, 150, 68, "AI Status", "Active", accent_dark)
    draw_metric(draw, card_x + 358, card_y + 160, 150, 68, "Signal", "97%", accent_dark)

    table_y = phone_y + 448
    rounded_rect(draw, (phone_x + 46, table_y, phone_x + phone_w - 46, table_y + 132), 24, (255, 255, 255), outline=(225, 234, 243))
    draw.text((phone_x + 68, table_y + 18), "Clinical Snapshot", font=FONT_BOLD, fill=(15, 31, 51))
    rows = [("Risk", "Medium"), ("Confidence", "96.8%"), ("Report", "Prepared")]
    for idx, (k, v) in enumerate(rows):
        y = table_y + 52 + idx * 24
        draw.text((phone_x + 68, y), k, font=FONT_SMALL, fill=(99, 118, 138))
        draw.text((phone_x + 210, y), v, font=FONT_SMALL, fill=accent_dark)

    cursor_x = int(phone_x + 120 + 280 * min(progress, 1.0))
    cursor_y = int(phone_y + 540 - 30 * math.sin(progress * math.pi))
    draw.polygon(
        [
            (cursor_x, cursor_y),
            (cursor_x + 18, cursor_y + 8),
            (cursor_x + 8, cursor_y + 18),
        ],
        fill=(20, 25, 32),
    )

    return np.array(img)


def make_video():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    writer = cv2.VideoWriter(
        str(OUTPUT),
        cv2.VideoWriter_fourcc(*"mp4v"),
        FPS,
        (WIDTH, HEIGHT),
    )
    if not writer.isOpened():
        raise RuntimeError("Failed to open video writer")

    scene_seconds = 3.4
    frames_per_scene = int(FPS * scene_seconds)

    for scene in SCENES:
        for frame_idx in range(frames_per_scene):
            progress = frame_idx / max(1, frames_per_scene - 1)
            frame = draw_phone_mockup(scene, progress)
            writer.write(cv2.cvtColor(frame, cv2.COLOR_RGB2BGR))

    writer.release()
    print(OUTPUT)


if __name__ == "__main__":
    make_video()
