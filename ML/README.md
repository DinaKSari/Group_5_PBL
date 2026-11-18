# Cara Menjalankan Model Prediksi Panen Selada

Model menggunakan XGBoost untuk memperkirakan jumlah hari tersisa hingga panen. Jalankan perintah berikut dari folder root repository menggunakan PowerShell.

## 1. Siapkan lingkungan Python

```powershell
py -m venv ML/api/.venv
.\ML\api\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r ML/api/requirements.txt
```

Jika PowerShell menolak aktivasi virtual environment, jalankan `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`, lalu aktifkan kembali.

## 2. Latih model XGBoost

```powershell
python ML/api/train.py
```

Model dan metadatanya disimpan ke `ML/api/artifacts/model.joblib` dan `ML/api/artifacts/features.json`. Jika `ML/api/data/lettuce.csv` belum tersedia, script menggunakan dataset sample deterministik.

CSV Lettuce Growth Days yang digunakan memiliki kolom `Plant_ID`, `Temperature (°C)`, `Humidity (%)`, `TDS Value (ppm)`, `pH Level`, dan `Growth Days`. Script memetakan kolom sensor ke fitur model dan menghitung `days_left` sebagai hari Growth Days maksimum per tanaman dikurangi Growth Days saat ini. Dengan demikian, label mengasumsikan catatan terakhir tiap tanaman adalah akhir siklus/panen. Evaluasi memisahkan data berdasarkan `Plant_ID` agar baris dari tanaman yang sama tidak bocor ke data uji.

## 3. Jalankan API prediksi

Buka terminal PowerShell baru dari folder root repository, aktifkan virtual environment, lalu jalankan:

```powershell
.\ML\api\.venv\Scripts\Activate.ps1
python ML/api/app.py
```

API berjalan di `http://127.0.0.1:5057`. Biarkan terminal ini tetap terbuka. Endpoint `/health` dapat digunakan untuk memeriksa apakah model telah dimuat.

## 4. Uji prediksi

Di terminal PowerShell lain, kirim request ke endpoint `/predict`:

```powershell
$body = @{
	umur_hst = 20
	suhu = 23
	kelembapan = 75
	tds = 700
	ph = 6
} | ConvertTo-Json

Invoke-RestMethod -Uri http://127.0.0.1:5057/predict -Method Post -ContentType 'application/json' -Body $body
```

Respons mencakup `days_left` (perkiraan hari menuju panen), `estimated_total_hst`, `harvest_date`, dan `ready`. Nilai input harus berada dalam rentang berikut:

| Parameter | Rentang |
|---|---:|
| `umur_hst` | 1–45 |
| `suhu` | 10–40 °C |
| `kelembapan` | 30–100% |
| `tds` | 200–1500 ppm |
| `ph` | 4–9 |

API dikonfigurasi untuk menerima koneksi lokal (`127.0.0.1`) dan ditujukan untuk dipanggil Laravel di mesin yang sama.
