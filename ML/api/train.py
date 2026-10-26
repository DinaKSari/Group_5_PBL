"""
Training pipeline untuk model estimasi hari menuju panen selada.

Alur: dataset -> split -> baseline (LinearRegression) + pembanding (RandomForestRegressor)
-> evaluasi (MAE, RMSE, R2) -> simpan model terbaik ke artifacts/model.joblib.

Jika data/lettuce.csv tidak tersedia, dibuat dataset SAMPLE (deterministik) supaya
pipeline bisa jalan end-to-end. Ganti dengan dataset Kaggle final (jurijsruko/lettuce)
dengan kolom: umur_hst, suhu, kelembapan, tds, ph, days_left.
"""
from __future__ import annotations

import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import train_test_split

BASE_DIR = Path(__file__).resolve().parent
DATA_CSV = BASE_DIR / "data" / "lettuce.csv"
ARTIFACTS = BASE_DIR / "artifacts"

FEATURES = ["umur_hst", "suhu", "kelembapan", "tds", "ph"]
TARGET = "days_left"

# Rentang validasi (dipakai juga oleh app.py dan divalidasi ulang di Laravel).
RANGES = {
    "umur_hst": (1, 45),
    "suhu": (10, 40),
    "kelembapan": (30, 100),
    "tds": (200, 1500),
    "ph": (4, 9),
}


def load_dataset() -> tuple[pd.DataFrame, str]:
    if DATA_CSV.exists():
        df = pd.read_csv(DATA_CSV)
        missing = [c for c in FEATURES + [TARGET] if c not in df.columns]
        if missing:
            raise SystemExit(f"data/lettuce.csv kurang kolom: {missing}")
        return df[FEATURES + [TARGET]].dropna().reset_index(drop=True), "csv"
    return build_sample(), "sample"


def build_sample(n: int = 1200, seed: int = 42) -> pd.DataFrame:
    """Dataset SAMPLE: siklus panen selada hidroponik ~30-40 hari.

    Kondisi menjauh dari optimum (suhu 22, kelembapan 75, TDS 700, pH 6.0)
    -> pertumbuhan melambat -> total hari panen bertambah.
    """
    rng = np.random.default_rng(seed)
    umur = rng.integers(5, 30, n).astype(float)
    suhu = rng.normal(23, 4, n).clip(10, 40)
    kelembapan = rng.normal(75, 10, n).clip(30, 100)
    tds = rng.normal(700, 180, n).clip(200, 1500)
    ph = rng.normal(6.0, 0.5, n).clip(4, 9)

    def penalty(value, optimum, scale):
        return ((value - optimum) / scale) ** 2

    total = (
        32
        + 6 * penalty(suhu, 22, 6)
        + 3 * penalty(kelembapan, 75, 15)
        + 4 * penalty(tds, 700, 250)
        + 5 * penalty(ph, 6.0, 1.2)
    )
    total += rng.normal(0, 1.2, n)
    days_left = np.clip(np.round(total - umur), 1, 38)
    return pd.DataFrame(
        {"umur_hst": umur, "suhu": suhu, "kelembapan": kelembapan, "tds": tds, "ph": ph, TARGET: days_left}
    )


def evaluate(name: str, y_true, y_pred) -> dict:
    mse = mean_squared_error(y_true, y_pred)
    return {
        "model": name,
        "MAE": round(float(mean_absolute_error(y_true, y_pred)), 3),
        "RMSE": round(float(np.sqrt(mse)), 3),
        "R2": round(float(r2_score(y_true, y_pred)), 3),
    }


def main() -> None:
    df, source = load_dataset()
    X, y = df[FEATURES], df[TARGET]
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    candidates = {
        "LinearRegression": LinearRegression(),
        "RandomForestRegressor": RandomForestRegressor(n_estimators=200, max_depth=12, random_state=42),
    }

    results, fitted = [], {}
    for name, model in candidates.items():
        model.fit(X_train, y_train)
        results.append(evaluate(name, y_test, model.predict(X_test)))
        fitted[name] = model

    best_name = min(results, key=lambda r: r["RMSE"])["model"]
    best_model = fitted[best_name]

    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    joblib.dump(best_model, ARTIFACTS / "model.joblib")
    meta = {
        "features": FEATURES,
        "target": TARGET,
        "ranges": RANGES,
        "selected_model": best_name,
        "dataset_source": source,
        "n_rows": int(len(df)),
        "metrics": results,
    }
    (ARTIFACTS / "features.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")

    print(f"[train] source={source} rows={len(df)}")
    for r in results:
        print(f"  {r['model']:22} MAE={r['MAE']:<6} RMSE={r['RMSE']:<6} R2={r['R2']}")
    print(f"[train] model terbaik: {best_name} -> artifacts/model.joblib")


if __name__ == "__main__":
    main()
