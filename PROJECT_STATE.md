# PROJECT IDENTITY

- Project name: `CARDIAC PRE-ISCHEMIA`
- Main purpose: AI-assisted ECG screening, signal analysis, PDF report generation, and patient/doctor workflows through a Flutter app with a FastAPI backend.
- Current application architecture:
  - `Flutter` frontend in `lib/main.dart`
  - `FastAPI` backend in `backend/main.py`
  - ECG signal-processing utilities in `backend/ecg_pipeline.py`
  - PDF/report rendering in `new_report/` plus backend fallback PDF path
  - `SQLite` app database managed by backend
  - Railway deployment through `Dockerfile` + `railway.json`
- Current model version: `ECG_MODEL_V15_FINAL`
- Current backend version: `wfdb_v15_verified_inference` pipeline with image/WFDB split inference and `/debug/model-probe` support
- Current Flutter/app version: `1.0.0+1` from `pubspec.yaml`

# CURRENT STATUS

Completed:
- Flutter app supports doctor, patient, and guest/demo flows.
- Backend supports WFDB file analysis, image analysis, report generation, and report download.
- Session persistence was added using `shared_preferences`; token + workspace + selected doctor state are now stored locally in Flutter.
- Patient flow was simplified so the patient can register/login and use the app without selecting a doctor.
- Patient profile now includes optional doctor linking through a `+` action and bottom-sheet doctor picker.
- Legacy `Patient Setup` screen was changed so it no longer asks the patient to choose a doctor before entering the patient workspace.
- Session bootstrap now falls back to the saved local workspace when `/auth/me` fails transiently instead of forcing logout on refresh.
- Web bootstrap now unregisters old service workers and loads Flutter without a service worker to avoid stale cached deployments.
- Backend now serves `index.html` with explicit no-cache headers so fresh deployments appear immediately.
- `build/web` was regenerated on `2026-08-11` so Railway can publish the current Flutter UI instead of an older build artifact.
- Backend now exposes inference transparency fields and `/debug/model-probe`.
- Backend separates image screening from WFDB model inference instead of forcing all image inputs through the packaged WFDB classifier.
- Backend includes safe fallback PDF generation if the advanced report renderer fails.

Currently being worked on:
- Persistent project memory/state management through this `PROJECT_STATE.md`.
- Investigation of overly similar predictions across different ECG inputs.
- Verification that latest Flutter + backend + Railway deployment are all running the newest code together.

Broken / unresolved:
- Different ECG inputs may still yield very similar high-confidence predictions; root cause is not yet scientifically verified.
- End-to-end deployed behavior after the latest refresh/cache/session fixes is not yet verified from this environment.
- Some patient-facing copy outside the main patient path may still contain wording related to follow-up/care coordination even though doctor linking is now optional.
- The latest patient setup fix and refresh/cache fixes will not appear in production until the app is redeployed.

NOT verified:
- Multi-ECG probability distribution after latest deploy
- Railway production build after commit `de17d51`
- Real-device refresh/session persistence after latest deploy
- End-to-end PDF generation after latest deploy
- Training/inference feature equivalence between original `.npy` training features and runtime ECG feature extraction

Remaining to be done:
- Redeploy latest backend/frontend code
- Run `/health` and `/debug/model-probe`
- Perform multi-ECG regression test
- Verify report generation on multiple distinct ECG cases
- Verify refresh behavior on deployed web after the rebuilt bundle is live
- Continue wording cleanup only after inference behavior is verified

# ML PIPELINE STATUS

ECG input
→ preprocessing
→ signal processing
→ feature extraction
→ feature validation
→ scaler
→ model
→ raw probability
→ calibration
→ threshold
→ classification
→ risk level
→ report

| Stage | Status | Implementation file | Verification status | Known problems |
|---|---|---|---|---|
| ECG input | Implemented | `backend/main.py` | Verified by code inspection | Two distinct input families exist: WFDB records and image-derived ECG |
| Preprocessing | Implemented | `backend/ecg_pipeline.py` | Verified by code inspection | Exact equivalence with original training preprocessing is not proven |
| Signal processing | Implemented | `backend/ecg_pipeline.py` | Verified by code inspection | Image-derived signals may still collapse visual differences depending on image quality/layout |
| Feature extraction | Implemented | `backend/ecg_pipeline.py` + `backend/main.py` | Verified by code inspection | Runtime feature compatibility with original `.npy` training features remains unverified |
| Feature validation | Partial | `ECG_MODEL_V15_FINAL/feature_schema.json`, `/debug/model-probe` in `backend/main.py` | Partial; tooling exists, full audit not run | Feature-vector uniqueness audit not yet executed on 10–20 records |
| Scaler | Implemented | `ECG_MODEL_V15_FINAL/scaler_v15_final.pkl` loaded in `backend/main.py` | Verified by metadata/code inspection | Runtime feature ordering/scaling consistency with training remains unverified |
| Model | Implemented | `ECG_MODEL_V15_FINAL/model_v15_final.pkl`, `backend/main.py` | Verified by metadata/code inspection | `ECG_MODEL_V15_FINAL` is a package refresh, not a newly retrained classifier |
| Raw probability | Implemented | `backend/main.py` via `predict_details()` | Verified by code inspection | Real deployed distribution across many ECGs not yet measured |
| Calibration | Implemented | `backend/main.py`, model package metadata | Verified by code inspection | Calibration quality on deployment ECGs not verified |
| Threshold | Implemented | `ECG_MODEL_V15_FINAL/model_metadata.json` + `threshold_v15_final.npy` | Verified by code/metadata inspection | Threshold behavior on real-case spread not verified |
| Classification | Implemented | `backend/main.py` | Verified by code inspection | Similar predictions issue may make classifications look artificially stable |
| Risk level | Implemented | `backend/main.py`, surfaced in `lib/main.dart` | Verified by code inspection | Depends on unresolved probability similarity problem |
| Report | Implemented | `backend/main.py`, `new_report/report_data.py`, Flutter report views | Verified by code inspection | Production PDF output after latest deploy not verified |

# CURRENT CRITICAL ISSUE

Different ECG recordings appear to produce extremely similar predictions, including very high probabilities such as approximately `0.998–1.000` and nearly identical risk classifications.

The project must investigate whether this is caused by:
- feature extraction
- preprocessing
- caching
- stale state
- feature ordering
- scaling
- model overconfidence
- calibration
- leakage
- backend inference
- Flutter/API integration
- report generation

Important rule:
- DO NOT solve this by artificially randomizing predictions.

Current verified evidence:
- `ECG_MODEL_V15_FINAL` metadata explicitly states it is a verified inference package refresh based on `KIMO_ECG_ULTRA_V14_PLUS`, not a newly retrained classifier.
- The training script `D:\DATA\train_model2_v14_plus.py` trains on precomputed `batch_X_*.npy` / `batch_y_*.npy` feature matrices.
- Runtime inference computes features from raw ECG at request time in the backend.
- This creates a real train/inference consistency risk until verified experimentally.

# AUDIT STATUS

- [ ] Dataset audit
- [ ] Patient ID audit
- [ ] Data leakage audit
- [ ] Duplicate ECG audit
- [ ] Feature-vector uniqueness audit
- [ ] Training/inference consistency audit
- [ ] Model probability audit
- [ ] Calibration audit
- [x] Backend inference audit
- [ ] Flutter/API audit
- [x] Report-generation audit
- [ ] Multi-ECG regression test

# EXPERIMENT HISTORY

## EXP-2026-08-11-001
- Date: `2026-08-11`
- Purpose: Persist login/session state across refresh and app reopen
- Files changed:
  - `pubspec.yaml`
  - `pubspec.lock`
  - `macos/Flutter/GeneratedPluginRegistrant.swift`
  - `lib/main.dart`
- Model version: `ECG_MODEL_V15_FINAL`
- Dataset/split: `N/A`
- Parameters: Added `shared_preferences`; stored token, role, username, workspace, selected/current doctor, and app settings locally
- Results:
  - Session bootstrap flow added
  - App can restore saved workspace if token remains valid
  - `Sign out` was added to settings
- Problems discovered:
  - End-to-end deploy verification not completed from this environment
- Decision: Keep change
- Next step: Redeploy and verify refresh behavior on deployed app

## EXP-2026-08-11-002
- Date: `2026-08-11`
- Purpose: Remove forced doctor selection from patient entry flow
- Files changed:
  - `lib/main.dart`
- Model version: `ECG_MODEL_V15_FINAL`
- Dataset/split: `N/A`
- Parameters:
  - Patient login routes directly to `PatientHome`
  - Role selection patient path routes directly to `PatientHome`
  - Added patient-side doctor picker through `+` in profile
- Results:
  - Patient can use app independently
  - Doctor linking became optional and can be done later
- Problems discovered:
  - Copy/text across the app still needs broader consistency cleanup
- Decision: Keep change
- Next step: Verify patient flow on deployed build

## EXP-2026-08-11-003
- Date: `2026-08-11`
- Purpose: Clarify UX copy so patient is not presented as requiring doctor approval/follow-up ownership
- Files changed:
  - `lib/main.dart`
- Model version: `ECG_MODEL_V15_FINAL`
- Dataset/split: `N/A`
- Parameters: Updated patient-related labels such as doctor linking, assigned clinician, and optional doctor wording
- Results:
  - Main patient path now clearly treats doctor linking as optional
- Problems discovered:
  - Some doctor/care language still exists in other screens outside the main patient path
- Decision: Keep change
- Next step: Finish only after inference verification, not before

## EXP-2026-08-11-004
- Date: `2026-08-11`
- Purpose: Create persistent project memory / continuity source of truth
- Files changed:
  - `PROJECT_STATE.md`
- Model version: `ECG_MODEL_V15_FINAL`
- Dataset/split: `N/A`
- Parameters: Added single project state file with identity, status, ML pipeline, audit checklist, verified facts, and next action
- Results:
  - New sessions can load project continuity from one file
- Problems discovered:
  - Existing audit notes exist in auxiliary docs and must remain secondary to this file
- Decision: Keep change
- Next step: Update `PROJECT_STATE.md` after every meaningful change

## EXP-2026-08-11-005
- Date: `2026-08-11`
- Purpose: Remove doctor selection from the legacy patient setup screen and make registration copy role-specific
- Files changed:
  - `lib/main.dart`
  - `PROJECT_STATE.md`
- Model version: `ECG_MODEL_V15_FINAL`
- Dataset/split: `N/A`
- Parameters:
  - `RegisterPage` intro/form copy now changes based on whether the selected account type is `doctor` or `patient`
  - `DoctorSelectionPage` now collects patient identity only and sends the user directly to `PatientHome`
  - The doctor dropdown and “no doctors registered” warning were removed from that screen
- Results:
  - Patient setup no longer requires or even offers doctor selection on that path
  - The old warning state shown in the screenshot should no longer appear after redeploy
- Problems discovered:
  - Production may still show the old screen until the latest build is deployed
- Decision: Keep change
- Next step: Redeploy and verify the old patient setup screen no longer shows doctor selection or the warning banner

## EXP-2026-08-11-006
- Date: `2026-08-11`
- Purpose: Fix stale deployed web builds and stop refresh from forcing logout on transient auth checks
- Files changed:
  - `lib/main.dart`
  - `backend/main.py`
  - `web/flutter_bootstrap.js`
  - `build/web/*`
  - `PROJECT_STATE.md`
- Model version: `ECG_MODEL_V15_FINAL`
- Dataset/split: `N/A`
- Parameters:
  - `SessionBootstrapPage` now restores the saved workspace if `/auth/me` fails instead of clearing the session immediately
  - Custom web bootstrap unregisters old service workers and disables new service-worker loading
  - Backend serves `index.html` with explicit `no-store` headers
  - Flutter web production bundle regenerated successfully on `2026-08-11`
- Results:
  - `build/web/main.dart.js` timestamp updated on `2026-08-11`
  - Old patient setup warning text is no longer present in the rebuilt web bundle
  - Railway now has a fresh deployable artifact that matches current source changes
- Problems discovered:
  - Full runtime verification against the deployed public URL has not yet been performed from this session
- Decision: Keep change
- Next step: Push and redeploy, then verify refresh behavior and patient registration flow on the live URL

# FILES CHANGED

- `lib/main.dart`
  - Main Flutter app, auth flow, patient/doctor workflows, session persistence, result pages
- `backend/main.py`
  - FastAPI backend, analysis endpoints, report generation, inference routing, `/debug/model-probe`
- `web/flutter_bootstrap.js`
  - Custom Flutter web bootstrap that unregisters stale service workers and disables web service-worker loading
- `build/web`
  - Regenerated deployed Flutter web bundle copied by Docker/Railway
- `backend/ecg_pipeline.py`
  - ECG signal processing and runtime feature extraction
- `new_report/report_data.py`
  - Advanced report data shaping/render support
- `ECG_MODEL_V15_FINAL/model_metadata.json`
  - Model identity, threshold, pipeline version, input format
- `ECG_MODEL_V15_FINAL/validation_results.json`
  - Current validation status for packaged model
- `MODEL_PIPELINE_AUDIT.md`
  - Auxiliary audit findings; useful reference, but not the single source of truth
- `MODEL_DIAGNOSTIC_RESULTS.csv`
  - Diagnostic CSV skeleton/output target for model probe results
- `pubspec.yaml`
  - Flutter dependencies and app version
- `railway.json`
  - Railway start configuration
- `Dockerfile`
  - Production container build

# KNOWN PROBLEMS

1. Similar ECG cases may be producing overly similar probabilities and classifications.
2. Training data features and runtime-generated features may not be scientifically identical.
3. Latest deployed production environment is not verified from this session after the newest commits.
4. Image-derived ECG analysis may still lose diversity relative to true WFDB multi-lead signals.
5. Some non-critical patient-facing wording may still imply follow-up/care ownership in secondary screens.
6. Production may still be serving the old patient setup screen or old refresh behavior until redeploy.

# VERIFIED FACTS

- `ECG_MODEL_V15_FINAL/model_metadata.json` says:
  - `model_version = ECG_MODEL_V15_FINAL`
  - `base_model_source = KIMO_ECG_ULTRA_V14_PLUS`
  - `threshold = 0.52`
  - `pipeline_version = wfdb_v15_verified_inference`
  - `input_format = WFDB multi-lead ECG record`
- `ECG_MODEL_V15_FINAL/README.md` states this package is a verified inference package refresh, not a newly retrained classifier.
- `ECG_MODEL_V15_FINAL/validation_results.json` is still `pending_backend_reload`.
- Recent git history confirms the following verified changes were committed:
  - `3ae0cce Persist auth session across refresh`
  - `98e0bfc Simplify patient doctor linking flow`
  - `de17d51 Clarify optional doctor linkage for patients`
- Local `lib/main.dart` now contains:
  - `Continue to Patient Workspace`
  - `Direct access`
  - a patient setup flow without the old doctor dropdown or warning banner
- Local `build/web/main.dart.js` no longer contains the old `No doctors are registered yet...` warning string after the rebuild on `2026-08-11`.
- Local `build/web/flutter_bootstrap.js` now unregisters old service workers and loads Flutter with `serviceWorkerSettings: null`.
- `backend/main.py` contains:
  - `predict_details()`
  - `rawProbability`
  - `calibratedProbability`
  - `inferenceMode`
  - `/debug/model-probe`
  - `image_signal_screening_v2` path for image inputs
- `backend/main.py` now sends `Cache-Control: no-store` headers for `index.html` responses.
- `pubspec.yaml` currently includes `shared_preferences` and app version `1.0.0+1`.

# NOT VERIFIED

- Real production output of `/debug/model-probe`
- Whether production is currently serving the rebuilt `build/web` that includes the latest refresh/cache/patient-setup fixes
- Whether the latest patient session persistence works correctly on deployed mobile/web
- Whether current PDF generation matches expectations on multiple distinct ECG cases
- Whether identical-looking outputs are caused more by model saturation, feature mismatch, fallback behavior, or front-end display reuse
- Whether all report/dashboard differences are visually obvious across multiple ECG cases after latest deploy
- Whether production has picked up the newest patient setup fix

# NEXT ACTION

Redeploy the latest project version, verify patient registration/setup no longer shows doctor selection or the warning banner, then run a controlled multi-ECG backend audit using `/health` and `/debug/model-probe` on 10–20 WFDB records.

# LAST SESSION SUMMARY

- What was done:
  - Added persistent session storage in Flutter
  - Simplified patient flow so doctor selection is optional
  - Added patient-side doctor picker
  - Clarified patient UX copy
  - Created `PROJECT_STATE.md` as the single source of truth
  - Removed doctor selection from the legacy patient setup screen
- What was discovered:
  - No `PROJECT_STATE.md` previously existed
  - The project already had useful auxiliary audit docs (`MODEL_PIPELINE_AUDIT.md`) but no unified continuity file
  - Model package metadata confirms this is not a newly retrained classifier
- What files were changed:
  - `lib/main.dart`
  - `pubspec.yaml`
  - `pubspec.lock`
  - `macos/Flutter/GeneratedPluginRegistrant.swift`
  - `PROJECT_STATE.md`
- What tests were run:
  - `flutter pub get`
  - `flutter analyze`
  - File inspection of:
    - `ECG_MODEL_V15_FINAL/model_metadata.json`
    - `ECG_MODEL_V15_FINAL/validation_results.json`
    - `MODEL_PIPELINE_AUDIT.md`
    - `git log`
- What passed:
  - Dependency resolution
  - Static analysis without blocking compile/runtime errors
  - Project state file creation/update
- What failed:
  - No end-to-end deployed verification was run from this environment
  - No multi-ECG regression/probability audit was run from this environment
- What remains:
  - Redeploy
  - Verify patient setup screen no longer asks for doctor selection
  - Verify refresh/session behavior
  - Run `/debug/model-probe`
  - Confirm whether similar predictions persist
- Exact next step:
  - Redeploy latest code, verify patient setup is direct without doctor selection, then capture `/debug/model-probe` output for 10–20 distinct WFDB recordings.
