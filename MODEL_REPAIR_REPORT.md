# MODEL_REPAIR_REPORT

## Changes Made

### 1. Sampling-rate-safe representative lead scoring
- Updated `backend/ecg_pipeline.py`
- `representative_lead(signal, fs=None)` now uses the real `fs` when available instead of a fixed internal `100 Hz` assumption.

### 2. Signal-quality explanation layer
- Updated `backend/ecg_pipeline.py`
- `signal_quality_metrics(...)` now returns:
  - `signal_quality_class`
  - `quality_reasons`
- Reasons include:
  - elevated baseline wander
  - high-frequency noise contamination
  - possible clipping or saturation
  - missing or invalid samples detected

### 3. Interval reliability gating
- Updated `backend/main.py`
- `PR`, `QRS`, `QT`, `QTc`, and `ST` now use a reliability gate based on:
  - signal quality score
  - detected peak count
  - number of candidate leads
- When confidence is insufficient, these measurements are tagged `UNRELIABLE` instead of being presented as normal estimated values.

### 4. Explicit warning for image-derived screening
- Updated `backend/main.py`
- Image-based analysis now adds explicit findings stating:
  - it uses signal-only image screening
  - it is experimental
  - it is not equivalent to a calibrated WFDB model result

## Why Each Change Was Necessary
- The image pipeline was being perceived as the production model although it was not using the saved calibrated model.
- Fixed-100-Hz assumptions are unsafe for peak ranking and can bias peak-driven downstream measurements.
- Numerically precise interval outputs without reliability gating are misleading under poor-quality or sparse-beat conditions.

## Files Modified
- [backend/ecg_pipeline.py](/D:/DATA/flutter_application_3/backend/ecg_pipeline.py)
- [backend/main.py](/D:/DATA/flutter_application_3/backend/main.py)

## Tests Performed
- Static code-path audit of WFDB vs image inference routing.
- Artifact metadata freeze into `AUDIT_BASELINE/baseline_manifest.json`.
- Local backend schema/database inspection.

## Before / After

### Before
- Image path used heuristic scoring without strong warning in the analysis findings.
- Representative lead scoring could silently rely on 100 Hz internally.
- Low-confidence interval estimates were still labeled `ESTIMATED`.

### After
- Image path remains available but is explicitly marked experimental in findings.
- Representative lead scoring now uses the actual sampling rate.
- Low-confidence interval outputs are tagged `UNRELIABLE`.
- Signal quality now includes machine-readable reasons.

## Validation Results
- `PARTIALLY VERIFIED`

## Remaining Limitations
- Full model behavior audit across 20-50 ECGs is still pending due local Python runtime incompatibility with the saved 3.11/1.5.0 model stack.
- Exact failure-case regression has not yet been rerun end-to-end on the same matching runtime.
- Patient-level leakage audit has not yet been completed.
