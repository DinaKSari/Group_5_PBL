"""
Training pipeline untuk model estimasi hari menuju panen selada.

Alur: dataset -> split -> latih dan evaluasi XGBoost -> latih ulang dengan seluruh data
-> simpan model ke artifacts/model.joblib.

Dataset Lettuce Growth Days menggunakan kolom Plant_ID, Temperature (°C),
Humidity (%), TDS Value (ppm), pH Level, dan Growth Days. Label days_left
dihitung sebagai hari terakhir per tanaman dikurangi Growth Days saat ini.
Jika CSV tidak tersedia, pipeline memakai dataset SAMPLE deterministik.
"""
from __future__ import annotations

import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import GroupShuffleSplit
from xgboost import XGBRegressor

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
        try:
            df = pd.read_csv(DATA_CSV, encoding="utf-8-sig")
        except UnicodeDecodeError:
            df = pd.read_csv(DATA_CSV, encoding="latin1")

        df.columns = df.columns.str.strip()
        source_columns = {
            "Plant_ID": "_group_id",
            "Growth Days": "umur_hst",
            "Temperature (°C)": "suhu",
            "Humidity (%)": "kelembapan",
            "TDS Value (ppm)": "tds",
            "pH Level": "ph",
        }
        missing = [c for c in source_columns if c not in df.columns]
        if missing:
            available = ", ".join(map(str, df.columns))
            raise SystemExit(
                "Kolom wajib data/lettuce.csv tidak ditemukan. "
                f"Kolom yang kurang: {missing}. Kolom tersedia: {available}."
            )
        data = df[list(source_columns)].rename(columns=source_columns)
        for column in data.columns:
            data[column] = pd.to_numeric(data[column], errors="coerce")
        data = data.dropna().reset_index(drop=True)
        data[TARGET] = data.groupby("_group_id")["umur_hst"].transform("max") - data["umur_hst"]
        data = data[data["umur_hst"].between(*RANGES["umur_hst"])].reset_index(drop=True)
        if data.empty:
            raise SystemExit("Tidak ada baris CSV valid dalam rentang umur_hst 1-45.")
        return data, "csv"

    sample = build_sample()
    sample["_group_id"] = np.arange(len(sample))
    return sample, "sample"


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
    X, y, groups = df[FEATURES], df[TARGET], df["_group_id"]
    train_idx, test_idx = next(
        GroupShuffleSplit(test_size=0.2, n_splits=1, random_state=42).split(X, y, groups)
    )
    X_train, X_test = X.iloc[train_idx], X.iloc[test_idx]
    y_train, y_test = y.iloc[train_idx], y.iloc[test_idx]

    model = XGBRegressor(
        objective="reg:squarederror",
        eval_metric="rmse",
        n_estimators=400,
        learning_rate=0.04,
        max_depth=4,
        min_child_weight=3,
        subsample=0.85,
        colsample_bytree=0.9,
        reg_alpha=0.05,
        reg_lambda=2.0,
        tree_method="hist",
        n_jobs=-1,
        random_state=42,
    )
    model.fit(X_train, y_train)
    results = [evaluate("XGBRegressor", y_test, model.predict(X_test))]

    # Evaluasi tetap memakai holdout; artefak produksi dilatih dengan semua data.
    model.fit(X, y)

    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    joblib.dump(model, ARTIFACTS / "model.joblib")
    meta = {
        "features": FEATURES,
        "target": TARGET,
        "ranges": RANGES,
        "selected_model": "XGBRegressor",
        "dataset_source": source,
        "n_rows": int(len(df)),
        "metrics": results,
    }
    (ARTIFACTS / "features.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")

    print(f"[train] source={source} rows={len(df)}")
    r = results[0]
    print(f"  {r['model']:22} MAE={r['MAE']:<6} RMSE={r['RMSE']:<6} R2={r['R2']}")
    print("[train] model digunakan: XGBRegressor -> artifacts/model.joblib")


if __name__ == "__main__":
    main()
