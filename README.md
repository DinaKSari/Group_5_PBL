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
> parameter sensor tersimpan di database, dan identitas user berasal dari Firebase Auth
> (`user_uid` dikirim bersama request untuk scoping riwayat & monitoring).

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

---

# 📁 Struktur Repository

Struktur repository akan dikembangkan mengikuti pemisahan komponen utama project:

```text
Group_5_PBL/
│
├── ML/
│   ├── dataset/
│   ├── notebooks/
│   ├── preprocessing/
│   ├── models/
│   └── README.md
│
├── smart_farming/
│   ├── mobile/
│   ├── backend/
│   └── README.md
│
├── Documents/
│   ├── Proposal/
│   ├── QA/
│   ├── Testing/
│   └── Reports/
│
├── Screenshots/
│
└── README.md
```

> Struktur folder dapat berubah selama proses pengembangan sesuai kebutuhan implementasi.

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

# 🚀 Cara Menjalankan (Deployment)

Sistem berjalan sebagai **3 layanan** di jaringan lokal yang sama (laptop + perangkat Android/emu):

| Layanan  | Perintah (dari folder)         | Alamat                   |
| -------- | ------------------------------ | ------------------------ |
| ML Flask | `python ML/api/app.py`         | `http://<ip>:5000` (`/predict`, `/health`) |
| Laravel  | `php artisan serve --host=0.0.0.0 --port=8000` (di `backend/`) | `http://<ip>:8000/api` + admin `/admin` |
| Flutter  | `flutter run` / `flutter build apk --release` (di `smart_farming/`) | aplikasi di perangkat |

**Jalan pintas satu perintah**: jalankan `run_all.bat` di root repo. Skrip ini
membangkitkan Flask (5000) & Laravel (0.0.0.0:8000) pada terminal terpisah,
melakukan health-check dengan `curl`, mencetak IPv4 LAN, lalu (mode `flutter`/`apk`)
menjalikan aplikasi. Mode: `run_all.bat flutter` | `apk` | `none`.

> `smart_farming/lib/config/api_config.dart` mengarahkan `baseUrl` ke `10.0.2.2:8000`
> (emulator). Untuk perangkat fisik, ubah ke IPv4 LAN laptop (mis. `192.168.1.x`)
> dan pastikan `AndroidManifest.xml` mengizinkan cleartext HTTP — keduanya khusus
> pengujian lokal.

**Panel Admin (Filament)**: buka `http://<ip>:8000/admin` → login
`admin@gmail.com` / `12345678`. Menu: Predictions (kolom **Petani** menampilkan
identitas penginput via tabel `app_users`), Sensor Readings, Activity Logs.

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
| Flask REST API         | 🟢 Selesai & Teruji (`/predict`, `/health`, `/devices`)   |
| Flutter Application    | 🟢 Register/Login Firebase Auth, monitoring & riwayat dari backend |
| Laravel Admin Panel    | 🟢 Filament (`/admin`): kelola prediksi, sensor, log, kolom Petani (identitas Tier-3 `app_users`) |
| Database               | 🟢 Laravel + SQLite (`predictions`, `sensor_readings`, `app_users`, `activity_logs`) |
| Integration            | 🟢 End-to-end Flutter → Laravel → Flask → ML teruji (device + smoke test)  |
| Release / Deployment   | 🟢 APK `--release` terpasang di perangkat; `run_all.bat` 1-perintah (Flask+Laravel) |
| Testing                | 🟢 QA Plan & Backend Unit Testing (`test_app.py`) Selesai |
| Documentation          | 🟢 README disinkronkan (temuan ML jujur) + screenshot + RTM |

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
