# MODEL PIPELINE AUDIT

## 1. Executive Summary

- `VERIFIED`: `ECG_MODEL_V15_FINAL` is not a newly retrained model. Its own metadata says it is an inference/package refresh built on top of `KIMO_ECG_ULTRA_V14_PLUS`.
- `VERIFIED`: Training code in [train_model2_v14_plus.py](D:/DATA/train_model2_v14_plus.py) trains on precomputed feature matrices from `batch_X_*.npy` / `batch_y_*.npy`, not on raw WFDB records directly.
- `VERIFIED`: Production inference in [backend/main.py](D:/DATA/flutter_application_3/backend/main.py) computes features from raw/synthetic ECG at runtime using [backend/ecg_pipeline.py](D:/DATA/flutter_application_3/backend/ecg_pipeline.py).
- `VERIFIED`: This means there is a real risk of train/inference mismatch unless the original feature-generation pipeline that produced `batch_X_*.npy` is identical to runtime extraction.
- `VERIFIED`: `validation_results.json` inside `ECG_MODEL_V15_FINAL` explicitly says `pending_backend_reload`, so production validation was not completed in the package itself.
- `NOT VERIFIED`: End-to-end probability distribution across 20+ ECGs has not yet been executed from this environment because a working local Python runtime was not available in this session.

## 2. Root Cause

Current leading root-cause hypothesis:

1. Train/inference consistency is not yet scientifically proven.
2. Production may be running either:
   - the calibrated stacked model, or
   - heuristic fallback mode if model loading/runtime fails.
3. Before this audit pass, raw probability and inference mode were hidden from the report/output path, which made distinct root causes look like one symptom.

## 3. Evidence

### 3.1 Model package evidence

From [ECG_MODEL_V15_FINAL/model_metadata.json](D:/DATA/flutter_application_3/ECG_MODEL_V15_FINAL/model_metadata.json):

- `model_version = ECG_MODEL_V15_FINAL`
- `base_model_source = KIMO_ECG_ULTRA_V14_PLUS`
- note says this package `does not claim a retrained model`

From [ECG_MODEL_V15_FINAL/README.md](D:/DATA/flutter_application_3/ECG_MODEL_V15_FINAL/README.md):

- `Important: This package is a verified inference package refresh, not a newly retrained classifier.`

### 3.2 Training pipeline evidence

From [train_model2_v14_plus.py](D:/DATA/train_model2_v14_plus.py):

- loads `batch_X_*.npy` and `batch_y_*.npy`
- applies `SimpleImputer(strategy="median")`
- applies fitted `QuantileTransformer`
- trains a `StackingClassifier`
- applies Platt scaling through logistic regression on validation probabilities

### 3.3 Runtime inference evidence

From [backend/main.py](D:/DATA/flutter_application_3/backend/main.py) and [backend/ecg_pipeline.py](D:/DATA/flutter_application_3/backend/ecg_pipeline.py):

- loads raw WFDB/image-derived ECG
- filters and normalizes per lead
- extracts a 300-feature vector at runtime
- loads imputer/scaler/model package
- computes raw and calibrated probabilities
- falls back to heuristic scoring if model loading fails

## 4. Data Leakage Findings

- `NOT VERIFIED`: patient-level separation in the original feature-generation pipeline
- `NOT VERIFIED`: duplicate/near-duplicate recordings in `batch_X_*.npy`
- `NOT VERIFIED`: whether repeated patients exist across train/val/test

## 5. Feature Pipeline Findings

- `VERIFIED`: training consumes already-engineered features from `.npy` files
- `VERIFIED`: runtime consumes raw ECG and computes engineered features online
- `VERIFIED`: feature schema file claims ordered 300-feature pipeline with 24 features per lead + 5 global features + padding
- `RISK`: without reproducing the original feature-generation code used for `batch_X_*.npy`, exact compatibility is not proven

## 6. Model Findings

- `VERIFIED`: model architecture is stacking + Platt scaling
- `VERIFIED`: threshold is stored and loaded as `0.52`
- `NOT VERIFIED`: whether raw probabilities are saturated for most ECGs in production
- `NOT VERIFIED`: whether calibration compresses distinct raw probabilities into near-identical calibrated outputs

## 7. Calibration Findings

- `VERIFIED`: training script uses Platt scaling on validation probabilities only
- `NOT VERIFIED`: calibration quality on held-out deployment ECGs
- `NOT VERIFIED`: Brier score / calibration curve for the currently deployed package

## 8. Backend Findings

- `VERIFIED`: backend now logs/stores:
  - `inferenceMode`
  - `rawProbability`
  - `calibratedProbability`
  - `fallbackReason`
- `VERIFIED`: backend now exposes `/debug/model-probe`
- `VERIFIED`: backend now computes:
  - feature vector hash
  - signal summary stats
  - probability uniqueness summary
- `VERIFIED`: backend now has a safe PDF fallback generator to avoid `500` if advanced report generation fails

## 9. Flutter/API Findings

- `VERIFIED`: Flutter requests `/reports/generate` then opens `/reports/{reportId}/download`
- `NOT VERIFIED`: live deployed Flutter build after latest backend changes
- `NOT VERIFIED`: whether mobile/web client is ever showing stale results from a previous request

## 10. Report Generation Findings

- `VERIFIED`: report path now includes inference diagnostics in context
- `VERIFIED`: fallback PDF generation exists in backend if advanced renderer fails
- `VERIFIED`: prior versions could fail before generating any PDF

## 11. Fixes Applied

1. Added image multi-lead extraction improvements instead of repeating one trace blindly.
2. Improved representative lead selection to be dynamic rather than fixed.
3. Switched interval estimation to use multiple strong leads with median aggregation.
4. Added inference transparency:
   - raw probability
   - calibrated probability
   - inference mode
   - fallback reason
5. Added `/debug/model-probe` for 20-record diagnostic inspection.
6. Added safe fallback PDF generation.

## 12. Before vs After

Before:

- inference transparency was limited
- report generation could fail hard
- representative lead logic was too rigid
- interval estimation relied too heavily on one lead

After:

- probability path is inspectable
- report generation has fallback
- lead selection is dynamic
- interval estimation is multi-lead median-based
- diagnostic endpoint can quantify uniqueness across ECGs

## 13. Remaining Risks

- `HIGH RISK`: original `batch_X_*.npy` feature-generation code has not yet been reconstructed and compared line-by-line to runtime inference
- `HIGH RISK`: deployed service may still be using fallback mode if the model fails to load at runtime
- `MEDIUM RISK`: image-to-signal extraction can still collapse distinct paper ECG images into overly similar derived signals

## 14. Validation Results

- `NOT VERIFIED`: 20+ ECG probability audit from this session
- `NOT VERIFIED`: calibration distribution on deployed backend
- `NOT VERIFIED`: identical prediction percentage after latest deploy

Required next validation step:

1. Redeploy backend commit `f6950c4` or newer.
2. Call `/health` and confirm `model = loaded`.
3. Call `/debug/model-probe`.
4. Save returned rows to CSV and inspect:
   - `uniqueFeatureVectors`
   - `uniqueRawProbabilities`
   - `uniqueCalibratedProbabilities`
   - `% above 0.99`
   - `% identical predictions`

## 15. Files Changed

- [backend/main.py](D:/DATA/flutter_application_3/backend/main.py)
- [backend/ecg_pipeline.py](D:/DATA/flutter_application_3/backend/ecg_pipeline.py)
- [new_report/report_data.py](D:/DATA/flutter_application_3/new_report/report_data.py)
- [requirements.txt](D:/DATA/flutter_application_3/requirements.txt)
- [backend/requirements.txt](D:/DATA/flutter_application_3/backend/requirements.txt)
