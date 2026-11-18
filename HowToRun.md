# Cara Menjalankan Demo LettuGrow

>Panduan ini untuk laptop Windows yang sama dengan yang dipakai menyiapkan demo. Tidak perlu melatih ulang model atau memasukkan token/rahasia apa pun.

## Persiapan sekali saja

Konfigurasi lokal, akun Firebase, model, dan dependensi sudah disiapkan di laptop ini. Cukup ikuti langkah; jangan mengedit konfigurasi atau menyalin file rahasia.

Jika memakai laptop atau salinan proyek yang berbeda, skrip akan berhenti pada prasyarat yang belum ada. Minta pemilik proyek menyiapkan PHP 8.4, Composer, Python virtual environment, akses MySQL, dan kredensial Firebase secara lokal. Jangan mengirim file kredensial atau rahasia melalui chat.

## LANGKAH

### 1. Nyalakan MySQL di Laragon

1. Buka **Laragon**.
2. Klik **Start All**.
3. Pastikan MySQL menunjukkan status berjalan.

Database demo sudah disiapkan. Jangan hapus database `smart_farming`.

### 2. Buka emulator Android

1. Buka **Android Studio**.
2. Buka **Device Manager**.
3. Tekan tombol ▶ pada emulator Android yang biasa dipakai dan tunggu sampai layar Android terbuka.

Ponsel Android yang tersambung dengan USB debugging juga bisa dipakai. Emulator adalah pilihan paling sederhana.

### 3. Jalankan demo

Di VS Code, buka folder proyek utama. Pilih **Terminal → New Terminal**. Pastikan terminal berada di folder proyek utama, lalu tempel perintah ini:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\start_demo.ps1
```

Biarkan terminal terbuka. Skrip akan:

- memastikan MySQL, PHP, kredensial lokal, dependensi, dan model tersedia;
- menjalankan migrasi database yang belum diterapkan;
- membuka jendela Flask dan Laravel;
- menyambungkan emulator ke backend melalui USB/ADB;
- memasang dan menjalankan aplikasi Flutter.

**Jangan klik Run lagi di Android Studio** saat skrip ini sedang menjalankan aplikasi. Gunakan jendela emulator yang sudah terbuka.

### 4. Masuk dan lakukan prediksi

1. Masuk dengan akun Firebase yang sudah terdaftar. Jika belum punya akun, pilih **Daftar Sekarang**. Jangan pilih mode tamu untuk menyimpan prediksi.
2. Buka tab **Prediksi** atau tekan **Mulai Prediksi Baru**.
3. Isi nama lokasi kebun. Parameter contoh yang bisa dipakai:

	| Parameter | Nilai contoh |
	| --- | ---: |
	| Umur selada | 20 hari |
	| Suhu | 23 °C |
	| Kelembapan | 78% |
	| TDS | 720 ppm |
	| pH | 6.0 |

4. Tekan **Prediksi Waktu Panen**. Hasil muncul di layar, termasuk estimasi hari panen, fase tanaman, dan profil clustering.

Contoh nilai di atas sebelumnya menghasilkan estimasi **25 hari lagi**. Hasil dapat berbeda jika nilai input atau data model berubah.

## Pemeriksaan jika belum jalan

Saat kedua jendela backend sudah terbuka, alamat berikut bisa dibuka di browser laptop:

- Flask: [http://127.0.0.1:5000/health](http://127.0.0.1:5000/health) — status seharusnya `ok` dan semua model `true`.
- Laravel: [http://127.0.0.1:8000/up](http://127.0.0.1:8000/up) — seharusnya menampilkan `OK`.

| Gejala | Yang perlu dilakukan |
| --- | --- |
| Skrip mengatakan MySQL belum aktif | Buka Laragon, klik **Start All**, lalu jalankan skrip kembali. |
| Skrip mengatakan emulator/perangkat belum terhubung | Pastikan emulator sudah menyala di Android Studio. Jika memakai ponsel, sambungkan USB dan aktifkan USB debugging. |
| Port 5000 atau 8000 sudah dipakai | Tutup jendela Flask/Laravel dari percobaan sebelumnya. Jangan menjalankan skrip dua kali bersamaan. |
| Flask health bukan `ok` | Periksa jendela **Flask ML**. Jangan tutup jendela itu saat demo berlangsung. |
| Prediksi gagal atau menampilkan 503 | Pastikan jendela **Flask ML** dan **Laravel API** masih terbuka. Hentikan keduanya, lalu jalankan ulang skrip utama. |
| Aplikasi kembali meminta masuk | Masuk kembali dengan akun Firebase. Sesi yang dipulihkan semestinya langsung membuka beranda; bila berulang, pastikan kedua backend berjalan dan jangan gunakan mode tamu. |

## Mengakhiri demo

1. Di terminal yang menjalankan Flutter, tekan **q**.
2. Tutup jendela **Flask ML** dan **Laravel API**.
3. MySQL boleh dibiarkan aktif di Laragon jika masih dipakai.

## Catatan penting

- Jalankan dari laptop ini karena kredensial Firebase dan rahasia layanan disimpan secara lokal, bukan di Git. **Jangan mengirim atau menyalin isi file kredensial maupun rahasia ke chat.**
- Skrip menggunakan artefak model yang sudah tersedia. Tidak perlu menjalankan proses training sebelum demo.
- Pada penggunaan emulator/USB, tidak perlu mengubah alamat IP laptop. ADB menghubungkan aplikasi ke backend lokal.
- Skrip peluncur demo: [start_demo.ps1](start_demo.ps1).
