# PROJECT_STATE

## Date
- 2026-08-12

## Current Production Model State
- Active model metadata points to `ECG_MODEL_V15_FINAL`
- Base model source: `KIMO_ECG_ULTRA_V14_PLUS`
- Intended validated input format: `WFDB multi-lead ECG record`
- Image inputs are still handled by a separate experimental signal-only scoring path

## Current Audit State
- Baseline frozen in `AUDIT_BASELINE/baseline_manifest.json`
- Failure audit written in `MODEL_FAILURE_AUDIT.md`
- Repair report written in `MODEL_REPAIR_REPORT.md`
- Initial regression placeholders created:
  - `ECG_REGRESSION_RESULTS.csv`
  - `ECG_FEATURE_AUDIT.csv`

## Confirmed Technical Risks
- Image-derived ECG screening can be misinterpreted as production-model output if not clearly labeled
- Sampling-rate assumptions previously leaked into representative-lead selection
- Interval measurements need reliability gating
- Local version-matched runtime for full artifact replay is currently broken because the saved stack depends on Python 3.11 + scikit-learn 1.5 artifacts

## Verified
- Code-path root cause for image/WFDB divergence
- Current model metadata, schema, preprocessing policy, and threshold
- Backend changes applied to increase transparency and reduce false precision

## Not Verified
- Full 20-50 record probability-distribution audit on the exact saved runtime
- Patient-level leakage audit
- Exact before/after failure-case rerun

## Next Required Step
- Restore or recreate a runnable Python 3.11 audit environment with scikit-learn 1.5-compatible artifacts, then run:
  - 20-50 ECG behavior audit
  - failure-case regression
  - feature-vector and probability distribution validation
