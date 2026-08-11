from __future__ import annotations

import math
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont


OUT = Path(r"D:\STEM\CARDIAC_PRE_ISCHEMIA_MOBILE_SCREEN_DEMO.mp4")
W = 1080
H = 1920
FPS = 30


def load_font(size: int, bold: bool = False):
    candidates = [
        r"C:\Windows\Fonts\bahnschrift.ttf",
        r"C:\Windows\Fonts\arialbd.ttf" if bold else r"C:\Windows\Fonts\arial.ttf",
        r"C:\Windows\Fonts\segoeui.ttf",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


F_TITLE = load_font(56, True)
F_H1 = load_font(42, True)
F_H2 = load_font(34, True)
F_TEXT = load_font(28, False)
F_SMALL = load_font(22, False)
F_BTN = load_font(30, True)


NAVY = (11, 31, 51)
NAVY_DARK = (7, 19, 31)
BG = (246, 250, 253)
SURFACE = (255, 255, 255)
BORDER = (220, 231, 241)
ACCENT = (54, 198, 255)
SUCCESS = (51, 214, 159)
WARNING = (255, 198, 109)
DANGER = (255, 107, 129)
TEXT2 = (96, 116, 136)


SCENES = [
    ("welcome", 4.0),
    ("login", 5.0),
    ("demo", 5.0),
    ("patient", 5.0),
    ("analysis", 5.5),
    ("upload", 4.0),
    ("results", 5.0),
    ("report", 5.0),
    ("doctor", 5.0),
]


PROTOTYPE_LABEL = "PROTOTYPE WALKTHROUGH"


def rr(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def shadow(draw, box, radius=30):
    x1, y1, x2, y2 = box
    for i in range(10):
        alpha = max(0, 20 - i * 2)
        rr(draw, (x1 - i, y1 - i, x2 + i, y2 + i), radius + i, (220, 232, 242, alpha))


def pill(draw, x, y, text, fill=(231, 247, 255), color=(31, 149, 199)):
    w = 24 + len(text) * 12
    rr(draw, (x, y, x + w, y + 44), 22, fill, outline=(201, 226, 243))
    draw.text((x + 14, y + 10), text, font=F_SMALL, fill=color)
    return w


def button(draw, x, y, w, h, text, filled=True):
    if filled:
        rr(draw, (x, y, x + w, y + h), 28, NAVY, outline=NAVY)
        draw.text((x + w / 2 - len(text) * 7.5, y + 18), text, font=F_BTN, fill=(255, 255, 255))
    else:
        rr(draw, (x, y, x + w, y + h), 28, SURFACE, outline=BORDER, width=2)
        draw.text((x + w / 2 - len(text) * 7.0, y + 18), text, font=F_BTN, fill=NAVY)


def status_bar(draw):
    draw.text((76, 52), "9:41", font=F_SMALL, fill=NAVY)
    draw.text((900, 52), "5G 100%", font=F_SMALL, fill=NAVY)


def app_header(draw, title, right_icons=True):
    status_bar(draw)
    rr(draw, (38, 90, W - 38, 210), 34, SURFACE, outline=BORDER)
    draw.text((W / 2 - len(title) * 12, 132), title, font=F_H2, fill=NAVY)
    rr(draw, (42, 112, 114, 184), 28, SURFACE, outline=BORDER)
    draw.text((64, 132), "<", font=F_H1, fill=NAVY)
    if right_icons:
        rr(draw, (W - 198, 112, W - 126, 184), 28, SURFACE, outline=BORDER)
        rr(draw, (W - 108, 112, W - 36, 184), 28, SURFACE, outline=BORDER)
        draw.text((W - 178, 132), "◧", font=F_TEXT, fill=NAVY)
        draw.text((W - 87, 132), "⚙", font=F_TEXT, fill=NAVY)


def prototype_banner(draw):
    rr(draw, (54, 216, 418, 260), 22, (255, 244, 232), outline=(255, 205, 145))
    draw.text((74, 228), PROTOTYPE_LABEL, font=F_SMALL, fill=(181, 98, 0))


def ecg_wave(draw, x, y, w, h, color, phase):
    pts = []
    for i in range(w):
        t = phase + i / w * 7 * math.pi
        base = math.sin(t) * 0.15 + math.sin(t * 0.35) * 0.08
        mod = (i + int(phase * 30)) % 240
        spike = 0.0
        if 80 <= mod <= 90:
            spike = 1.15 - abs(mod - 85) / 5
        py = y + h / 2 - (base + spike) * h * 0.34
        pts.append((x + i, py))
    draw.line(pts, fill=color, width=5)


def card_metric(draw, x, y, w, h, label, value, color):
    rr(draw, (x, y, x + w, y + h), 24, SURFACE, outline=BORDER)
    draw.text((x + 22, y + 18), label, font=F_SMALL, fill=TEXT2)
    draw.text((x + 22, y + 56), value, font=F_H2, fill=color)


def tap(draw, x, y, frame_p):
    r = 16 + int(frame_p * 42)
    alpha = max(20, 170 - int(frame_p * 150))
    draw.ellipse((x - r, y - r, x + r, y + r), outline=(54, 198, 255, alpha), width=4)
    draw.ellipse((x - 10, y - 10, x + 10, y + 10), fill=(20, 28, 36))


def render_screen(scene, p):
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)

    for gx in range(0, W, 54):
        draw.line((gx, 0, gx, H), fill=(233, 241, 247), width=1)
    for gy in range(0, H, 54):
        draw.line((0, gy, W, gy), fill=(233, 241, 247), width=1)

    if scene == "welcome":
        app_header(draw, "Cardiac Pre-Ischemia")
        prototype_banner(draw)
        rr(draw, (36, 246, W - 36, 1510), 40, SURFACE, outline=BORDER)
        rr(draw, (360, 318, 720, 678), 90, NAVY)
        draw.text((458, 446), "ECG", font=F_H1, fill=(255, 255, 255))
        pill(draw, 334, 734, "AI-Assisted ECG Analysis")
        draw.text((152, 846), "CARDIAC PRE-ISCHEMIA", font=F_TITLE, fill=NAVY)
        draw.multiline_text((120, 952), "Premium ECG intelligence for screening,\nmonitoring, and physician-ready reporting.", font=F_TEXT, fill=TEXT2, align="center", spacing=8)
        x = 46
        x += pill(draw, x, 1130, "Fast ECG Intake") + 14
        x += pill(draw, x, 1130, "Clinical Metrics") + 14
        pill(draw, x, 1130, "Shareable PDF Reports")
        button(draw, 46, 1298, W - 92, 86, "Enter Platform", True)
        button(draw, 46, 1412, W - 92, 86, "Explore Demo", False)
        if 0.3 < p < 0.9:
            tap(draw, W // 2, 1455, (p - 0.3) / 0.6)

    elif scene == "login":
        status_bar(draw)
        prototype_banner(draw)
        draw.text((114, 160), "SECURE CLINICAL ACCESS", font=F_SMALL, fill=ACCENT)
        draw.text((80, 236), "Cardiac Pre-Ischemia", font=F_H1, fill=NAVY)
        draw.multiline_text((80, 302), "Trusted access for patients, physicians,\nand supervised screening workflows.", font=F_TEXT, fill=TEXT2, spacing=8)
        rr(draw, (52, 480, W - 52, 1540), 38, SURFACE, outline=BORDER)
        draw.text((96, 540), "Sign in", font=F_H2, fill=NAVY)
        draw.text((96, 594), "Use your account to continue into the correct medical workflow.", font=F_SMALL, fill=TEXT2)
        rr(draw, (96, 702, W - 96, 800), 24, BG, outline=BORDER)
        draw.text((126, 736), "Mobile Number", font=F_SMALL, fill=TEXT2)
        draw.text((126, 768), "01012345678", font=F_TEXT, fill=NAVY)
        rr(draw, (96, 840, W - 96, 938), 24, BG, outline=BORDER)
        draw.text((126, 874), "Password", font=F_SMALL, fill=TEXT2)
        draw.text((126, 906), "••••••••", font=F_TEXT, fill=NAVY)
        button(draw, 96, 1046, W - 192, 86, "Continue to platform", True)
        button(draw, 96, 1164, W - 192, 86, "Create new account", False)
        rr(draw, (96, 1284, W - 96, 1352), 28, (234, 248, 255), outline=BORDER)
        draw.text((W / 2 - 115, 1306), "Watch full demo", font=F_BTN, fill=ACCENT)
        if 0.2 < p < 0.9:
            tap(draw, W // 2, 1320, (p - 0.2) / 0.7)

    elif scene == "demo":
        status_bar(draw)
        prototype_banner(draw)
        draw.text((390, 126), "Watch Demo", font=F_H2, fill=NAVY)
        draw.text((154, 176), "A cinematic walkthrough of the full medical workflow", font=F_SMALL, fill=TEXT2)
        rr(draw, (50, 246, W - 50, 1640), 42, SURFACE, outline=BORDER)
        draw.text((94, 308), "Doctor Dashboard", font=F_H1, fill=NAVY)
        draw.text((94, 368), "The doctor reviews active patients, pending reports,\nalerts, and recent ECG sessions from one command center.", font=F_TEXT, fill=TEXT2, spacing=8)
        rr(draw, (88, 506, W - 88, 1320), 34, (247, 251, 255), outline=BORDER)
        draw.text((120, 548), "Live feature walkthrough", font=F_SMALL, fill=SUCCESS)
        rr(draw, (120, 620, W - 120, 954), 28, SURFACE, outline=BORDER)
        ecg_wave(draw, 150, 690, W - 300, 190, SUCCESS, p * 6.0)
        card_metric(draw, 120, 998, 250, 118, "Workflow", "Preview", SUCCESS)
        card_metric(draw, 392, 998, 250, 118, "AI Status", "Available", SUCCESS)
        card_metric(draw, 664, 998, 250, 118, "Report", "Supported", ACCENT)
        draw.text((120, 1170), "Patient list", font=F_TEXT, fill=NAVY)
        draw.text((120, 1222), "Alert queue", font=F_TEXT, fill=NAVY)
        draw.text((120, 1274), "Quick review", font=F_TEXT, fill=NAVY)

    elif scene == "patient":
        app_header(draw, "Patient Home", False)
        prototype_banner(draw)
        rr(draw, (42, 252, W - 42, 430), 34, SURFACE, outline=BORDER)
        draw.text((84, 312), "Monitoring ready", font=F_H1, fill=NAVY)
        draw.text((84, 374), "History, live ECG, reports, and follow-up tools", font=F_SMALL, fill=TEXT2)
        rr(draw, (42, 474, W - 42, 850), 34, SURFACE, outline=BORDER)
        draw.text((84, 526), "Live ECG", font=F_H2, fill=NAVY)
        rr(draw, (84, 592, W - 84, 790), 26, (245, 250, 253), outline=BORDER)
        ecg_wave(draw, 110, 628, W - 220, 128, ACCENT, p * 5.0)
        card_metric(draw, 42, 894, 304, 116, "Care Owner", "Optional", WARNING)
        card_metric(draw, 388, 894, 304, 116, "Analysis", "Ready", ACCENT)
        card_metric(draw, 734, 894, 304, 116, "Reports", "Accessible", SUCCESS)
        button(draw, 72, 1080, W - 144, 84, "Open analysis workspace", True)

    elif scene == "analysis":
        app_header(draw, "Analysis Hub", False)
        prototype_banner(draw)
        rr(draw, (40, 248, W - 40, 1680), 36, SURFACE, outline=BORDER)
        draw.text((84, 304), "Select source", font=F_H2, fill=NAVY)
        draw.text((84, 354), "Image, upload, or live wearable session.", font=F_SMALL, fill=TEXT2)
        rr(draw, (84, 432, W - 84, 630), 30, (244, 250, 254), outline=BORDER)
        draw.text((126, 486), "ECG image", font=F_H2, fill=NAVY)
        draw.text((126, 540), "Upload a photo or scan of an ECG sheet", font=F_SMALL, fill=TEXT2)
        rr(draw, (84, 670, W - 84, 868), 30, (244, 250, 254), outline=BORDER)
        draw.text((126, 724), "WFDB / ECG files", font=F_H2, fill=NAVY)
        draw.text((126, 778), "Load .hea, .dat, or supported ECG files", font=F_SMALL, fill=TEXT2)
        rr(draw, (84, 908, W - 84, 1106), 30, (244, 250, 254), outline=BORDER)
        draw.text((126, 962), "Live wearable session", font=F_H2, fill=NAVY)
        draw.text((126, 1016), "Start real-time or prototype monitoring session", font=F_SMALL, fill=TEXT2)
        if 0.3 < p < 0.95:
            tap(draw, W // 2, 770, (p - 0.3) / 0.65)

    elif scene == "upload":
        app_header(draw, "ECG File Upload", False)
        prototype_banner(draw)
        rr(draw, (44, 250, W - 44, 1500), 36, SURFACE, outline=BORDER)
        draw.text((84, 330), "Choose ECG files", font=F_H1, fill=NAVY)
        draw.text((84, 390), "WFDB pair, image conversion, or analysis-ready input", font=F_SMALL, fill=TEXT2)
        rr(draw, (84, 520, W - 84, 910), 34, (246, 250, 253), outline=BORDER)
        draw.text((232, 620), "00001_lr.hea", font=F_H2, fill=NAVY)
        draw.text((232, 692), "00001_lr.dat", font=F_H2, fill=NAVY)
        draw.text((232, 764), "Signal pair detected and ready", font=F_SMALL, fill=SUCCESS)
        button(draw, 84, 1000, W - 168, 86, "Run AI Analysis", True)
        button(draw, 84, 1116, W - 168, 86, "Generate PDF Report", False)
        if 0.18 < p < 0.92:
            tap(draw, W // 2, 1042, (p - 0.18) / 0.74)

    elif scene == "results":
        app_header(draw, "AI Analysis Result", False)
        prototype_banner(draw)
        rr(draw, (40, 246, W - 40, 1700), 38, SURFACE, outline=BORDER)
        draw.text((84, 306), "Cardiac Pre-Ischemia", font=F_H1, fill=NAVY)
        draw.text((84, 364), "Prototype analysis walkthrough with verified feature set", font=F_SMALL, fill=TEXT2)
        rr(draw, (84, 442, W - 84, 710), 30, (247, 251, 255), outline=BORDER)
        ecg_wave(draw, 116, 480, W - 232, 160, DANGER, p * 5.8)
        card_metric(draw, 84, 758, 286, 118, "Analysis State", "Completed", DANGER)
        card_metric(draw, 396, 758, 286, 118, "Metrics", "Available", ACCENT)
        card_metric(draw, 708, 758, 286, 118, "Review", "Required", SUCCESS)
        rr(draw, (84, 928, W - 84, 1260), 30, SURFACE, outline=BORDER)
        draw.text((118, 972), "Clinical findings", font=F_H2, fill=NAVY)
        draw.text((118, 1040), "Signal quality and ECG measurements available from the analysis pipeline", font=F_TEXT, fill=NAVY)
        draw.text((118, 1094), "Classification, graph context, and review notes are displayed after processing", font=F_TEXT, fill=NAVY)
        draw.text((118, 1148), "Final interpretation remains with qualified clinicians", font=F_TEXT, fill=NAVY)
        button(draw, 84, 1320, W - 168, 86, "Open Report", True)

    elif scene == "report":
        app_header(draw, "Generated Report", False)
        prototype_banner(draw)
        rr(draw, (120, 240, W - 120, 1680), 20, SURFACE, outline=BORDER)
        draw.text((168, 292), "Cardiac Pre-Ischemia Analysis Report", font=F_H2, fill=NAVY)
        y = 378
        rows = [
            ("Patient", "Demo patient"),
            ("ECG Summary", "AI-assisted screening session"),
            ("Signal Quality", "Pipeline output"),
            ("Risk Output", "Model-backed review field"),
            ("Graphs", "Waveform and analysis context"),
            ("Review", "Clinical interpretation required"),
        ]
        for k, v in rows:
            draw.text((170, y), k, font=F_SMALL, fill=TEXT2)
            draw.text((500, y), v, font=F_SMALL, fill=NAVY)
            draw.line((166, y + 34, W - 166, y + 34), fill=BORDER, width=1)
            y += 72
        rr(draw, (170, 890, W - 170, 1180), 24, (245, 250, 253), outline=BORDER)
        ecg_wave(draw, 200, 950, W - 400, 160, ACCENT, p * 4.6)
        draw.text((170, 1240), "Recommended Next Steps", font=F_H2, fill=NAVY)
        draw.text((170, 1302), "Report content follows the generated analysis workflow", font=F_TEXT, fill=NAVY)
        draw.text((170, 1352), "Evidence summary and graphs are included for review", font=F_TEXT, fill=NAVY)

    elif scene == "doctor":
        app_header(draw, "Doctor Dashboard", False)
        prototype_banner(draw)
        rr(draw, (44, 244, W - 44, 420), 34, SURFACE, outline=BORDER)
        draw.text((84, 304), "Physician review workspace", font=F_H1, fill=NAVY)
        draw.text((84, 364), "Reports, patients, priorities, and review queue", font=F_SMALL, fill=TEXT2)
        rr(draw, (44, 468, W - 44, 760), 34, SURFACE, outline=BORDER)
        draw.text((84, 520), "Patient list", font=F_H2, fill=NAVY)
        for idx, name in enumerate(["Demo Patient", "Signal Review Case", "Follow-up Session"]):
            y = 592 + idx * 56
            draw.text((94, y), name, font=F_TEXT, fill=NAVY)
            draw.text((W - 260, y), "Open", font=F_TEXT, fill=ACCENT)
        rr(draw, (44, 806, W - 44, 1180), 34, SURFACE, outline=BORDER)
        draw.text((84, 860), "Doctor Reports", font=F_H2, fill=NAVY)
        draw.text((84, 930), "Recent PDF outputs, history, and patient review context", font=F_SMALL, fill=TEXT2)
        card_metric(draw, 64, 1240, 286, 118, "Patients", "Registry", SUCCESS)
        card_metric(draw, 380, 1240, 286, 118, "Alerts", "Review", WARNING)
        card_metric(draw, 696, 1240, 286, 118, "Reports", "Ready", ACCENT)

    rr(draw, (54, 1780, 1026, 1858), 24, (243, 248, 252), outline=BORDER)
    draw.text((86, 1808), "Simulated mobile-style walkthrough based on verified project features. Not a live patient recording.", font=F_SMALL, fill=TEXT2)

    return np.array(img)


def build():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    writer = cv2.VideoWriter(str(OUT), cv2.VideoWriter_fourcc(*"mp4v"), FPS, (W, H))
    if not writer.isOpened():
      raise RuntimeError("Failed to open video writer")
    for scene_name, secs in SCENES:
        frames = int(secs * FPS)
        for i in range(frames):
            p = i / max(1, frames - 1)
            frame = render_screen(scene_name, p)
            writer.write(cv2.cvtColor(frame, cv2.COLOR_RGB2BGR))
    writer.release()
    print(OUT)


if __name__ == "__main__":
    build()
