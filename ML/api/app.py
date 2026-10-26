"""
Microservice ML (Flask) untuk estimasi hari menuju panen selada.

Dirancang STATELESS dan internal: hanya Laravel yang memanggilnya.
Tidak menyentuh database dan tidak mengurus autentikasi.

Endpoint:
GET  /health   -> status + metadata model
POST /predict  -> {umur_hst, suhu, kelembapan, tds, ph} -> hari menuju panen

Jalankan:  python app.py   (default http://127.0.0.1:5057)
"""
from __future__ import annotations

import json
from datetime import date, timedelta
from pathlib import Path

import joblib
import numpy as np
from flask import Flask, jsonify, request
from flask_cors import CORS

BASE_DIR = Path(__file__).resolve().parent
ARTIFACTS = BASE_DIR / "artifacts"
MODEL_PATH = ARTIFACTS / "model.joblib"
META_PATH = ARTIFACTS / "features.json"

DEFAULT_RANGES = {
    "umur_hst": (1, 45),
    "suhu": (10, 40),
    "kelembapan": (30, 100),
    "tds": (200, 1500),
    "ph": (4, 9),
}

app = Flask(__name__)
CORS(app)

model = joblib.load(MODEL_PATH) if MODEL_PATH.exists() else None
meta = json.loads(META_PATH.read_text(encoding="utf-8")) if META_PATH.exists() else {}
FEATURES = meta.get("features", list(DEFAULT_RANGES))
RANGES = meta.get("ranges", DEFAULT_RANGES)


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
            "status": "ok" if model is not None else "no_model",
            "model_loaded": model is not None,
            "selected_model": meta.get("selected_model"),
            "dataset_source": meta.get("dataset_source"),
            "features": FEATURES,
        }
    )


@app.post("/predict")
def predict():
    if model is None:
        return jsonify({"error": "Model belum dilatih. Jalankan 'python train.py'."}), 503

    clean, errors = validate(request.get_json(silent=True) or {})
    if errors:
        return jsonify({"error": "Validasi gagal.", "errors": errors}), 422

    features = [[clean[f] for f in FEATURES]]
    days_left = float(model.predict(features)[0])
    days_left = max(0, int(round(days_left)))

    harvest = date.today() + timedelta(days=days_left)
    return jsonify(
        {
            "days_left": days_left,
            "estimated_total_hst": int(round(clean["umur_hst"] + days_left)),
            "current_umur_hst": clean["umur_hst"],
            "harvest_date": harvest.isoformat(),
            "ready": days_left <= 0,
            "features_used": {f: clean[f] for f in FEATURES},
        }
    )


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5057, debug=False)
