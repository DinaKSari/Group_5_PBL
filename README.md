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
Flask REST API
    ↓
Validation & Preprocessing
    ↓
Machine Learning Model
    ↓
JSON Response
    ↓
Flutter UI
```

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

Model Machine Learning digunakan untuk melakukan **regresi**, yaitu memperkirakan jumlah hari menuju waktu panen berdasarkan parameter pertumbuhan dan kondisi lingkungan.

### Dataset

Dataset yang direncanakan digunakan adalah:

**Lettuce Growth Days Analysis**

Sumber:

[Kaggle — Lettuce Growth Days Analysis](https://www.kaggle.com/datasets/jurijsruko/lettuce)

Variabel dataset yang digunakan antara lain:

| Variabel    | Keterangan              |
| ----------- | ----------------------- |
| Plant ID    | Identitas tanaman       |
| Date        | Tanggal pengamatan      |
| Temperature | Suhu                    |
| Humidity    | Kelembapan              |
| TDS Value   | Nilai TDS               |
| pH Level    | Tingkat pH              |
| Growth Days | Jumlah hari pertumbuhan |

Dataset dan sumbernya tercantum pada proposal proyek.

### Pipeline Machine Learning

```text
Dataset
   ↓
Data Cleaning
   ↓
Exploratory Data Analysis
   ↓
Preprocessing
   ↓
Feature Engineering
   ↓
Train/Test Split
   ↓
Training Model
   ↓
Evaluasi
   ↓
Pemilihan Model Terbaik
   ↓
Export Model
   ↓
Flask REST API
   ↓
Flutter
```

### Model yang Direncanakan

Model yang akan dibandingkan:

* Linear Regression
* Decision Tree Regressor
* Random Forest Regressor

Evaluasi model menggunakan:

* MAE
* MSE / RMSE
* R²

Model terbaik akan dipilih berdasarkan performa validasi/testing, stabilitas, dan kesesuaian untuk implementasi.

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
* [] Menentukan target Machine Learning

**Output:**

Kandidat dataset dan requirement awal sistem.

---

## 🟢 Minggu 3 — EDA & Perancangan Sistem

**Target:**

* [ ] Exploratory Data Analysis
* [ ] Analisis distribusi data
* [ ] Analisis missing value
* [ ] Analisis outlier
* [ ] Analisis korelasi
* [ ] Perancangan alur aplikasi
* [ ] Perancangan arsitektur sistem

**Output:**

Hasil EDA, studi kelayakan, dan desain awal sistem.

---

## 🟢 Minggu 4 — Finalisasi Proposal & QA Plan

**Target:**

* [] Finalisasi proposal PBL
* [] Finalisasi scope project
* [] Menentukan strategi pengujian
* [] Menyusun QA Plan awal
* [] Menentukan test case awal

**Output:**

Proposal PBL dan QA Plan.

**Checkpoint: CP-1 — Proposal**

---

## 🟡 Minggu 5 — Preprocessing & Baseline Model

**Target:**

* [ ] Data cleaning
* [ ] Preprocessing dataset
* [ ] Feature engineering
* [ ] Train/test split
* [ ] Membuat baseline model
* [ ] Scaffolding project Flutter
* [ ] Scaffolding Flask API

**Output:**

Baseline Machine Learning model dan skeleton aplikasi.

---

## 🟡 Minggu 6 — Model Comparison & Evaluation

**Target:**

* [ ] Training Linear Regression
* [ ] Training Decision Tree Regressor
* [ ] Training Random Forest Regressor
* [ ] Membandingkan performa model
* [ ] Menghitung MAE
* [ ] Menghitung RMSE
* [ ] Menghitung R²
* [ ] Menentukan kandidat model terbaik

**Output:**

Perbandingan performa model Machine Learning.

---

## 🟡 Minggu 7 — Model Export, API & UI

**Target:**

* [ ] Export model
* [ ] Implementasi Flask REST API
* [ ] Membuat endpoint prediksi
* [ ] Membuat form input Flutter
* [ ] Implementasi API service
* [ ] Implementasi komunikasi Flutter → Flask

**Output:**

Prototype API dan UI aplikasi.

---

## 🟡 Minggu 8 — Integrasi Awal & Demo

**Target:**

* [ ] Integrasi awal Flutter + Flask
* [ ] Integrasi Flask + Machine Learning
* [ ] Pengujian request/response
* [ ] Demo fitur awal
* [ ] Perbaikan bug awal

**Output:**

Integrasi awal sistem dan demo milestone pertama.

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

# 📌 Status Project

| Komponen               | Status                |
| ---------------------- | --------------------- |
| Ide & Scope Project    | 🟢 Selesai            |
| Pembagian Tim          | 🟢 Selesai            |
| Proposal               | 🟢 Selesai            |
| Dataset                | 🟢 Kandidat tersedia  |
| EDA                    | 🟡 Dalam pengembangan |
| Preprocessing          | ⚪ Belum               |
| Machine Learning Model | ⚪ Belum               |
| Flask REST API         | ⚪ Belum               |
| Flutter Application    | 🟡 Dalam pengembangan |
| Database               | ⚪ Belum               |
| Integration            | ⚪ Belum               |
| Testing                | 🟡 QA Plan tersedia   |
| Documentation          | 🟡 Dalam pengembangan |

---

# 🚀 Target Akhir

Target akhir project adalah menghasilkan prototype aplikasi Android yang mampu melakukan **prediksi waktu panen tanaman selada secara end-to-end**, mulai dari input parameter oleh pengguna, pemrosesan melalui REST API, prediksi menggunakan model Machine Learning, hingga menampilkan hasil dan menyimpan riwayat prediksi.

Keberhasilan project ditargetkan mencakup aplikasi Flutter yang berjalan, minimal satu fitur Machine Learning yang menghasilkan prediksi nyata, model dengan evaluasi MAE/RMSE/R², endpoint API yang dapat diuji, alur Flutter → Flask → ML → Flask → Flutter yang berjalan, serta dokumentasi testing dan requirement traceability.

---

## 👥 Kelompok 5

**Program Studi D4 Teknik Informatika**
**Jurusan Teknologi Informasi**
**Politeknik Negeri Malang**
**2026**
