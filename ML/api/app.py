"""
Microservice ML (Flask) untuk Smart Farming Selada:
1. Regresi      : Estimasi hari menuju panen (days_left)
2. Klasifikasi  : Prediksi fase pertumbuhan / kesiapan panen (Semai, Vegetatif, Siap Panen)
3. Klusterisasi : Analisis profil lingkungan & nutrisi mikroklimat tanaman (Cosine K-Means)

Endpoint:
GET  /health   -> status + metadata ketiga model ML
POST /predict  -> {umur_hst, suhu, kelembapan, tds, ph} -> estimasi lengkap

Jalankan:  python app.py
Default bind = 127.0.0.1:5000 — microservice ini hanya untuk Laravel, BUKAN publik.
Laravel wajib mengirim header `X-ML-Token` sama dengan env `ML_SHARED_SECRET`;
kalau env itu kosong, /predict menolak semua request (fail closed).
"""
from __future__ import annotations

import functools
import json
import os
from datetime import date, timedelta
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from flask import Flask, jsonify, request
from flask_cors import CORS

try:
    from .cosine_kmeans import SphericalKMeans  # noqa: F401 - register artifact class for package imports
except ImportError:
    from cosine_kmeans import SphericalKMeans  # noqa: F401 - script execution from ML/api

BASE_DIR = Path(__file__).resolve().parent
ARTIFACTS = BASE_DIR / "artifacts"
REG_MODEL_PATH = ARTIFACTS / "model.joblib"
CLS_MODEL_PATH = ARTIFACTS / "classifier.joblib"
CLUSTER_MODEL_PATH = ARTIFACTS / "cluster.joblib"
META_PATH = ARTIFACTS / "features.json"

DEFAULT_RANGES = {
    "umur_hst": (1, 48),
    "suhu": (15, 38),
    "kelembapan": (40, 95),
    "tds": (300, 1400),
    "ph": (4.5, 8.5),
}

DEFAULT_STAGE_LABELS = {
    "0": "Semai (Nursery)",
    "1": "Vegetatif (Pembesaran)",
    "2": "Siap Panen (Mature)",
}

app = Flask(__name__)
# Default: tidak ada CORS sama sekali. Isi ML_CORS_ORIGINS="http://localhost:8000"
# hanya kalau memang ada pemanggil browser yang sah (mis. dashboard admin lokal).
_cors_origins = os.getenv("ML_CORS_ORIGINS", "")
if _cors_origins:
    CORS(app, resources={r"/*": {"origins": [o.strip() for o in _cors_origins.split(",") if o.strip()]}})

ML_SHARED_SECRET = os.getenv("ML_SHARED_SECRET", "")


def internal_only(fn):
    """Hanya Laravel yang boleh memanggil model. Tanpa secret yang cocok → 401,
    termasuk ketika env di sisi Flask kosong (fail closed)."""

    @functools.wraps(fn)
    def wrapper(*args, **kwargs):
        given = request.headers.get("X-ML-Token", "")
        if not ML_SHARED_SECRET or given != ML_SHARED_SECRET:
            return jsonify({"error": "Endpoint internal: token layanan tidak valid."}), 401
        return fn(*args, **kwargs)

    return wrapper

reg_model = joblib.load(REG_MODEL_PATH) if REG_MODEL_PATH.exists() else None
cls_model = joblib.load(CLS_MODEL_PATH) if CLS_MODEL_PATH.exists() else None
cluster_model = joblib.load(CLUSTER_MODEL_PATH) if CLUSTER_MODEL_PATH.exists() else None

meta = json.loads(META_PATH.read_text(encoding="utf-8")) if META_PATH.exists() else {}
FEATURES = meta.get("features", list(DEFAULT_RANGES))
ENV_FEATURES = meta.get("env_features", ["suhu", "kelembapan", "tds", "ph"])
RANGES = meta.get("ranges", DEFAULT_RANGES)
STAGE_LABELS = meta.get("stage_labels", DEFAULT_STAGE_LABELS)
CLUSTER_PROFILES = meta.get("clustering", {}).get("profiles", {})


def validate(payload) -> tuple[dict | None, list[str]]:
    if not isinstance(payload, dict):
        return None, ["Body harus berupa JSON object."]
    clean, errors = {}, []
    for feat in FEATURES:
        if feat not in payload or payload[feat] is None:
            errors.append(f"Field '{feat}' wajib diisi.")
            continue
        raw = payload[feat]
        if isinstance(raw, bool) or not isinstance(raw, (int, float, str)):
            errors.append(f"Field '{feat}' harus angka.")
            continue
        try:
            val = float(raw)
        except (TypeError, ValueError):
            errors.append(f"Field '{feat}' harus angka.")
            continue
        if not np.isfinite(val):
            errors.append(f"Field '{feat}' tidak valid.")
            continue
        lo, hi = RANGES.get(feat, (-np.inf, np.inf))
        if val < lo or val > hi:
            errors.append(f"Field '{feat}' di luar rentang [{lo}, {hi}].")
            continue
        clean[feat] = val
    return (clean if not errors else None), errors


@app.get("/health")
def health():
    return jsonify(
        {
            "status": "ok" if reg_model is not None else "no_model",
            "models_loaded": {
                "regression": reg_model is not None,
                "classification": cls_model is not None,
                "clustering": cluster_model is not None,
            },
            "dataset_source": meta.get("dataset_source"),
            "n_rows": meta.get("n_rows"),
            "features": FEATURES,
            "regression_meta": meta.get("regression"),
            "classification_meta": meta.get("classification"),
            "clustering_meta": meta.get("clustering"),
        }
    )


@app.post("/predict")
@internal_only
def predict():
    if reg_model is None:
        return jsonify({"error": "Model belum dilatih. Jalankan 'python train.py'."}), 503

    clean, errors = validate(request.get_json(silent=True) or {})
    if errors:
        return jsonify({"error": "Validasi gagal.", "errors": errors}), 422

    feature_df = pd.DataFrame([[clean[f] for f in FEATURES]], columns=FEATURES)

    # 1. Regresi: sisa hari menuju panen
    days_pred = float(reg_model.predict(feature_df)[0])
    days_left = max(0, int(round(days_pred)))
    harvest = date.today() + timedelta(days=days_left)

    # 2. Klasifikasi: fase pertumbuhan / kesiapan panen
    if cls_model is not None:
        stage_id = int(cls_model.predict(feature_df)[0])
    else:
        stage_id = 0 if clean["umur_hst"] <= 14 else (1 if clean["umur_hst"] <= 35 else 2)
    stage_label = STAGE_LABELS.get(str(stage_id), STAGE_LABELS.get(stage_id, "Tidak Diketahui"))

    # 3. Klusterisasi: profil lingkungan & mikroklimat
    cluster_id = None
    cluster_info = None
    if cluster_model is not None:
        env_df = pd.DataFrame([[clean[f] for f in ENV_FEATURES]], columns=ENV_FEATURES)
        cluster_id = int(cluster_model.predict(env_df)[0])
        cluster_info = CLUSTER_PROFILES.get(str(cluster_id), {
            "description": f"Cluster {cluster_id}"
        })

    is_ready = days_left <= 0 or stage_id == 2

    return jsonify(
        {
            "days_left": days_left,
            "estimated_total_hst": int(round(clean["umur_hst"] + days_left)),
            "current_umur_hst": clean["umur_hst"],
            "harvest_date": harvest.isoformat(),
            "ready": is_ready,
            "classification": {
                "stage_id": stage_id,
                "growth_stage": stage_label,
            },
            "clustering": {
                "cluster_id": cluster_id,
                "profile": cluster_info,
            },
            "features_used": {f: clean[f] for f in FEATURES},
        }
    )


if __name__ == "__main__":
    host = os.getenv("HOST", "127.0.0.1")
    port = int(os.getenv("PORT", 5000))
    app.run(host=host, port=port, debug=False)
