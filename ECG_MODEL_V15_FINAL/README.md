ECG_MODEL_V15_FINAL

Contents
- `model_v15_final.pkl`
- `imputer_v15_final.pkl`
- `scaler_v15_final.pkl`
- `threshold_v15_final.npy`
- `model_metadata.json`
- `feature_schema.json`
- `preprocessing_config.json`
- `validation_results.json`

Purpose
- Preserve the original `KIMO_ECG_ULTRA_V14_PLUS` trained classifier and its fitted preprocessing artifacts.
- Fix production inference by making backend preprocessing, feature extraction, and runtime metadata explicit and versioned.

Important
- This package is a verified inference package refresh, not a newly retrained classifier.
- Clinical outputs remain AI-assisted screening outputs and heuristic ECG measurements where noted.
