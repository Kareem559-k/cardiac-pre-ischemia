FROM python:3.11

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV CARDIAC_DATA_DIR=/data
ENV CARDIAC_DB_PATH=/data/app.db
ENV CARDIAC_REPORTS_DIR=/data/generated_reports
ENV CARDIAC_WFDB_EXPORTS_DIR=/data/generated_wfdb
ENV KIMO_ECG_MODEL_DIR=/app/ECG_MODEL_V15_FINAL

WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN mkdir -p /app/backend
COPY backend/requirements.txt /app/backend/requirements.txt

RUN apt-get update \
    && apt-get install -y --no-install-recommends libgomp1 libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir -r /app/requirements.txt

COPY backend /app/backend
COPY build/web /app/build/web
COPY ECG_MODEL_V15_FINAL /app/ECG_MODEL_V15_FINAL
COPY 00001_lr_approved.pdf /app/00001_lr_approved.pdf

RUN mkdir -p /data/generated_reports /data/generated_wfdb

WORKDIR /app/backend

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
