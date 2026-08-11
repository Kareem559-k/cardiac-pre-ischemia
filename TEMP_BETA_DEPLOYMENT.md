# Cardiac Pre-Ischemia Temporary Beta Deployment

This project is prepared for a short closed beta with a small group of doctors.

## Recommended temporary hosting

Use Railway with one service and one mounted volume.

Reason:
- The backend stores `app.db`, generated PDF reports, and WFDB exports on disk.
- A mounted volume keeps these files after restarts.
- The backend can now serve the Flutter web build from the same domain.

## Files already prepared

- `railway.json`
- `requirements.txt`
- `backend/main.py`
- `build/web/*`

## Railway environment variables

Set these values in Railway:

```text
CARDIAC_DATA_DIR=/data
CARDIAC_DB_PATH=/data/app.db
CARDIAC_REPORTS_DIR=/data/generated_reports
CARDIAC_WFDB_EXPORTS_DIR=/data/generated_wfdb
KIMO_ECG_MODEL_DIR=/app/ECG_MODEL_V15_FINAL
CARDIAC_PUBLIC_BASE_URL=https://YOUR-RAILWAY-DOMAIN
CARDIAC_ALLOWED_ORIGINS=https://YOUR-RAILWAY-DOMAIN
```

## Files that must stay in the deployed repo

- `build/web`
- `00001_lr_approved.pdf`
- `ECG_MODEL_V15_FINAL`

## Service behavior after deployment

- `GET /health` checks backend, database, and model loading
- `GET /` opens the Flutter web app
- Report downloads use the deployed public domain
- Image-to-WFDB downloads use the deployed public domain

## Before giving access to doctors

1. Open `/health` and confirm:
   - `backend: ok`
   - `database: ok`
   - `model: loaded`
2. Create one doctor account.
3. Create one patient account.
4. Run one `.hea` or `.dat`/`.csv`/`.wav` analysis.
5. Generate one PDF report and download it.

## Not yet production-grade

This is suitable for a short beta, not a public medical launch.

Remaining items before a real launch:
- Replace debug Android signing with a release keystore
- Move from SQLite to managed Postgres
- Add server-side rate limits
- Add proper audit logging
- Add backup/retention policy
- Add real clinical validation and regulatory review
