# Panduan Import Database XAMPP

Script universal untuk import database MySQL/MariaDB di XAMPP dengan **penanganan khusus untuk error encoding dan karakter khusus**.

## File yang Tersedia

1. **import_database.bat** - Import ke database yang sudah ada
2. **create_and_import.bat** - Buat database baru + import sekaligus

**✨ Update Terbaru (2026-07-11):**
- ✅ Fix error "Unknown command '\-'."
- ✅ Penanganan encoding UTF-8 otomatis
- ✅ Support file dengan/tanpa BOM
- ✅ Penanganan password MySQL yang lebih baik
- ✅ Error handling dan troubleshooting lengkap

## Cara Menggunakan

### Opsi 1: Import ke Database yang Sudah Ada

1. Pastikan XAMPP MySQL sudah running
2. Double-click file `import_database.bat`
3. **Masukkan password MySQL** (tekan Enter jika kosong)
4. Masukkan nama database (contoh: `myproject_db`)
5. Masukkan path lengkap file SQL Anda, contoh:
   ```
   C:\Users\Username\Downloads\database.sql
   ```
6. Tekan Y untuk konfirmasi
7. Tunggu proses selesai

### Opsi 2: Buat Database Baru + Import

1. Pastikan XAMPP MySQL sudah running
2. Double-click file `create_and_import.bat`
3. **Masukkan password MySQL** (tekan Enter jika kosong)
4. Masukkan nama database baru (contoh: `myproject_db`)
5. Script akan otomatis membuat database dengan charset UTF-8
6. Masukkan path file SQL
7. Tunggu proses selesai

## Troubleshooting

### ⚠️ Error: "Unknown command '\-'."

**Penyebab Umum:**
- File SQL mengandung BOM (Byte Order Mark)
- Encoding file tidak sesuai (UTF-16, ANSI, dll.)
- Karakter khusus di awal file

**Solusi Otomatis:**
Script sudah dilengkapi dengan flag `--default-character-set=utf8` dan `--force` untuk menangani masalah ini.

**Solusi Manual jika masih error:**
1. Buka file SQL dengan **Notepad++**
2. Menu **Encoding** → **Convert to UTF-8 (without BOM)**
3. **Save** file dan jalankan script lagi
4. Atau gunakan phpMyAdmin sebagai alternatif

### Error: Access Denied

**Solusi Baru:**
Script sekarang otomatis menanyakan password MySQL. Masukkan password atau tekan Enter jika kosong.

**Manual Override (jika diperlukan):**
Edit file .bat, ubah baris:
```batch
set DB_USER=root
```
Menjadi:
```batch
set DB_USER=root
set DB_PASS=password_anda
```

### Error: File Not Found

- Pastikan path file SQL benar dan lengkap
- Gunakan backslash `\` untuk Windows path
- **Contoh path yang benar:** `C:\Users\Mecloud\Downloads\my.sql`
- Script akan menampilkan ukuran file untuk validasi

### Error: Encoding/Character Issues

**Script sudah dilengkapi dengan:**
- `--default-character-set=utf8` untuk handling charset
- `--force` flag untuk melanjutkan meski ada warning minor
- Deteksi dan tips otomatis untuk file bermasalah

### Import Sangat Lambat

- Normal untuk file besar (50MB+ bisa 2-5 menit)
- Jangan tutup command prompt selama proses berjalan
- Script menampilkan timestamp untuk tracking waktu

### Error: Packet Too Large

- Edit `C:\xampp\mysql\bin\my.ini`
- Tambahkan di bawah `[mysqld]`:
  ```ini
  max_allowed_packet=128M
  innodb_buffer_pool_size=256M
  ```
- Restart MySQL di XAMPP Control Panel

## Tips Penggunaan

- ✅ Script ini **tidak memerlukan** konfigurasi khusus
- ✅ Cocok untuk database ukuran **100MB+** dengan encoding handling
- ✅ Import via command line **lebih cepat** dari phpMyAdmin
- ✅ **Auto-fix** untuk masalah encoding umum
- ✅ Bisa digunakan untuk **semua project** XAMPP Anda
- ✅ **Password support** untuk MySQL yang terproteksi
- ✅ **Detailed error messages** dengan solusi spesifik

## Alternatif Jika Script Gagal

### Via phpMyAdmin (Backup Plan):
1. Buka `http://localhost/phpmyadmin`
2. Buat/pilih database
3. Tab **Import** → **Choose file**
4. Select SQL file → **Execute**

### Via MySQL Command Line:
```cmd
cd C:\xampp\mysql\bin
mysql -u root -p --default-character-set=utf8 database_name < "C:\path\to\file.sql"
```

## Lokasi Script

```
C:\xampp\htdocs\import-db\
├── import_database.bat
├── create_and_import.bat
└── README.md
```

## Contoh Penggunaan

**Untuk project baru:**
- Database: `myproject_db` 
- SQL File: `C:\Users\Mecloud\Downloads\my.sql`
- Password: (kosong atau sesuai setting MySQL Anda)

**Contoh Path yang Didukung:**
```
C:\Users\Username\Downloads\database.sql
C:\backup\myproject.sql
D:\data\export.sql
C:\xampp\htdocs\import-db\sample.sql
```

## Changelog

**v2.0 (2026-07-11)**
- ➕ Fix untuk error "Unknown command '\-'."
- ➕ Auto-handling UTF-8 encoding
- ➕ Support password MySQL
- ➕ Enhanced error messages dengan solusi
- ➕ File validation dan tips encoding
- ➕ Timestamp untuk tracking import

**v1.0 (2026-06-23)**
- ✅ Basic import functionality
- ✅ Create database + import
- ✅ Simple error handling

---

**Created:** 2026-06-23  
**Updated:** 2026-07-11  
**Location:** C:\xampp\htdocs\import-db\

**Tested with:** XAMPP 8.2.x, MySQL/MariaDB, File size up to 500MB
