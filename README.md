# 🌱 Aplikasi Prediksi Estimasi Waktu Panen Tanaman Selada

**Project-Based Learning (PBL) — Kelompok 5**

Aplikasi mobile berbasis **Machine Learning** untuk membantu pengguna, khususnya petani selada, dalam memperoleh **estimasi waktu panen tanaman selada** berdasarkan data pertumbuhan dan kondisi lingkungan.

---

## 👥 Anggota Kelompok

| No | Nama                                    | NIM            | Peran                                                         |
| -- | --------------------------------------- | -------------- | ------------------------------------------------------------- |
| 1  | **Dina Kumala Sari**                    | `244107020072` | Ketua Tim, Mobile Developer, ML Engineer, Koordinator QA Plan |
| 2  | **M. Yahya Irvansyah**                  | `244107020032` | Mobile Developer, ML Engineer, Unit Testing                   |
| 3  | **Muhammad Pearl Ocshada**              | `244107020064` | Backend Developer, Mobile Developer, ML Engineer, API Testing |
| 4  | **Sharren Elvaretta Pratamadya Fianto** | `244107020191` | Dokumentator, Mobile Developer, ML Engineer, Tester           |
| 5  | **Anselmus Marcel Putra Andria**        | `244107020141` | Tester, Dokumentator, Mobile Developer, ML Engineer           |

---

## 📌 Deskripsi Project

Project ini merupakan pengembangan aplikasi mobile untuk membantu pengguna dalam **memprediksi dan mengestimasi waktu panen tanaman selada** dengan memanfaatkan teknologi **Machine Learning**.

Aplikasi menggunakan data pertumbuhan tanaman dan kondisi lingkungan seperti:

* Suhu
* Kelembapan
* TDS
* pH
* Umur atau jumlah hari pertumbuhan tanaman

Data tersebut akan diproses oleh model Machine Learning untuk menghasilkan estimasi waktu menuju panen.

Aplikasi mobile dikembangkan menggunakan **Flutter**, sedangkan model Machine Learning akan diintegrasikan melalui **REST API menggunakan Flask**.

---

## 🎯 Tujuan Project

Project ini memiliki beberapa tujuan utama:

1. Mengembangkan model Machine Learning untuk melakukan estimasi jumlah hari menuju panen tanaman selada.
2. Mengembangkan REST API menggunakan Flask sebagai penghubung aplikasi mobile dengan model Machine Learning.
3. Mengembangkan aplikasi mobile menggunakan Flutter.
4. Mengintegrasikan Flutter, REST API Flask, Machine Learning, dan database.
5. Menyediakan fitur input parameter tanaman, prediksi waktu panen, hasil prediksi, dan riwayat prediksi.
6. Melakukan pengujian perangkat lunak melalui unit testing, API testing, integration testing, dan system testing.
7. Menghasilkan prototype aplikasi yang dapat dikembangkan lebih lanjut.

---

## 💡 Konsep Aplikasi

Secara umum, alur aplikasi adalah:

```text
Input Data Tanaman
        ↓
Validasi Input
        ↓
Flutter Mobile App
        ↓
REST API Flask
        ↓
Preprocessing
        ↓
Machine Learning Model
        ↓
Prediksi Waktu Panen
        ↓
Response JSON
        ↓
Flutter
        ↓
Hasil Prediksi
        ↓
Riwayat Prediksi
```

Arsitektur sistem yang dirancang adalah:

```text
Flutter UI
    ↓
State Management
    ↓
API Service / HTTP Client
    ↓
Laravel REST API  (auth header user_uid, riwayat, sensor readings)
    ↓
Flask REST API (microservice ML, stateless)
    ↓
Validation & Preprocessing
    ↓
Machine Learning Model
    ↓
JSON Response
    ↓
Flutter UI
```

> **Catatan arsitektur final:** Flutter tidak lagi memanggil Flask langsung.
> Laravel (`smart_farming/backend`, port 8000) menjadi satu-satunya backend bagi aplikasi:
> `POST /api/predict` diproksikan ke Flask (`MlInferenceService`), hasil prediksi dan
> parameter sensor tersimpan di database, dan identitas user diambil dari **ID token Firebase
> yang divalidasi di server** (middleware `firebase.auth` + `kreait/firebase-php`; nilai
> `uid` hasil verifikasi itulah yang dipakai untuk men-scope riwayat & monitoring, dan
> tersimpan di kolom `user_uid`). Client tidak lagi menentukan identitasnya sendiri lewat
> body/query — mengirim `user_uid` milik orang lain tidak lagi bisa membaca data orang lain.

Rancangan arsitektur dan pipeline Machine Learning mengikuti rancangan teknis pada proposal.

---

## ✨ Fitur Utama

### 1. 🌱 Input Parameter Pertanian

Pengguna dapat memasukkan parameter yang diperlukan untuk melakukan prediksi, seperti:

* Suhu
* Kelembapan
* TDS
* pH
* Umur pertumbuhan tanaman

### 2. 🤖 Prediksi Waktu Panen

Model Machine Learning memproses data yang diberikan pengguna untuk menghasilkan estimasi waktu menuju panen.

### 3. 📊 Hasil Prediksi

Hasil prediksi ditampilkan pada aplikasi mobile sehingga pengguna dapat mengetahui estimasi waktu panen berdasarkan parameter yang dimasukkan.

### 4. 📋 Riwayat Prediksi

Hasil prediksi dapat disimpan dan ditampilkan kembali sebagai riwayat.

### 5. ✅ Validasi Input

Aplikasi melakukan validasi terhadap input pengguna untuk mencegah:

* Data kosong
* Tipe data yang tidak sesuai
* Nilai yang tidak valid
* Nilai negatif pada parameter tertentu

### 6. 🔗 REST API Integration

Flutter berkomunikasi dengan backend Flask melalui REST API untuk mengirim data input dan menerima hasil prediksi.

Daftar fitur utama tersebut mengacu pada rancangan produk pada proposal PBL.

---

## 🧠 Machine Learning

Sistem Machine Learning pada proyek ini mengintegrasikan tiga pilar pemodelan untuk memberikan analisis pertumbuhan selada yang komprehensif:

1. **Regresi**: Memperkirakan jumlah hari menuju panen (`days_left`) berdasarkan parameter lingkungan dan umur tanaman.
2. **Klasifikasi**: Mengklasifikasikan fase pertumbuhan / kesiapan panen tanaman (*Semai*, *Vegetatif*, *Siap Panen*).
3. **Klusterisasi (Clustering)**: Menyegmen profil mikroklimat tanaman hidroponik menjadi 2 zona (Sejuk / Hangat) menggunakan `StandardScaler` + K-Means.

### Dataset

Dataset yang digunakan:

**Lettuce Growth Days Analysis**

Sumber:
* [Kaggle — Lettuce Growth Days Analysis](https://www.kaggle.com/datasets/jurijsruko/lettuce)
* File training: `ML/data/lettuce_dataset_training.csv` (2.213 baris data) & `ML/data/lettuce_dataset_updated.xlsx`

Variabel dataset yang digunakan:

| Variabel    | Keterangan              |
| ----------- | ----------------------- |
| Plant ID    | Identitas tanaman       |
| Date        | Tanggal pengamatan      |
| Temperature | Suhu (°C)               |
| Humidity    | Kelembapan (%)          |
| TDS Value   | Nilai TDS (ppm)         |
| pH Level    | Tingkat pH              |
| Growth Days | Umur tanaman (HST)      |

### Pipeline Machine Learning

```text
Dataset (lettuce_dataset_training.csv)
   ↓
Data Cleaning & EDA (model_ml_pbl_group5.ipynb)
   ↓
Preprocessing & Feature Engineering
   ↓
Train/Test Split (80:20)
   ↓
Multi-Task Training:
   ├── 1. Regresi (LinearRegression vs RandomForest vs XGBoost)
   ├── 2. Klasifikasi (KNN vs SVM vs Naive Bayes vs RandomForest vs XGBoost)
   └── 3. Klusterisasi (StandardScaler + K-Means, k dipilih silhouette → k=2)
   ↓
Evaluasi & Validasi Model (baseline, CV-F1, confusion matrix, ROC-AUC, elbow+silhouette)
   ↓
Export Artefak Model (model.joblib, classifier.joblib, cluster.joblib)
   ↓
Flask REST API Microservice (app.py)
   ↓
Flutter Mobile App (Smart Farming)
```

### Model & Hasil Evaluasi

> **Catatan metodologis (penting, dibaca jujur).** Label klasifikasi fase
> `stage_class` adalah **fungsi deterministik** dari `umur_hst` (≤14 → Semai,
> 15–35 → Vegetatif, >35 → Siap Panen), sementara `umur_hst` juga menjadi fitur
> input. Akibatnya tugas klasifikasi **separable sempurna** — akurasi ~1.0 pada
> Naive Bayes / Random Forest / XGBoost **bukan "penemuan" model**, melainkan
> konsekuensi definisi label. Nilai tambah ML proyek ini terletak pada **regresi**
> (estimasi `days_left`) dan **klusterisasi** mikroklimat. Untuk membuktikan hal
> ini, pipeline menyertakan **baseline** (prediksi kelas mayoritas), **cross-validation
> stratified 5-fold**, **confusion matrix**, **ROC-AUC (OvR)**, dan varian
> **ENV-ONLY** (klasifikasi tanpa umur). Seluruh metrik tersimpan di
> `ML/api/artifacts/features.json`; figur di `ML/reports/`.

#### 1. Pemodelan Regresi (Estimasi Hari Panen) — *model inti*
* **Kandidat**: `LinearRegression`, `RandomForestRegressor`, `XGBoost`.
* **Metrik**: MAE, RMSE, $R^2$ (test split 80:20) + waktu latih & inferensi.

| Model | MAE | RMSE | $R^2$ | Inferensi (ms/sampel) |
| --- | --- | --- | --- | --- |
| **Linear Regression** *(terpilih)* | 0.285 | 0.507 | 0.999 | 0.005 |
| **Random Forest Regressor** | 0.307 | 0.587 | 0.998 | 0.055 |
| **XGBoost** | 0.328 | 0.552 | 0.998 | 0.014 |

*Model terbaik (RMSE minimum) = Linear Regression, disimpan ke `artifacts/model.joblib`.
Regresi inilah yang menghasilkan estimasi "X hari lagi" di aplikasi.*

#### 2. Pemodelan Klasifikasi (Fase Kesiapan Panen) — *degeneratif, lihat catatan*
* **Kelas target**: `0` Semai (1–14 HST), `1` Vegetatif (15–35 HST), `2` Siap Panen (>35 HST).
* **Kandidat**: KNN, SVM, Gaussian Naive Bayes, Random Forest, XGBoost.
* **Metrik**: Akurasi, F1 (macro), CV-F1 (5-fold), ROC-AUC (OvR).

| Model | Akurasi | F1 (macro) | CV-F1 (5-fold) | ROC-AUC (OvR) |
| --- | --- | --- | --- | --- |
| KNN | 0.9458 | 0.9470 | 0.9109 ± 0.008 | 0.9899 |
| SVM | 0.6862 | 0.5219 | 0.5002 ± 0.012 | 0.9979 |
| Naive Bayes | 1.0000 | 1.0000 | 0.9987 ± 0.001 | 1.0000 |
| Random Forest | 1.0000 | 1.0000 | 0.9994 ± 0.001 | 1.0000 |
| **XGBoost** *(terpilih by CV-F1)* | 1.0000 | 1.0000 | 1.0000 ± 0.000 | 1.0000 |

* **Baseline (kelas mayoritas)**: akurasi **0.4831**.
* **ENV-ONLY (tanpa `umur_hst`)**: akurasi **0.6479** — kontras jujur: tanpa umur,
  lingkungan saja hampir tidak bisa memisahkan fase (mendekati baseline),
  menegaskan bahwa ~1.0 berasal dari kebocoran label-umur, bukan sinyal lingkungan.
* **Confusion matrix** (XGBoost, baris=aktual): diagonal `[132, 214, 97]`, nol error.
* Model terpilih disimpan ke `artifacts/classifier.joblib` (dipakai hanya sebagai
  pelabelan fase; keputusan panen sesungguhnya dari regresi `days_left`).

#### 3. Pemodelan Klusterisasi (Profil Mikroklimat Lingkungan)
* **Algoritma**: `StandardScaler` → `KMeans`. Penskalaan wajib karena rentang TDS
  (300–1400) mendominasi jarak Euclidean terhadap pH (4,5–8,5); tanpa scaling,
  kluster terpecah hanya menurut nutrisi dan kehilangan makna mikroklimat.
* **Pemilihan k**: silhouette merata rendah (0,20–0,25 untuk semua k) → mikroklimat
  bersifat **kontinu**, bukan grup diskret ketat. Agar tetap interpretabel, k
  dibatasi rentang 2–4 dan dipilih silhouette maksimum → **k = 2** (silhouette **0,235**).
* **Segmentasi (relatif terhadap rata-rata global: suhu 27,1 °C, TDS 599 ppm)**:
  * `Cluster 0` — **Hangat (transpirasi tinggi)**: suhu ~31,1 °C, n = 1.295.
  * `Cluster 1` — **Sejuk**: suhu ~21,4 °C, n = 918.
* Kurva elbow+silhouette lengkap tersimpan di `ML/reports/elbow_silhouette.png`;
  model (pipeline scaler+KMeans) disimpan ke `artifacts/cluster.joblib`.

**Figur evaluasi** (dihasilkan `python ML/api/train.py`): `ML/reports/confusion_matrix.png`,
`roc_auc.png`, `elbow_silhouette.png`, `feature_importance.png`.

---

## 🛠️ Teknologi yang Digunakan

### Mobile

* Flutter
* Dart
* HTTP Client
* Provider / Riverpod

### Backend

* Python
* Flask
* REST API
* JSON

### Machine Learning

* Python
* Pandas
* NumPy
* Scikit-learn
* Joblib / Pickle
* Google Colab

### Testing & Development

* Git
* GitHub
* Postman
* pytest
* Flutter Test
* Black-box Testing
* Integration Testing

---

# 📅 Progress Mingguan

Progress pengembangan mengikuti roadmap 16 minggu yang telah ditentukan dalam proposal PBL.

> **Keterangan:** Checklist akan diperbarui selama proses pengembangan project.

---

## 🟢 Minggu 1 — Inisiasi Project

**Target:**

* [x] Pembentukan kelompok
* [x] Pembagian peran anggota
* [x] Identifikasi masalah
* [x] Menentukan ide project
* [x] Menentukan scope awal
* [x] Menentukan mata kuliah yang diintegrasikan

**Output:**

Scope awal project dan pembagian tanggung jawab anggota.

---

## 🟢 Minggu 2 — Studi Dataset & Kebutuhan

**Target:**

* [x] Mencari kandidat dataset
* [x] Mempelajari dataset pertumbuhan selada
* [x] Identifikasi variabel dataset
* [x] Menentukan kebutuhan sistem
* [x] Menentukan target Machine Learning

**Output:**

Kandidat dataset dan requirement awal sistem.

---

## 🟢 Minggu 3 — EDA & Perancangan Sistem

**Target:**

* [x] Exploratory Data Analysis
* [x] Analisis distribusi data
* [x] Analisis missing value
* [x] Analisis outlier
* [x] Analisis korelasi
* [x] Perancangan alur aplikasi
* [x] Perancangan arsitektur sistem

**Output:**

Hasil EDA, studi kelayakan, dan desain awal sistem.

---

## 🟢 Minggu 4 — Finalisasi Proposal & QA Plan

**Target:**

* [x] Finalisasi proposal PBL
* [x] Finalisasi scope project
* [x] Menentukan strategi pengujian
* [x] Menyusun QA Plan awal
* [x] Menentukan test case awal

**Output:**

Proposal PBL dan QA Plan.

**Checkpoint: CP-1 — Proposal**

---

## 🟢 Minggu 5 — Preprocessing & Baseline Model

**Target:**

* [x] Data cleaning
* [x] Preprocessing dataset
* [x] Feature engineering
* [x] Train/test split
* [x] Membuat baseline model
* [x] Scaffolding project Flutter
* [x] Scaffolding Flask API

**Output:**

Baseline Machine Learning model dan skeleton aplikasi.

---

## 🟢 Minggu 6 — Model Comparison & Evaluation

**Target:**

* [x] Training SVM
* [x] Training KNN
* [x] Training Naive Bayes
* [x] Training XGBoost
* [x] Membandingkan performa model
* [x] Menghitung Akurasi
* [x] Menghitung Precision (macro)
* [x] Menghitung Recall (macro)
* [x] Menghitung F1 (macro)
* [x] Menghitung ROC-AUC(OvR)
* [x] Menghitung Waktu tuning / prediksi 
* [x] Menentukan kandidat model terbaik

**Output:**

Perbandingan performa model Machine Learning.

---

## 🟢 Minggu 7 — Model Export, API & UI

**Target:**

* [x] Export model (Regresi, Klasifikasi, Klusterisasi)
* [x] Implementasi Flask REST API (`app.py`)
* [x] Membuat endpoint prediksi (`/predict`), metadata (`/health`), devices (`/devices`)
* [x] Membuat form input Flutter
* [ ] Implementasi API service
* [ ] Implementasi komunikasi Flutter → Flask

**Output:**

Microservice API Flask lengkap dengan 3 model ML teruji dan UI form aplikasi.

---

## 🟢 Minggu 8 — Integrasi Awal & Demo

**Target:**

* [x] Integrasi Flask + Machine Learning
* [x] Pengujian request/response & Unit Test Backend (`test_app.py`)
* [ ] Integrasi awal Flutter + Flask
* [ ] Demo fitur awal
* [ ] Perbaikan bug awal

**Output:**

Backend ML microservice stabil dan lulus unit test otomatis.

**Checkpoint: CP-2 — Milestone 1**

---

## 🟠 Minggu 9 — End-to-End Prediction

**Target:**

* [ ] Integrasi Flutter → Flask
* [ ] Integrasi Flask → ML Model
* [ ] Implementasi prediction flow
* [ ] Pengujian prediksi end-to-end
* [ ] Penyusunan draft test case

**Output:**

Alur prediksi end-to-end.

---

## 🟠 Minggu 10 — Database & Riwayat

**Target:**

* [ ] Implementasi database
* [ ] Penyimpanan hasil prediksi
* [ ] Implementasi halaman riwayat
* [ ] Error handling
* [ ] Empty state
* [ ] Loading state

**Output:**

Feature completion untuk prediksi dan riwayat.

---

## 🟠 Minggu 11 — Penyempurnaan Sistem

**Target:**

* [ ] Penyempurnaan UI
* [ ] Penyempurnaan API
* [ ] Penyempurnaan model
* [ ] Perbaikan bug
* [ ] Validasi input
* [ ] Peningkatan user experience

**Output:**

Candidate release aplikasi.

---

## 🟠 Minggu 12 — Interim QA

**Target:**

* [ ] Menjalankan test case
* [ ] Integration testing
* [ ] API testing
* [ ] Black-box testing
* [ ] Identifikasi bug
* [ ] Bug fixing
* [ ] Evaluasi model

**Output:**

Hasil interim QA dan perbaikan sistem.

**Checkpoint: CP-3 — Milestone 2**

---

## 🔵 Minggu 13 — Regression & Compatibility Testing

**Target:**

* [ ] Regression testing
* [ ] Compatibility testing
* [ ] Usability testing
* [ ] Pengujian pada emulator/perangkat Android
* [ ] Perbaikan bug hasil testing

**Output:**

Hasil QA iteration.

---

## 🔵 Minggu 14 — Performance & Bug Fixing

**Target:**

* [ ] Performance testing
* [ ] Pengukuran response API
* [ ] Pengukuran inference model
* [ ] Identifikasi bottleneck
* [ ] Perbaikan bug
* [ ] Finalisasi release candidate

**Output:**

Release Candidate.

---

## 🔵 Minggu 15 — Final Evaluation & Testing

**Target:**

* [ ] Evaluasi final Machine Learning
* [ ] Final testing aplikasi
* [ ] Final API testing
* [ ] Final integration testing
* [ ] Final regression testing
* [ ] Persiapan deployment

**Output:**

Final Release Candidate.

---

## 🔵 Minggu 16 — Finalisasi & Demo

**Target:**

* [ ] Demo aplikasi
* [ ] Finalisasi laporan
* [ ] Finalisasi dokumentasi
* [ ] Repository cleanup
* [ ] Finalisasi README
* [ ] Finalisasi bukti testing
* [ ] Presentasi project

**Output:**

Final Project PBL.

**Checkpoint: CP-4 — Final**

---

# 🧪 Quality Assurance

Pengujian sistem dilakukan untuk memastikan setiap bagian aplikasi berjalan sesuai kebutuhan.

Jenis pengujian yang digunakan:

| Jenis Testing               | Tools / Metode                 | Target                                    |
| --------------------------- | ------------------------------ | ----------------------------------------- |
| Unit Testing Backend        | pytest                         | Validation, service, prediction           |
| Unit/Widget Testing Flutter | flutter test                   | Validator, model, widget                  |
| API Testing                 | Postman                        | Request, response, status, error handling |
| Integration Testing         | Flutter + Flask + ML           | Alur prediksi end-to-end                  |
| Black-box Testing           | Requirement-based              | Kesesuaian fungsi                         |
| White-box Testing           | Logic review + unit test       | Jalur logika penting                      |
| Usability Testing           | Skenario / observasi           | Kemudahan penggunaan                      |
| Compatibility Testing       | Android device/emulator        | Kompatibilitas perangkat                  |
| Performance Testing         | Response/inference measurement | Identifikasi bottleneck                   |

Project memiliki target minimal **15 test case fungsional** yang akan dieksekusi dan didokumentasikan.
Tabel di atas berisi **27 test case** (TC-016 s.d. TC-018 non-fungsional; TC-019 s.d. TC-027
ditambahkan 2026-11-16 bersama Remote Config, entri sensor manual, naskah tunnel dan penandaan
APK release). Status eksekusi tiap kebutuhan dipetakan di `Documents/QA/RTM_Kelompok5.xlsx`;
TC-019 s.d. TC-024 sudah lulus sebagai `flutter test` tanpa akses jaringan, sisanya butuh
perangkat/keystore milik manusia (lihat `docs/RUNBOOK_MANUAL.md` R7).

---

# 📋 Test Case

| ID     | Skenario                      | Expected Result                 |
| ------ | ----------------------------- | ------------------------------- |
| TC-001 | Input parameter valid         | Prediksi ditampilkan            |
| TC-002 | Field wajib kosong            | Validasi ditampilkan            |
| TC-003 | Input teks pada field numerik | Input ditolak / validasi        |
| TC-004 | Nilai negatif                 | Validasi gagal                  |
| TC-005 | API JSON valid                | HTTP 200 dan response sesuai    |
| TC-006 | API data tidak lengkap        | HTTP 400 dan error              |
| TC-007 | Model dipanggil               | Nilai prediksi dikembalikan     |
| TC-008 | API tidak tersedia            | Error informatif                |
| TC-009 | Simpan prediksi               | Riwayat tersimpan               |
| TC-010 | Buka aplikasi Android         | Aplikasi berjalan               |
| TC-011 | Navigasi                      | Perpindahan halaman sesuai alur |
| TC-012 | Loading request               | Loading ditampilkan             |
| TC-013 | JSON tidak sesuai             | Aplikasi tidak crash            |
| TC-014 | History kosong                | Empty state ditampilkan         |
| TC-015 | Prediksi end-to-end           | Alur lengkap berhasil           |
| TC-016 | Performance: waktu respons API dan inferensi | Tidak ada antre/timeout; dicatat di `docs/PLAN.md` (≈0,09 s lokal) |
| TC-017 | Compatibility: varian perangkat/emulator Android | Aplikasi ter-install dan berfungsi |
| TC-018 | Usability: alur login → prediksi → riwayat | Pengguna menyelesaikan alur tanpa panduan |
| TC-019 | Prioritas base URL: `--dart-define` > Remote Config > default build; slash akhir dinormalisasi | `ApiConfig.resolve` menghasilkan URL yang sama untuk `.../` dan `...` (`test/remote_settings_test.dart`) |
| TC-020 | Remote Config gagal/tidak tersedia (timeout 3 s, JSON error, offline) | Holder tetap memakai nilai sebelumnya, app **tidak** melempar exception |
| TC-021 | `minimum_supported_version` Remote Config > versi APK | Banner non-dismissible muncul di Home menyebut kedua angka; app tetap dipakai. Versi build metadata `+N` tidak dihitung |
| TC-022 | Entri manual di luar rentang (mis. pH 12, TDS 50) | Ditolak di perangkat dengan teks "harus di antara <min> dan <max>", 0 request keluar |
| TC-023 | Entri manual valid → `POST /api/sensor` | Body memakai nama kolom kontrak ML + `source: "manual"`; 201 = sukses, dashboard ikut ter-invalidate |
| TC-024 | Entri manual saat mode Tamu / sesi kedaluwarsa / server mati / server menggantung | `AuthFailure` (sebelum request), `AuthFailure` 401, `NetworkFailure`, `ServerFailure` berbatas waktu — bukan exception mentah |
| TC-025 | Rangkaian penyalaan server (`deploy/start_tunnel.ps1`) idempoten di atas Laragon yang sudah jalan | MySQL → Flask → Laravel → ngrok muncul berurutan di `deploy/logs/`; `-Status` tidak mengubah apa pun |
| TC-026 | APK release ditandatangani keystore kelompok | `apksigner verify --print-certs` = `Signer #1 certificate DN: CN=LettuGrow` + scheme v2 `true`; **bukan** `CN=Android Debug`. (`keytool -printcert -jarfile` tidak berlaku: APK Flutter tidak memakai signature v1/JAR) |
| TC-027 | Build rilis hanya HTTPS | `usesCleartextTraffic` hanya ada di `src/debug/AndroidManifest.xml` |

---

# 📁 Struktur Repository

Kondisi aktual setelah integrasi Flutter → Laravel → Flask (bukan lagi rencana awal):

```text
Group_5_PBL/
│
├── ML/
│   ├── api/                    app.py (Flask :5000), train.py, requirements.txt (dipin),
│   │                           artifacts/*.joblib (model terlatih — ikut di git), test_app.py
│   ├── data/                   lettuce_dataset_training.csv / .xlsx
│   ├── reports/                hasil evaluasi & grafik
│   ├── model_ml_pbl_group5.ipynb          EDA + pipeline utama (dipakai di laporan)
│   ├── klasifikasi_perbandingan_selada.ipynb, PBL_..._Muhammad_Pearl_Ocshada.ipynb
│   └── README.md
│
├── smart_farming/
│   ├── lib/                    Flutter (Clean Architecture per fitur: domain/data/presentation)
│   │   ├── core/               api_client, failures, error_messages, remote_settings, session
│   │   └── features/           auth, home, history, prediction, sensor, notification, onboarding
│   ├── test/                   74 tes (unit + kontrak HTTP + widget)
│   ├── android/                applicationId com.lettgrow.app (namespace masih com.example.smart_farming)
│   ├── tool/                   run_android.ps1, make_keystore.ps1, build_release.ps1
│   └── backend/                Laravel 13 + Filament (API :8000 + panel /admin)
│       ├── app/                models, HTTP controllers, middleware VerifyFirebaseIdToken, resources
│       ├── database/           9 migration + seeder admin (kredensial dari .env, tanpa default)
│       ├── routes/api.php      /predict, /predictions, /sensor, /sensor/latest, /devices —
│       │                       semuanya di dalam group middleware firebase.auth
│       └── .env.example        satu-satunya template kredensial yang masuk git
│
├── deploy/                     menjadikan laptop server: start_tunnel.ps1/.bat, windows-autostart/
│                               (task SYSTEM saat boot), logs/ (gitignored), README.md
├── tool/                       migrate_sqlite_to_mysql.php (proses migrasi data lama)
├── docs/                       PLAN.md, RUNBOOK_MANUAL.md (langkah manusia-only + tes perangkat)
├── Documents/                  Proposal, QA (test case & RTM), Testing, Reports
├── Screenshots/
└── run_all.bat                 pintasan development (Flask + Laravel + flutter run)
```

File kredensial yang **sengaja tidak masuk git**: `smart_farming/backend/.env`, service account
Firebase di `backend/storage/app/private/`, `android/app/google-services.json`,
`android/key.properties`, keystore, `deploy/tunnel.config.json`. Lihat §2 di bawah.

---

# 👨‍💻 Pembagian Fokus Pengembangan

### Dina Kumala Sari

* Lead training Machine Learning
* Model evaluation
* Arsitektur aplikasi
* Home page
* QA Plan
* Requirement Traceability Matrix
* Git workflow

### M. Yahya Irvansyah

* Preprocessing
* Feature engineering
* Eksperimen model
* Halaman prediksi
* Navigasi
* Provider/Riverpod
* Unit testing Flutter

### Muhammad Pearl Ocshada

* Flask REST API
* Endpoint `/predict`
* Model loading
* API service Flutter
* Error handling
* API testing menggunakan Postman

### Sharren Elvaretta Pratamadya Fianto

* Exploratory Data Analysis
* Statistik deskriptif
* Visualisasi dataset
* Styling/UI
* Copy/label aplikasi
* Dokumentasi project
* Manual & black-box testing

### Anselmus Marcel Putra Andria

* Data Quality Report
* Missing value
* Duplikasi
* Outlier
* UI halaman Riwayat
* Eksekusi test case
* Bug tracking

Pembagian tanggung jawab teknis ini mengikuti rancangan organisasi tim dalam proposal.

---

# 📚 Mata Kuliah Terintegrasi

Project PBL ini mengintegrasikan tiga mata kuliah:

1. **Pemrograman Mobile**

   * Dosen: Habibie Ed Dien, S.Kom., M.T.

2. **Pembelajaran Mesin**

   * Dosen: Usman Nurhasan, S.Kom., M.T.

3. **Penjaminan Mutu Perangkat Lunak**

   * Dosen: M. Hasyim Ratsanjani, S.Kom., M.Kom.

Program Studi D4 Teknik Informatika
Jurusan Teknologi Informasi
Politeknik Negeri Malang
Semester 5 — Tahun Akademik 2026/2027.

---

# 🚀 Cara Menjalankan Project di Laptop Kalian

Panduan langkah demi langkah untuk anggota kelompok yang baru pertama kali menyalakan project ini
di laptop sendiri (Windows). Semua perintah di PowerShell; perintah `cmd.exe` diberi tanda. Kalau
ada yang gagal, langsung ke **§10 Troubleshooting** — gejalanya sudah dipetakan ke penyebabnya.

## 🗺️ Peta sistem (baca dulu 30 detik)

```text
HP / emulator
   │  http(s)://<host>:8000/api   (+ header Authorization: idToken Firebase)
   ▼
Laravel  :8000  ──►  MySQL :3306        database `smart_farming`
   │        └──►     Flask ML :5000     hanya bind 127.0.0.1, wajib header X-ML-Token
   │                        └──►        ML/api/artifacts/*.joblib (model terlatih, ikut di repo)
   └──►  /admin   panel Filament

ngrok (opsional) : 8000  ──►  https://<domain>.ngrok-free.dev/api   untuk user di luar LAN
```

| Komponen          | Folder                      | Port | Dijalankan oleh                      |
| ----------------- | --------------------------- | ---- | ------------------------------------ |
| Aplikasi Flutter  | `smart_farming/`            | —    | `flutter run` / APK di HP            |
| Laravel API+admin | `smart_farming/backend/`    | 8000 | `php artisan serve`                  |
| Flask ML          | `ML/api/`                   | 5000 | `python app.py`                      |
| MySQL             | `C:\laragon\bin\mysql\...`  | 3306 | Laragon, atau `start_tunnel.ps1`     |
| Tunnel publik     | `deploy/`                   | 4040 | `deploy\start_tunnel.ps1` (ngrok)    |

**Tiga hal yang tidak boleh tertukar:** Flask ML tidak boleh diakses langsung dari HP (Laravel yang
manggil, pakai rahasia bersama), `/admin` adalah panel Filament (bukan bagian API), dan tanpa
MySQL yang hidup seluruh endpoint API gagal walaupun Laravel terlihat "jalan".

---

## 1. Prasyarat — versi yang teruji di laptop ini

| Alat          | Versi teruji             | Cek versi                | Catatan                                                        |
| ------------- | ------------------------ | ------------------------ | -------------------------------------------------------------- |
| Git           | 2.x                      | `git --version`          | —                                                              |
| PHP           | 8.5.5 NTS x64 (min 8.3)  | `php -v`                 | butuh ekstensi `pdo_mysql`, `curl`, `mbstring`, `openssl`, `zip` |
| Composer      | 2.9.5                    | `composer -V`            | —                                                              |
| MySQL         | 8.0.30 (Community)       | `mysqld --version`       | paling praktis lewat **Laragon** (sudah membawa PHP + MySQL)   |
| Python        | 3.10.6                   | `python --version`       | Flask ML; versi paket diikat di `ML/api/requirements.txt`      |
| Flutter       | 3.47.1 stable            | `flutter --version`      | Dart 3.13.1 (`pubspec.yaml` minta `sdk: ^3.13.1`)              |
| Android SDK   | lewat Android Studio     | `flutter doctor`         | build APK rilis butuh `cmdline-tools` + `build-tools`         |
| JDK           | 17 (teruji 21.0.12)      | `java -version`          | AGP 9.1.0 / Gradle 9.3.1 diunduh otomatis oleh wrapper         |
| ngrok         | 3.x + akun free          | `ngrok version`          | **hanya** kalau mau URL publik                                 |
| Node.js       | 24.11 (opsional)         | `node -v`                | hanya untuk `npm run build`; API & Filament tidak membutuhkannya |

```powershell
flutter doctor    # yang boleh merah cuma hal yang tidak dipakai project ini (iOS/Visual Studio/Chrome)
```

Instalasi paling ringkas di Windows: **Laragon** (PHP+MySQL+Composer) → **Android Studio** (SDK+JDK)
→ **Flutter SDK** → **Python 3.10** → tambahkan `flutter/bin`, `laragon/bin/php/...`,
`laragon/bin/mysql/.../bin` ke `PATH`.

---

## 2. Yang TIDAK ikut ter-clone (harus dibuat/diambil sendiri)

Sengaja tidak masuk git karena berisi kredensial. Tanpa `google-services.json` **dan** service
account JSON, tidak ada seorang pun bisa login — bukan sekadar fitur yang hilang.

| File yang hilang                                | Di mana ditaruh                                 | Dari mana                                                   | Efek kalau tidak ada                          |
| ----------------------------------------------- | ----------------------------------------------- | ----------------------------------------------------------- | --------------------------------------------- |
| `google-services.json`                          | `smart_farming/android/app/`                    | Firebase Console → project → Android app `com.lettgrow.app` | `flutter run`/build Android gagal             |
| service account JSON (admin SDK)                 | `smart_farming/backend/storage/app/private/`    | Console → Project settings → Service accounts → Generate     | semua endpoint API balas **503**              |
| `smart_farming/backend/.env`                    | —                                               | salin dari `.env.example` (lihat §5)                         | Laravel tidak punya `APP_KEY`/DB              |
| keystore + `android/key.properties`             | `%USERPROFILE%\.android` + `smart_farming/android/` | `tool\make_keystore.ps1` (lihat §9)                     | APK rilis ditolak build (kecuali `-AllowDebugSigning`) |
| `deploy/tunnel.config.json` (opsional)          | `deploy/`                                       | salin dari `tunnel.config.example.json`                      | hanya kalau autofinder salah tebak path       |

> Project Firebase kelompok: **`smart-farming-683ec`**. Minta akses anggota ke pemilik project —
> kredensial service account tidak dikirim lewat chat, unduh sendiri dari Console.

---

## 3. Clone repository

```powershell
git clone https://github.com/DinaKSari/Group_5_PBL.git
cd Group_5_PBL
git checkout feature-letugrow-m1-keamanan-mysql
```

⚠️ **Status hari ini (2026-11-16):** branch `feature-letugrow-m1-keamanan-mysql` — yang berisi
integrasi Flutter → Laravel, autentikasi Firebase nyata, database MySQL, skrip `deploy/` dan build
rilis — **belum di-push** (kebijakan tim: `git push` harus diminta eksplisit). Branch ini 24 commit
di depan `origin/main` dan `origin/davelop`. Sampai branch itu di-push, kalian harus minta salinan
repo dari laptop pemilik branch, atau minta push ke GitHub. Di `origin/main`/`origin/davelop` folder
`deploy/` belum ada.

---

## 4. Nyalakan MySQL + buat database

Laragon: klik **Start All** (MySQL jalan tanpa service Windows). Lalu:

```powershell
mysql -u root -e "CREATE DATABASE IF NOT EXISTS smart_farming CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -e "SHOW DATABASES LIKE 'smart_farming';"
```

`root` tanpa password adalah setup laptop kuliah ini. Aman selama MySQL tidak `listen` di publik —
jangan dibalik jadi `0.0.0.0` dan jangan dipakai di mesin yang bisa diakses orang lain.

---

## 5. Backend Laravel (API + panel admin)

```powershell
cd smart_farming\backend
composer install
Copy-Item .env.example .env
php artisan key:generate
```

Edit `.env`, isi kelompok key berikut (semuanya sudah ada di file, tinggal diisi):

| Key                      | Isi seperti apa                                                                                                   |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------- |
| `APP_DEBUG`              | `false` wajib begitu ada tunnel/ngrok. `true` hanya saat debugging LAN.                                           |
| `DB_*`                   | `mysql / 127.0.0.1 / 3306 / smart_farming / root /` (password kosong) — sudah benar, cukup dicek.                 |
| `FIREBASE_CREDENTIALS`   | path relatif, mis. `storage/app/private/<nama-file-service-account>.json`                                         |
| `FIREBASE_PROJECT_ID`    | `smart-farming-683ec`                                                                                             |
| `FLASK_ML_SHARED_SECRET` | string acak 32 byte, **harus sama persis** dengan `ML_SHARED_SECRET` milik Flask. Generate: `php -r "echo bin2hex(random_bytes(32));"` |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` / `ADMIN_NAME` | akun panel `/admin`. Seeder **menolak jalan** kalau kosong, dan `ADMIN_PASSWORD` minimal 12 karakter. Tidak ada lagi password default `12345678`. |

```powershell
php artisan migrate --seed        # 9 migration + akun admin Filament
php artisan test                  # harapan: 29 passed (90 assertions)
```

Panel admin: `http://127.0.0.1:8000/admin/login` (login pakai `ADMIN_EMAIL`/`ADMIN_PASSWORD`).
Menu: Predictions, Sensor Readings, Activity Logs.

> `SERVER_HOST=0.0.0.0` di `.env` dibaca oleh `php artisan serve` (teruji: tanpa flag `--host`
> server langsung bind `0.0.0.0:8000`), jadi HP di satu Wi-Fi bisa langsung mengakses.
> Kalau laptop dipakai di jaringan yang tidak dipercaya, jalankan
> `php artisan serve --host=127.0.0.1` saja.

---

## 6. Flask ML

Dari folder `smart_farming\backend` (lanjutan §5) — atau ketik path absolut:

```powershell
cd ..\..\ML\api
python -m pip install -r requirements.txt
$env:ML_SHARED_SECRET = "<nilai FLASK_ML_SHARED_SECRET dari backend/.env>"
python app.py                    # jendela ini terpakai: Flask adalah server, jangan ditutup
```

Flask hanya bind `127.0.0.1`, jadi ia memang tidak dirancang untuk diakses HP langsung — hanya
Laravel yang memanggilnya.

Uji di terminal lain (Flask hanya menerima panggilan ber-token):

```powershell
curl.exe http://127.0.0.1:5000/health     # harapan: "status":"ok" + models_loaded semua true
curl.exe -X POST http://127.0.0.1:5000/predict -H "Content-Type: application/json" -d '{}'
#   harapan: 401 (tanpa header X-ML-Token, Flask menolak = perilaku benar)
```

> ⚠️ `ML/api/test_app.py` **sudah tertinggal dari implementasi: 5 dari 6 tesnya gagal** saat
> dijalankan sekarang (`python -m unittest test_app -v`): file itu tidak mengirim header `X-ML-Token`
> yang kini wajib, dan dua tesnya memanggil `/devices` yang sudah pindah dari Flask ke Laravel
> (`POST /api/devices`). Satu-satunya tes yang lulus adalah `/health`. Perintah itu sengaja
> **tidak** dimasukkan ke checklist §11 sampai file tesnya disinkronkan.

**Kenapa versi paket dipin:** `model.joblib`/`cluster.joblib` dipickle oleh numpy 2.x dan
`classifier.joblib` butuh xgboost. numpy 1.x = gagal muat artefak, dan gejalanya bukan "model tidak
akurat" tapi prosesnya mati saat startup. Jangan melatih ulang (`python train.py`) dengan
lingkungan berbeda kecuali kalian ikut men-commit artefak barunya.

Kalau kalian menjalankan Flask lewat `run_all.bat` atau `deploy\start_tunnel.ps1`, **tidak perlu**
men-set `$env:ML_SHARED_SECRET` manual — kedua skrip itu mengambil rahasianya dari `backend/.env`
(satu sumber kebenaran).

---

## 7. Aplikasi Flutter

```powershell
cd ..\..\smart_farming
flutter pub get
flutter analyze                # harapan: 0 error (4 info `withOpacity` deprecated memang sudah ada)
flutter test                   # harapan: 74 test, "All tests passed!"
```

Sambungkan HP dengan USB debugging (atau emulator), lalu satu perintah ini sudah cukup — ia
memeriksa Flask 5000 & Laravel 8000 (menyalakan yang mati di jendela baru dengan `-StartBackend`),
memasang `adb reverse tcp:8000 tcp:8000`, lalu `flutter run`:

```powershell
powershell -ExecutionPolicy Bypass -File tool\run_android.ps1 -StartBackend
# -CheckOnly  = hanya periksa backend, jangan launch
# -Device <id> / -Port <n> / -MlPort <n>
```

Karena ada forwarding ADB, HP melihat laptop sebagai `127.0.0.1:8000` — tidak bergantung IP laptop,
tidak bergantung Wi-Fi, dan tetap jalan di jaringan yang memblokir antar-perangkat (Wi-Fi kampus).
Alternatif tanpa kabel (HP & laptop harus saling terjangkau):

```powershell
flutter run --dart-define=API_BASE_URL=http://IP-LAPTOP:8000/api    # perangkat fisik
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api     # emulator Android
```

Alur uji manual yang paling cepat: **Register** (Firebase Auth, butuh `google-services.json`) →
**Beranda** (monitoring live dari backend) → **Catat Parameter Kebun** (5 nilai; coba pH 12 untuk
melihat validasi) → **Prediksi** → tab **Riwayat**.

---

## 8. Menyediakan API untuk user nyata (tunnel ngrok) — opsional

Dipakai hanya kalau HP tidak berada di jaringan yang sama dengan laptop / user sudah di luar.

```powershell
cd deploy
.\start_tunnel.ps1              # MySQL → Flask → Laravel → ngrok, cetak URL publik
```

| Bendera          | Fungsi                                                                                              |
| ---------------- | ---------------------------------------------------------------------------------------------------- |
| _(tanpa)_        | nyalakan semuanya; idempoten: port yang sudah hidup dilewati                                        |
| `-Status`        | lihat apa yang hidup + URL publik, tanpa mengubah apa pun                                          |
| `-Stop`          | matikan Laravel/Flask/ngrok milik skrip (MySQL dibiarkan); tambah `-MySql` untuk mematikan MySQL dengan `mysqladmin shutdown` (rapi, bukan kill paksa) |
| `-NoNgrok`       | lokal saja (HP lewat `adb reverse` / Wi-Fi)                                                          |
| `-TakeOver`      | rebut port 8000 dari `php artisan serve` asing yang jalan di jendela konsol kalian                  |
| `-WebPort` / `-MlPort` / `-Workers` | ubah port / jumlah worker (`PHP_CLI_SERVER_WORKERS`)                     |

Skrip berhenti dengan pesan jelas, bukan diam-diam, kalau: `FLASK_ML_SHARED_SECRET` kosong,
`APP_DEBUG` masih `true`, atau `/api/sensor/latest` tidak membalas **401 JSON** — tiga syarat bahwa
API benar-benar sehat sebelum tunnel dibuka.

URL publik hasil skrip disimpan di `deploy\last-url.txt`; daftarkan nilai itu sebagai parameter
Remote Config `api_base_url` (lihat `docs/RUNBOOK_MANUAL.md` R4) supaya APK tidak perlu dibangun
ulang setiap tunnel berganti alamat. ⚠️ Kuota ngrok free 20.000 request/bulan — **jangan pernah**
menambah polling `Timer` di aplikasi.

Autostart setelah boot (butuh Administrator sekali, dan membuat laptop menjadi server publik setiap
kali menyala — baca konsekuensinya di `deploy/README.md`):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File deploy\windows-autostart\install-autostart.ps1
```

---

## 9. Build APK rilis (untuk dibagikan ke HP teman)

```powershell
cd smart_farming
powershell -ExecutionPolicy Bypass -File tool\make_keystore.ps1     # SEKALI seumur hidup
powershell -ExecutionPolicy Bypass -File tool\build_release.ps1     # tiap rilis
```

- `make_keystore.ps1` menanyakan passphrase dua kali lewat prompt tersembunyi (tidak pernah tercetak,
  tidak pernah lewat chat) dan menulis `android/key.properties`. **Salin file `.keystore` ke luar
  laptop** — tanpanya APK baru tidak bisa dipasang menimpa versi lama.
- `build_release.ps1` membaca `version:` dari `pubspec.yaml` → `--dart-define=APP_VERSION=...`,
  menolak build tanpa `key.properties`, lalu memverifikasi tanda tangan dengan
  `apksigner verify --print-certs`. Bendera: `-ApiBaseUrl <url>` (menembak base URL ke build),
  `-Clean`, `-AllowDebugSigning` (untuk coba-coba, jangan dipakai rilis).
- Artefak: `build/app/outputs/flutter-apk/app-release.apk` (±55 MB; APK, bukan AAB, karena AAB tidak
  bisa di-sideload).

Pasang ke HP:

```powershell
adb devices
adb uninstall com.lettgrow.app        # WAJIB kalau HP pernah menerima APK debug/package lama
adb install build\app\outputs\flutter-apk\app-release.apk
```

Tanpa `adb uninstall` dulu, install gagal dengan `INSTALL_FAILED_UPDATE_INCOMPATIBLE` (tanda tangan
debug ≠ rilis), dan package `com.kelompok5.smart_farming` lama dianggap aplikasi yang berbeda.
Manifest rilis hanya HTTPS — `usesCleartextTraffic` hanya ada di `android/app/src/debug/`.

---

## 10. Troubleshooting

| Gejala                                                                    | Penyebab paling mungkin                                                       | Solusi                                                                 |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------------------ | ---------------------------------------------------------------------- |
| Semua API balas **503** `"Autentikasi server belum terkonfigurasi."`             | `FIREBASE_CREDENTIALS` kosong / file service account tidak ada                 | taruh JSON di `backend/storage/app/private/`, isi path-nya, `php artisan config:clear` |
| Prediksi balas **503** `"Layanan prediksi ML tidak dapat dihubungi."`            | Flask mati, atau `FLASK_ML_SHARED_SECRET` (Laravel) ≠ `ML_SHARED_SECRET` (Flask) | nyalakan Flask; samakan persis; jalankan Flask lewat `run_all.bat`/`start_tunnel.ps1` biar diambil dari `.env` |
| Prediksi balas **503** `"Model ML belum siap..."`                                 | artefak `artifacts/*.joblib` tidak bisa dimuat                                  | `python -m pip install -r ML/api/requirements.txt` (versi dipin, lihat §6)              |
| `python app.py` langsung mati saat startup                               | versi numpy/xgboost tidak cocok dengan artefak `.joblib`                       | `python -m pip install -r ML/api/requirements.txt` (jangan upgrade sebagian) |
| `Failed to load ... google-services.json` saat `flutter run`             | file belum diunduh dari Console                                                | §2; pastikan package id `com.lettgrow.app`                             |
| `SQLSTATE[HY000] [1049] Unknown database 'smart_farming'`                 | database belum dibuat / MySQL Laragon belum Start All                          | §4                                                                      |
| Seeder error `ADMIN_EMAIL dan ADMIN_PASSWORD`                             | `.env` belum diisi                                                             | isi keduanya; `ADMIN_PASSWORD` ≥ 12 karakter                           |
| HP tidak bisa mengakses `http://<ip-laptop>:8000`                         | beda jaringan / Windows Firewall / client isolation Wi-Fi kampus               | pakai `tool\run_android.ps1` (adb reverse) — jalur USB tidak lewat Wi-Fi |
| `Address already in use` saat `artisan serve`                             | port 8000 sudah dipegang Laravel lain / Laragon                                | `.\deploy\start_tunnel.ps1 -Status` lalu `-TakeOver`                   |
| `start_tunnel.ps1` berhenti: `API tidak balas 401 JSON`                   | yang menjawab 8000 bukan Laravel sehat (halaman error/`APP_DEBUG` aktif)       | perbaiki Laravel-nya dulu; ini gerbang pengaman, bukan bug skrip        |
| `start_tunnel.ps1 -Stop` gagal `could not be terminated`                  | layanan jalan sebagai SYSTEM (task autostart) di Session 0                     | PowerShell *Run as administrator* → `Disable-ScheduledTask -TaskName 'LettuGrow Tunnel'` lalu `-Stop` |
| Login di app gagal terus padahal akun sudah daftar                        | `google-services.json` milik project Firebase lain                             | keduanya harus project `smart-farming-683ec`                            |
| Muncul halaman interstitial "You are about to visit..." di browser        | header `ngrok-skip-browser-warning` tidak dikirim (normal untuk app)           | buka lewat aplikasi/`curl -H "ngrok-skip-browser-warning: x"`, bukan address bar |
| Stack trace/config terlihat di respons error                              | `APP_DEBUG=true` dan ada cache config lama                                     | set `false` lalu `php artisan config:clear`                             |
| Rilis tidak bisa dipasang di HP yang sudah ada APK debug                  | tanda tangan beda                                                              | `adb uninstall com.lettgrow.app`                                        |

---

## 11. Checklist verifikasi (semua harus hijau sebelum bilang "di laptopku jalan")

| Perintah                                                                       | Harapan                                   |
| ------------------------------------------------------------------------------ | ----------------------------------------- |
| `cd smart_farming\backend && php artisan test`                                 | `29 passed (90 assertions)`               |
| `cd ML\api && python -m unittest test_app -v`                                  | **BUKAN bukti lulus** — 5/6 gagal, file tes belum sinkron (§6) |
| `cd smart_farming && flutter test`                                             | `+74: All tests passed!`                  |
| `curl.exe http://127.0.0.1:5000/health`                                        | `"status":"ok"`                           |
| `curl.exe http://127.0.0.1:8000/up`                                            | 200                                       |
| `curl.exe http://127.0.0.1:8000/api/sensor/latest`                             | **401 + JSON** (bukan 200, bukan HTML)     |
| `curl.exe -X POST http://127.0.0.1:8000/api/predict -d '{}' -H "Content-Type: application/json"` | 401 JSON, tanpa kata `"exception"`/`"trace"` |
| buka `/admin/login`                                                            | 200, login dengan akun dari `.env`        |
| app: login → catat parameter → prediksi → riwayat                              | hasil "X Hari Lagi" nyata, riwayat terisi |

---

## 12. Ringkasan untuk yang sudah pernah setup

```powershell
# backend + ML + app, satu jendela per layanan (dev, bind 0.0.0.0)
.\run_all.bat flutter          # atau: apk | none

# pastikan backend hidup, pasang adb reverse, lalu flutter run ke HP via USB
powershell -ExecutionPolicy Bypass -File smart_farming\tool\run_android.ps1 -StartBackend

# laptop ini jadi server publik (MySQL → Flask → Laravel → ngrok)
.\deploy\start_tunnel.ps1
.\deploy\start_tunnel.ps1 -Status        # cek cepat, tidak mengubah apa pun
```

Dokumen pendamping: `docs/RUNBOOK_MANUAL.md` (langkah yang hanya bisa dilakukan manusia: Firebase
Console, rotasi rahasia, tes di perangkat), `docs/PLAN.md` (keputusan teknis), `deploy/README.md`
(detail skrip tunnel & kuota ngrok), `smart_farming/README.md` (arsitektur clean architecture app).


---

# 📌 Status Project

| Komponen               | Status                                                    |
| ---------------------- | --------------------------------------------------------- |
| Ide & Scope Project    | 🟢 Selesai                                                |
| Pembagian Tim          | 🟢 Selesai                                                |
| Proposal               | 🟢 Selesai                                                |
| Dataset                | 🟢 Tersedia (`ML/data/lettuce_dataset_training.csv`)      |
| EDA                    | 🟢 Selesai (`ML/model_ml_pbl_group5.ipynb`)               |
| Preprocessing          | 🟢 Selesai                                                |
| Machine Learning Model | 🟢 Selesai (Regresi + Klasifikasi + Klusterisasi, evaluasi jujur) |
| Flask REST API         | 🟢 `/health` + `/predict` (hanya bind 127.0.0.1, wajib `X-ML-Token`) · 🟡 `test_app.py` 5/6 gagal, belum sinkron — lihat §6 panduan |
| Flutter Application    | 🟢 Register/Login Firebase Auth, monitoring & riwayat dari backend, entri parameter manual |
| Laravel Admin Panel    | 🟢 Filament (`/admin`): kelola prediksi, sensor, log, kolom Petani (identitas Tier-3 `app_users`) |
| Database               | 🟢 **MySQL 8** (`predictions`, `sensor_readings`, `app_users`, `activity_logs`) — SQLite ditinggalkan 2026-11-16, datanya dipindah lewat `tool/migrate_sqlite_to_mysql.php` |
| Integration            | 🟢 End-to-end Flutter → Laravel → Flask → ML teruji (device + smoke test)  |
| Release / Deployment   | 🟢 APK `--release` terpasang di perangkat; `deploy\start_tunnel.ps1` (MySQL→Flask→Laravel→ngrok) + autostart SYSTEM · 🟡 branch kerja belum di-push |
| Testing                | 🟢 Laravel 29 tes (90 assertion) & Flutter 74 tes lulus · 🟡 6 tes Flask belum disinkronkan |
| Documentation          | 🟢 README (panduan jalan §Cara Menjalankan) + `docs/PLAN.md` + `docs/RUNBOOK_MANUAL.md` + RTM |

---

# 🚀 Target Akhir

Target akhir project adalah menghasilkan prototype aplikasi Android yang mampu melakukan **prediksi waktu panen tanaman selada secara end-to-end**, mulai dari input parameter oleh pengguna, pemrosesan melalui REST API, prediksi menggunakan model Machine Learning, hingga menampilkan hasil dan menyimpan riwayat prediksi.

Keberhasilan project ditargetkan mencakup aplikasi Flutter yang berjalan, minimal satu fitur Machine Learning yang menghasilkan prediksi nyata, model dengan evaluasi Akurasi, Precision (macro), Recall (macro), F1 (macro), ROC-AUC(OvR), Waktu tuning / prediksi , endpoint API yang dapat diuji, alur Flutter → Flask → ML → Flask → Flutter yang berjalan, serta dokumentasi testing dan requirement traceability.

---

## 👥 Kelompok 5

**Program Studi D4 Teknik Informatika**
**Jurusan Teknologi Informasi**
**Politeknik Negeri Malang**
**2026**
