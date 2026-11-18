"""
Training pipeline untuk Machine Learning:
1. Regresi      : Estimasi hari menuju panen (days_left)
2. Klasifikasi  : Prediksi fase pertumbuhan / kesiapan panen (Semai, Vegetatif, Siap Panen)
3. Klusterisasi : Segmentasi profil mikroklimat lingkungan tanaman selada (Cosine K-Means)

Catatan metodologis (audit leakage - B1):
    Label `stage_class` adalah fungsi deterministik dari `umur_hst` (lihat
    assign_growth_stage). Karena `umur_hst` juga menjadi fitur, klasifikasi fase
    menjadi tugas yang *separable sempurna* -> akurasi ~1.0 bukan "penemuan" model.
    Pipeline ini menyertakan: DummyClassifier baseline, stratified cross-validation,
    confusion matrix, ROC-AUC (OvR), dan varian klasifikasi ENV-ONLY (tanpa umur)
    untuk menunjukkan kontras yang jujur.

Dataset: ML/data/lettuce_dataset_training.csv (atau lettuce_dataset_updated.xlsx)
"""
from __future__ import annotations

import json
import time
from pathlib import Path

import joblib
import numpy as np
import pandas as pd

import matplotlib
matplotlib.use("Agg")  # headless: simpan ke file, bukan window
import matplotlib.pyplot as plt

from sklearn.dummy import DummyClassifier
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.linear_model import LinearRegression
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    f1_score,
    mean_absolute_error,
    mean_squared_error,
    precision_score,
    r2_score,
    recall_score,
    roc_auc_score,
    roc_curve,
    silhouette_score,
)
from sklearn.model_selection import StratifiedKFold, cross_val_score, train_test_split
from sklearn.naive_bayes import GaussianNB
from sklearn.neighbors import KNeighborsClassifier
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler, label_binarize
from sklearn.svm import SVC

from cosine_kmeans import SphericalKMeans

try:
    from xgboost import XGBClassifier, XGBRegressor
    HAS_XGBOOST = True
except Exception:  # pragma: no cover - tergantung lingkungan
    HAS_XGBOOST = False

BASE_DIR = Path(__file__).resolve().parent
ML_DIR = BASE_DIR.parent
DATA_DIR = ML_DIR / "data"
ARTIFACTS = BASE_DIR / "artifacts"
REPORTS = ML_DIR / "reports"

FEATURES = ["umur_hst", "suhu", "kelembapan", "tds", "ph"]
ENV_FEATURES = ["suhu", "kelembapan", "tds", "ph"]

STAGE_LABELS = {
    0: "Semai (Nursery)",
    1: "Vegetatif (Pembesaran)",
    2: "Siap Panen (Mature)",
}

RANGES = {
    "umur_hst": (1, 48),
    "suhu": (15, 38),
    "kelembapan": (40, 95),
    "tds": (300, 1400),
    "ph": (4.5, 8.5),
}


def load_dataset() -> tuple[pd.DataFrame, str]:
    csv_path = DATA_DIR / "lettuce_dataset_training.csv"
    xlsx_path = DATA_DIR / "lettuce_dataset_updated.xlsx"

    if csv_path.exists():
        raw = pd.read_csv(csv_path, header=None)
        # 9 kolom: Plant_ID, Date, Temp_C, Hum_pct, TDS_ppm, pH, Growth_Days, Temp_F, Hum_ratio
        if raw.shape[1] >= 7:
            df = pd.DataFrame(
                {
                    "plant_id": raw[0],
                    "umur_hst": raw[6].astype(float),
                    "suhu": raw[2].astype(float),
                    "kelembapan": raw[3].astype(float),
                    "tds": raw[4].astype(float),
                    "ph": raw[5].astype(float),
                }
            )
            plant_harvest = df.groupby("plant_id")["umur_hst"].transform("max")
            df["days_left"] = np.clip(plant_harvest - df["umur_hst"], 0, None)
            return df, "lettuce_dataset_training.csv"

    if xlsx_path.exists():
        raw = pd.read_excel(xlsx_path)
        col_map = {
            "Plant_ID": "plant_id",
            "Growth Days": "umur_hst",
            "Temperature (°C)": "suhu",
            "Humidity (%)": "kelembapan",
            "TDS Value (ppm)": "tds",
            "pH Level": "ph",
        }
        df = raw.rename(columns=col_map)[["plant_id", "umur_hst", "suhu", "kelembapan", "tds", "ph"]].copy()
        plant_harvest = df.groupby("plant_id")["umur_hst"].transform("max")
        df["days_left"] = np.clip(plant_harvest - df["umur_hst"], 0, None)
        return df, "lettuce_dataset_updated.xlsx"

    return build_sample(), "sample_synthetic"


def build_sample(n: int = 1200, seed: int = 42) -> pd.DataFrame:
    """Dataset fallback jika file CSV tidak ditemukan."""
    rng = np.random.default_rng(seed)
    umur = rng.integers(1, 45, n).astype(float)
    suhu = rng.normal(25, 4, n).clip(18, 35)
    kelembapan = rng.normal(70, 8, n).clip(50, 85)
    tds = rng.normal(680, 120, n).clip(450, 950)
    ph = rng.normal(6.2, 0.4, n).clip(5.0, 7.5)

    total = 45.0 + rng.normal(0, 0.5, n)
    days_left = np.clip(np.round(total - umur), 0, 45)
    return pd.DataFrame(
        {
            "umur_hst": umur,
            "suhu": suhu,
            "kelembapan": kelembapan,
            "tds": tds,
            "ph": ph,
            "days_left": days_left,
        }
    )


def assign_growth_stage(umur_hst: pd.Series) -> pd.Series:
    """Klasifikasi fase pertumbuhan selada hidroponik:
    0: Semai (1 - 14 HST)
    1: Vegetatif (15 - 35 HST)
    2: Siap Panen (> 35 HST)
    """
    conditions = [
        (umur_hst <= 14),
        (umur_hst > 14) & (umur_hst <= 35),
        (umur_hst > 35),
    ]
    return pd.Series(np.select(conditions, [0, 1, 2], default=1), index=umur_hst.index)


def _timed_fit(model, X, y):
    """Fit model sambil mengukur waktu latih (detik)."""
    t0 = time.perf_counter()
    model.fit(X, y)
    return float(time.perf_counter() - t0)


def _inference_ms(model, X, kind: str, n_repeat: int = 100) -> float:
    """Ukur rata-rata waktu prediksi (milidetik) per sampel."""
    X = X.iloc[:n_repeat] if hasattr(X, "iloc") else X[:n_repeat]
    fn = model.predict_proba if kind == "proba" else model.predict
    t0 = time.perf_counter()
    for _ in range(10):
        fn(X)
    elapsed = (time.perf_counter() - t0) / 10
    return round(elapsed * 1000 / len(X), 4)


def train_and_evaluate():
    df, source = load_dataset()
    df["stage_class"] = assign_growth_stage(df["umur_hst"])

    X = df[FEATURES]
    y_reg = df["days_left"]
    y_cls = df["stage_class"]

    X_train, X_test, yr_train, yr_test, yc_train, yc_test = train_test_split(
        X, y_reg, y_cls, test_size=0.2, random_state=42
    )

    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)

    # ==========================================
    # 1. PELATIHAN & EVALUASI REGRESI
    # ==========================================
    reg_candidates = {
        "LinearRegression": LinearRegression(),
        "RandomForestRegressor": RandomForestRegressor(n_estimators=100, random_state=42),
    }
    if HAS_XGBOOST:
        reg_candidates["XGBoost"] = XGBRegressor(
            n_estimators=300, max_depth=4, learning_rate=0.05,
            subsample=0.9, colsample_bytree=0.9, random_state=42,
        )

    reg_results, reg_fitted = [], {}
    for name, model in reg_candidates.items():
        fit_s = _timed_fit(model, X_train, yr_train)
        preds = model.predict(X_test)
        reg_results.append({
            "model": name,
            "MAE": round(float(mean_absolute_error(yr_test, preds)), 3),
            "RMSE": round(float(np.sqrt(mean_squared_error(yr_test, preds))), 3),
            "R2": round(float(r2_score(yr_test, preds)), 3),
            "fit_seconds": round(fit_s, 3),
            "inference_ms": _inference_ms(model, X_test, "predict"),
        })
        reg_fitted[name] = model

    best_reg_name = min(reg_results, key=lambda r: r["RMSE"])["model"]
    best_reg_model = reg_fitted[best_reg_name]

    # ==========================================
    # 2. PELATIHAN & EVALUASI KLASIFIKASI
    # ==========================================
    cls_candidates = {
        "KNN": KNeighborsClassifier(n_neighbors=5),
        "SVM": SVC(probability=True, random_state=42),
        "Naive Bayes": GaussianNB(),
        "Random Forest": RandomForestClassifier(n_estimators=100, random_state=42),
    }
    if HAS_XGBOOST:
        cls_candidates["XGBoost"] = XGBClassifier(
            n_estimators=300, max_depth=4, learning_rate=0.05,
            subsample=0.9, colsample_bytree=0.9, random_state=42,
            eval_metric="mlogloss",
        )

    # Baseline: prediksi kelas mayoritas (titik referensi "tidak ada model")
    dummy = DummyClassifier(strategy="most_frequent").fit(X_train, yc_train)
    baseline_acc = float(accuracy_score(yc_test, dummy.predict(X_test)))

    cls_results, cls_fitted = [], {}
    for name, model in cls_candidates.items():
        fit_s = _timed_fit(model, X_train, yc_train)
        preds = model.predict(X_test)
        cv_scores = cross_val_score(model, X, y_cls, cv=cv, scoring="f1_macro", n_jobs=-1)
        entry = {
            "model": name,
            "Akurasi": round(float(accuracy_score(yc_test, preds)), 4),
            "Precision": round(float(precision_score(yc_test, preds, average="macro", zero_division=0)), 4),
            "Recall": round(float(recall_score(yc_test, preds, average="macro", zero_division=0)), 4),
            "F1": round(float(f1_score(yc_test, preds, average="macro", zero_division=0)), 4),
            "CV_F1_mean": round(float(cv_scores.mean()), 4),
            "CV_F1_std": round(float(cv_scores.std()), 4),
            "fit_seconds": round(fit_s, 3),
            "inference_ms": _inference_ms(model, X_test, "predict"),
        }
        # ROC-AUC (OvR) bila model mendukung probabilitas
        try:
            proba = model.predict_proba(X_test)
            classes = list(model.classes_)
            y_bin = label_binarize(yc_test, classes=classes)
            entry["ROC_AUC_OvR"] = round(float(roc_auc_score(y_bin, proba, average="macro")), 4)
        except Exception:
            entry["ROC_AUC_OvR"] = None
        cls_results.append(entry)
        cls_fitted[name] = model

    best_cls_name = max(cls_results, key=lambda r: r["CV_F1_mean"])["model"]
    best_cls_model = cls_fitted[best_cls_name]
    best_preds = best_cls_model.predict(X_test)
    cm = confusion_matrix(yc_test, best_preds, labels=[0, 1, 2])
    cls_report = classification_report(yc_test, best_preds, labels=[0, 1, 2], output_dict=True, zero_division=0)

    # --- Varian jujur: klasifikasi ENV-ONLY (tanpa umur_hst) ---
    # Bila stage ditentukan umur, model tanpa umur harus jatuh mendekati baseline.
    Xe_train, Xe_test, yce_train, yce_test = train_test_split(
        df[ENV_FEATURES], y_cls, test_size=0.2, random_state=42, stratify=y_cls
    )
    env_only = RandomForestClassifier(n_estimators=100, random_state=42).fit(Xe_train, yce_train)
    env_only_acc = float(accuracy_score(yce_test, env_only.predict(Xe_test)))

    # ==========================================
    # 3. KLUSTERISASI (COSINE K-MEANS) + ELBOW/SILHOUETTE
    # ==========================================
    # ENV_FEATURES distandardisasi sebelum Cosine K-Means agar perbedaan satuan
    # fitur tidak mendominasi arah vektor. Estimator menormalisasi tiap baris dan
    # centroid, lalu melakukan assignment berdasarkan cosine similarity.
    X_env = df[ENV_FEATURES]
    scaler = StandardScaler().fit(X_env)
    X_env_scaled = scaler.transform(X_env)
    X_env_unit = SphericalKMeans._normalize(X_env_scaled)
    k_range = range(2, 9)

    # Pemilihan k. Setelah scaling dan metrik cosine, silhouette tetap relatif
    # rendah: mikroklimat lingkungan bersifat KONTINU, bukan grup diskret yang
    # ketat. Maka argmax-silhouette bebas akan mengejar noise (k besar). Untuk
    # segmentasi yang dapat dibaca petani, k dibatasi ke rentang interpretabel
    # [2, K_INTERPRETABLE]; silhouette maksimal diambil di dalam rentang itu.
    K_INTERPRETABLE = 4
    elbow = []
    for k in k_range:
        km = SphericalKMeans(n_clusters=k, random_state=42, n_init=10).fit(X_env_scaled)
        elbow.append({
            "k": k,
            "inertia": round(float(km.inertia_), 4),
            "silhouette": round(float(silhouette_score(X_env_unit, km.labels_, metric="cosine")), 4),
        })
    best_k = max(
        (e for e in elbow if e["k"] <= K_INTERPRETABLE), key=lambda e: e["silhouette"]
    )["k"]

    # Pipeline scaler->Cosine K-Means menerima nilai mentah saat inferensi;
    # scaling dan normalisasi arah dijalankan konsisten dengan proses latih.
    kmeans_pipe = Pipeline([
        ("scaler", scaler),
        ("kmeans", SphericalKMeans(n_clusters=best_k, random_state=42, n_init=10)),
    ])
    _timed_fit(kmeans_pipe, X_env, None)
    cluster_labels = kmeans_pipe.predict(X_env)
    sil_score = float(silhouette_score(X_env_unit, cluster_labels, metric="cosine"))

    # Referensi global untuk pelabelan relatif (bukan ambang absolut).
    globe = {
        "suhu": float(df["suhu"].mean()),
        "kelembapan": float(df["kelembapan"].mean()),
        "tds": float(df["tds"].mean()),
        "ph": float(df["ph"].mean()),
    }

    cluster_profiles = {}
    for c in range(best_k):
        mask = cluster_labels == c
        sub = df[mask]
        cluster_profiles[str(c)] = {
            "count": int(mask.sum()),
            "avg_suhu": round(float(sub["suhu"].mean()), 1),
            "avg_kelembapan": round(float(sub["kelembapan"].mean()), 1),
            "avg_tds": round(float(sub["tds"].mean()), 1),
            "avg_ph": round(float(sub["ph"].mean()), 2),
        }

    def describe_cluster(profile):
        # Label relatif terhadap rata-rata global dataset, bukan ambang absolut.
        tags = []
        suhu, hum, tds, ph = (profile["avg_suhu"], profile["avg_kelembapan"],
                              profile["avg_tds"], profile["avg_ph"])
        tags.append("Sejuk" if suhu < globe["suhu"] - 0.5 else
                    "Hangat (transpirasi tinggi)" if suhu > globe["suhu"] + 0.5 else
                    "Suhu Normal")
        tags.append("Lembap" if hum > globe["kelembapan"] + 2 else
                    "Kering" if hum < globe["kelembapan"] - 2 else
                    "Kelembapan Normal")
        tags.append("Nutrisi Pekat (TDS tinggi)" if tds > globe["tds"] + 40 else
                    "Nutrisi Encer (TDS rendah)" if tds < globe["tds"] - 40 else
                    "Nutrisi Ideal")
        if ph < globe["ph"] - 0.15:
            tags.append("pH lebih asam")
        elif ph > globe["ph"] + 0.15:
            tags.append("pH lebih basa")
        return " • ".join(tags)

    for c_id, prof in cluster_profiles.items():
        prof["description"] = describe_cluster(prof)


    # ==========================================
    # 4. FIGUR EVALUASI (B3) -> ML/reports/
    # ==========================================
    REPORTS.mkdir(parents=True, exist_ok=True)

    # 4a. Confusion matrix
    fig, ax = plt.subplots(figsize=(5, 4))
    im = ax.imshow(cm, cmap="Greens")
    ax.set_xticks([0, 1, 2]); ax.set_yticks([0, 1, 2])
    ax.set_xticklabels(["Semai", "Vegetatif", "Siap"], fontsize=8)
    ax.set_yticklabels(["Semai", "Vegetatif", "Siap"], fontsize=8)
    for i in range(3):
        for j in range(3):
            ax.text(j, i, str(cm[i, j]), ha="center", va="center",
                    color="black" if cm[i, j] < cm.max() / 2 else "white")
    ax.set_xlabel("Prediksi"); ax.set_ylabel("Aktual")
    ax.set_title(f"Confusion Matrix - {best_cls_name}")
    fig.colorbar(im, ax=ax, fraction=0.046)
    fig.tight_layout(); fig.savefig(REPORTS / "confusion_matrix.png", dpi=130); plt.close(fig)

    # 4b. ROC-AUC (OvR) untuk model terpilih
    try:
        proba = best_cls_model.predict_proba(X_test)
        classes = list(best_cls_model.classes_)
        y_bin = label_binarize(yc_test, classes=classes)
        fig, ax = plt.subplots(figsize=(5, 4))
        for idx, cls in enumerate(classes):
            fpr, tpr, _ = roc_curve(y_bin[:, idx], proba[:, idx])
            ax.plot(fpr, tpr, label=f"{STAGE_LABELS[cls]} (AUC={roc_auc_score(y_bin[:, idx], proba[:, idx]):.3f})")
        ax.plot([0, 1], [0, 1], "k--", lw=0.8)
        ax.set_xlabel("False Positive Rate"); ax.set_ylabel("True Positive Rate")
        ax.set_title("ROC Curve (One-vs-Rest)")
        ax.legend(fontsize=7, loc="lower right")
        fig.tight_layout(); fig.savefig(REPORTS / "roc_auc.png", dpi=130); plt.close(fig)
    except Exception:
        pass

    # 4c. Elbow (cosine inertia) + Cosine Silhouette
    fig, ax1 = plt.subplots(figsize=(6, 4))
    ks = [e["k"] for e in elbow]
    ax1.plot(ks, [e["inertia"] for e in elbow], "o-", color="tab:green", label="Cosine inertia (elbow)")
    ax1.set_xlabel("k"); ax1.set_ylabel("Cosine inertia", color="tab:green")
    ax2 = ax1.twinx()
    ax2.plot(ks, [e["silhouette"] for e in elbow], "s--", color="tab:orange", label="Silhouette")
    ax2.set_ylabel("Silhouette Score", color="tab:orange")
    ax1.set_title("Pemilihan k - Elbow & Silhouette")
    fig.tight_layout(); fig.savefig(REPORTS / "elbow_silhouette.png", dpi=130); plt.close(fig)

    # 4d. Feature importance (regresi terpilih)
    importances = None
    if hasattr(best_reg_model, "feature_importances_"):
        importances = best_reg_model.feature_importances_
    elif hasattr(best_reg_model, "coef_"):
        importances = np.abs(best_reg_model.coef_)
    if importances is not None:
        order = np.argsort(importances)
        fig, ax = plt.subplots(figsize=(6, 3.5))
        ax.barh([FEATURES[i] for i in order], importances[order], color="tab:green")
        ax.set_title(f"Feature Importance - {best_reg_name}")
        fig.tight_layout(); fig.savefig(REPORTS / "feature_importance.png", dpi=130); plt.close(fig)

    # ==========================================
    # 5. SIMPAN ARTIFAK MODEL & METADATA
    # ==========================================
    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    joblib.dump(best_reg_model, ARTIFACTS / "model.joblib")
    joblib.dump(best_cls_model, ARTIFACTS / "classifier.joblib")
    joblib.dump(kmeans_pipe, ARTIFACTS / "cluster.joblib")

    metadata = {
        "dataset_source": source,
        "n_rows": int(len(df)),
        "features": FEATURES,
        "env_features": ENV_FEATURES,
        "ranges": RANGES,
        "stage_labels": STAGE_LABELS,
        "xgboost_available": HAS_XGBOOST,
        "regression": {
            "target": "days_left",
            "selected_model": best_reg_name,
            "metrics": reg_results,
        },
        "classification": {
            "target": "stage_class",
            "selected_model": best_cls_name,
            "note": "stage_class adalah fungsi deterministik umur_hst; akurasi ~1.0 mencerminkan separabilitas trivial, bukan penemuan model.",
            "baseline_most_frequent_accuracy": round(baseline_acc, 4),
            "env_only_accuracy_no_age": round(env_only_acc, 4),
            "confusion_matrix": cm.tolist(),
            "classification_report": cls_report,
            "metrics": cls_results,
        },
        "clustering": {
            "algorithm": f"StandardScaler + Spherical K-Means (cosine similarity, k={best_k})",
            "distance_metric": "cosine",
            "k_selection": f"cosine silhouette maksimal dalam rentang interpretabel k=2..{K_INTERPRETABLE} (mikroklimat kontinu)",
            "n_clusters": best_k,
            "silhouette_score": round(sil_score, 4),
            "global_means": {k: round(v, 2) for k, v in globe.items()},
            "elbow_silhouette": elbow,
            "profiles": cluster_profiles,
        },
    }

    (ARTIFACTS / "features.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")

    # ==========================================
    # 6. RINGKASAN KE LAYAR
    # ==========================================
    print(f"\n[TRAIN SUCCESS] Dataset: {source} ({len(df)} rows) | XGBoost: {'ya' if HAS_XGBOOST else 'TIDAK'}")

    print(f"\n--- 1. Regresi (Best: {best_reg_name}) ---")
    for r in reg_results:
        print(f"  {r['model']:22} MAE={r['MAE']:<6} RMSE={r['RMSE']:<6} R2={r['R2']:<6} "
              f"fit={r['fit_seconds']}s inf={r['inference_ms']}ms")

    print(f"\n--- 2. Klasifikasi (Best by CV-F1: {best_cls_name}) ---")
    print(f"  Baseline (most_frequent) accuracy = {baseline_acc:.4f}")
    print(f"  ENV-ONLY (tanpa umur) accuracy    = {env_only_acc:.4f}  <- kontras jujur vs ~1.0")
    for r in cls_results:
        print(f"  {r['model']:15} Akurasi={r['Akurasi']:<7} F1={r['F1']:<7} "
              f"CV-F1={r['CV_F1_mean']}±{r['CV_F1_std']} AUC={r['ROC_AUC_OvR']} inf={r['inference_ms']}ms")
    print("  Confusion matrix (baris=aktual, kolom=prediksi):")
    for row in cm:
        print("   ", [int(v) for v in row])

    print(f"\n--- 3. Klusterisasi (StandardScaler + Cosine K-Means, k optimum={best_k}) ---")
    print(f"  k terpilih via silhouette maks. | Silhouette k={best_k}: {sil_score:.4f}")
    for c_id, prof in cluster_profiles.items():
        print(f"  Cluster {c_id}: {prof['description']} (n={prof['count']}) - "
              f"Suhu={prof['avg_suhu']}C, Hum={prof['avg_kelembapan']}%, TDS={prof['avg_tds']}, pH={prof['avg_ph']}")

    print(f"\n[ARTEFAK] -> {ARTIFACTS}")
    print(f"[FIGUR]   -> {REPORTS} (confusion_matrix, roc_auc, elbow_silhouette, feature_importance)")


if __name__ == "__main__":
    train_and_evaluate()
