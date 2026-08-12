# MODEL_FAILURE_AUDIT

## Suspected Failure
- Different ECG inputs were producing overly similar or saturated-looking outputs.
- Image-based ECG uploads were being interpreted by users as if they were passed through the same calibrated production model used for WFDB records.
- A failure case with reported high HR, wide QRS, prolonged QTc, and high score triggered concern that the signal-processing path may be producing invalid measurements.

## Confirmed Failure
- Confirmed: the `image` analysis path does **not** use `ECG_MODEL_V15_FINAL`.
- Confirmed: the `image` path uses `_image_signal_screening_score(...)`, a rule-based heuristic score, then maps it into the same report pipeline.
- Confirmed: the image path forces `fs=100.0` for image-derived synthetic traces.
- Confirmed: representative-lead scoring in `backend/ecg_pipeline.py` previously used `DEFAULT_FS=100.0` internally instead of the actual record sampling rate.
- Confirmed: interval values (`PR`, `QRS`, `QT`, `QTc`, `ST`) were emitted as `ESTIMATED` even when signal quality and beat count were insufficient for confident interpretation.

## Evidence
- `backend/main.py`
  - `analyze_image(...)` converts an image to a synthetic signal and sets `fs = 100.0`.
  - `_run_signal_analysis(...)` branches on `input_type == "image"` and sets:
    - `model_version = "image_signal_screening_v2"`
    - `pipeline_version = "image_ecg_signal_only_v2"`
    - `feature_version = "rule_based_measurement_fusion_v2"`
    - `score = _image_signal_screening_score(...)`
- `backend/ecg_pipeline.py`
  - `representative_lead(...)` originally used `DEFAULT_FS = 100.0` inside peak-distance scoring.
- `ECG_MODEL_V15_FINAL/model_metadata.json`
  - Explicitly states input format is `WFDB multi-lead ECG record`.

## Root Cause
1. **Primary root cause:** image uploads were routed through a heuristic experimental scoring path but surfaced to the user inside the same analysis/report UX, which made them appear equivalent to calibrated model inference.
2. **Secondary root cause:** sampling-rate-dependent representative-lead ranking used a fixed 100 Hz assumption internally, which can distort downstream peak selection for non-100 Hz data.
3. **Secondary root cause:** interval measurements lacked an explicit reliability gate, so low-quality or low-beat-count cases could still look numerically precise.

## Affected Components
- `backend/main.py`
- `backend/ecg_pipeline.py`
- Report pipeline consuming `AnalysisResponse`
- Image upload analysis path

## Severity
- `HIGH`

## Reproducibility
- `CONFIRMED IN CODE`
- `PARTIALLY VERIFIED IN RUNTIME`

## What Is Not Yet Verified
- Full 20-50 ECG probability-distribution audit under a version-matched Python 3.11 runtime.
- Patient-level leakage audit on the original training data.
- Before/after numeric regression on the exact failure ECG payload.
