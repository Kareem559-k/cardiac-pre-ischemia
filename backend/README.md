# Cardiac Sense Backend (FastAPI + SQLite)

## تشغيل الباك‑إند

```bash
cd backend
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## Endpoints
- POST `/analyze_image`  (multipart: file)
- POST `/analyze_files`  (multipart: files[])
- POST `/emergency`      (json: patientName, latitude, longitude)
- GET  `/emergencies`
- POST `/patients`       (json: name, age?, gender?, phone?, notes?)
- GET  `/patients`
- GET  `/patients/{id}`
- POST `/auth/register`  (json: email, password, role?, name?)
- POST `/auth/login`     (json: email, password)
- GET  `/stats`
- GET  `/messages`
- POST `/messages`       (json: text, senderRole, senderName)
- GET  `/messages?patientId=123`
- POST `/messages`       (json: patientId, text, senderRole, senderName)
- GET  `/reports/export` (pdf)
- GET  `/reports/{patientId}`
- GET  `/appointments?patientId=123`
- POST `/appointments`   (json: patientId, doctorName, when, status?, notes?)
- GET  `/health`
