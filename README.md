# Panduan Import Database XAMPP

Script universal untuk import database MySQL/MariaDB di XAMPP dengan **penanganan khusus untuk error encoding dan karakter khusus**.

## File yang Tersedia

1. **import_database.bat** - Import ke database yang sudah ada
2. **create_and_import.bat** - Buat database baru + import sekaligus

---

## ⚠️ KASUS NYATA: Import "sukses" tapi 0 tabel (db_simsms)

**Keluhan:** File `db_simsms_2026-09-28_00-00-05.sql` diimport, tapi tidak ada tabel maupun value yang masuk. Muncul pesan error tentang `bon` / `bom`.

**Hasil investigasi (2026-09-28): 3 bug ditemukan, file SQL-nya SENDIRI VALID.**

### 🔴 Bug #1 — Nama folder = nama file (PENYEBAB UTAMA)

Backup dari cron Ubuntu menghasilkan **folder** dan **file** dengan nama identik:

```
C:\Users\Mecloud\Downloads\
├── db_simsms_2026-09-28_00-00-05.sql\        <-- ini FOLDER
│   └── db_simsms_2026-09-28_00-00-05.sql     <-- ini FILE asli (74 MB)
└── db_simsms_2026-09-28_00-00-05.sql.gz      <-- arsip gzip  (7 MB)
```

Saat Anda mengetik path folder, `mysql < folder` membaca **direktori**, bukan file isinya.
Windows membuat _named pipe_ → `mysql` gagal total tanpa pesan error yang jelas.

> **Solusi:** ketik path yang berakhir `.sql` **dua kali**, atau cukup berikan folder-nya —
> script v3.0 sudah otomatis mencari file `.sql` / `.gz` di dalam folder.

### 🔴 Bug #2 — Karakter TAB di dalam file dump (PENYEBAB "0 tabel")

Baris 5 file SQL Anda berisi **karakter TAB**:

```
-- Server version	8.0.37-0ubuntu0.22.04.3
                  ^ karakter TAB, bukan spasi
```

File hanya berisi **1 TAB** (di baris 5), tapi fatal:

1. `mysql.exe` (client) membaca TAB sebagai pemisah perintah interaktif
2. Statement `-- Server version<TAB>8.0.37...` gagal diparse
3. Karena script memakai flag **`--force`**, error **diabaikan** dan `mysql` meneruskan
   sisa file ke mode yang salah → `CREATE TABLE` & `INSERT` tidak dieksekusi
4. Client mengeluarkan **ExitCode 0** → script melaporkan **"SUCCESS!"** padahal kosong

**Inilah penyebab "tidak ada tabel dan value yang terimport".**

### 🔴 Bug #3 — Flag `--force` menyembunyikan error

`--force` memaksa `mysql` lanjut walau ada error. Untuk import normal ini **berbahaya**
karena membuat kegagalan tak terlihat. Script v3.0 **tidak lagi memakai `--force`**.

### Panduan "error bon / bom"

Tidak ditemukan kata `bon` / `bom` di dalam file SQL (0 kemunculan), dan file **tidak punya BOM**
(byte awal = `2D 2D 20` = `"-- "`, benar).

Pesan yang Anda lihat adalah **salah satu dari ini**:

| Pesan yang muncul                                      | Arti sebenarnya                                                |
| ------------------------------------------------------ | -------------------------------------------------------------- |
| `ERROR at line 1: Unknown command '\-'`                | BOM / TAB di awal file · **Bug #2**                            |
| `Can't open file ... (Errcode: 21)` / `Is a directory` | Path menunjuk **folder** · **Bug #1**                          |
| error saat script menulis "Memeriksa file SQL..."      | output `dir \| find ".sql"` bocor · kosmetik                   |
| `bon` / `bom`                                          | kemungkinan salah baca pesan lain, atau error dari script lain |

### ✅ Bukti perbaikan

File asli diverifikasi dan diimport ke MariaDB XAMPP 10.4.32:

```
CREATE TABLE : 30        INSERT INTO : 91        DROP TABLE : 30
Header "MySQL dump" : 1  (bukan multi-dump)     BOM : tidak ada
TAB : hanya 1, di baris 5

Hasil import dengan script v3.0:
  ExitCode             : 0
  Jumlah tabel         : 30  ✅
  Data terbesar        : notifications 86.709 baris
                         inventaris    18.822 baris
                         log_callback  18.709 baris
  Sample users         : id=1 Superadmin admin@example.com
```

**Kesimpulan: file SQL Anda TIDAK rusak. Script lama yang bermasalah.**

---

**✨ Update Terbaru (2026-09-28) — v3.0:**

- ✅ **Auto-deteksi folder**: input folder → otomatis cari file `.sql` di dalamnya
- ✅ **Auto-ekstrak `.gz`**: backup cron berformat `.sql.gz` langsung didukung
- ✅ **Auto-sanitize**: buang BOM, konversi CRLF→LF, dan **ganti TAB→spasi**
- ✅ **Hapus `--force`**: error sekarang terlihat, bukan disembunyikan
- ✅ **Charset `utf8mb4`** (bukan `utf8`): sesuai dump MySQL 8 & emoji
- ✅ **Verifikasi otomatis**: hitung `CREATE TABLE` / `INSERT INTO` sebelum import
- ✅ **Verifikasi hasil**: tampilkan jumlah tabel setelah import
- ✅ Collation database `utf8mb4_unicode_ci`

**v2.0 (2026-07-11):**

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
5. Masukkan path file SQL — boleh **file** `.sql`, **file** `.sql.gz`, atau **folder**:
   ```
   C:\Users\Username\Downloads\database.sql
   ```
6. Tunggu proses selesai (script membersihkan file & memverifikasi hasilnya)

### Opsi 2: Buat Database Baru + Import

1. Pastikan XAMPP MySQL sudah running
2. Double-click file `create_and_import.bat`
3. **Masukkan password MySQL** (tekan Enter jika kosong)
4. Masukkan nama database baru (contoh: `myproject_db`)
5. Script akan otomatis membuat database dengan charset UTF-8
6. Masukkan path file SQL — boleh **file** `.sql`, **file** `.sql.gz`, atau **folder**
7. Tunggu proses selesai (script membersihkan file & memverifikasi hasilnya)

## Troubleshooting

### ⚠️ Import "berhasil" tapi tidak ada tabel

Ini adalah kasus db_simsms di atas. Penyebab & solusi:

1. **Path menunjuk folder, bukan file** → pastikan path berakhir `.sql`,
   ATAU berikan foldernya (v3.0 akan mencari otomatis)
2. **TAB di dalam file dump** → v3.0 otomatis menggantinya dengan spasi
3. Cek output baris `CREATE TABLE:` — kalau angkanya 0, file memang bukan dump tabel

### ⚠️ Error: "Unknown command '\-'."

**Penyebab Umum:**

- File SQL mengandung BOM (Byte Order Mark)
- Karakter TAB di dalam file
- Encoding file tidak sesuai (UTF-16, ANSI, dll.)

**Solusi Otomatis (v3.0):**
Script sudah membersihkan BOM, CRLF, dan TAB secara otomatis sebelum import.

**Solusi Manual jika masih error:**

1. Buka file SQL dengan **Notepad++**
2. Menu **Encoding** → **Convert to UTF-8 (without BOM)**
3. **Replace** → _Find what:_ `\t` · _Replace with:_ (spasi) · **Replace All** · mode **Extended**
4. **Save** file dan jalankan script lagi

### Error: Path adalah Folder

```
ERROR 2005: Can't open file '...' (Errcode: 21)
```

atau `Is a directory`. Path menunjuk folder hasil backup cron.
Gunakan path lengkap ke file `.sql` di dalamnya, atau serahkan foldernya ke script v3.0.

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

**Script v3.0 sudah dilengkapi dengan:**

- Auto-sanitize: buang BOM, CRLF → LF, TAB → spasi
- `--default-character-set=utf8mb4` untuk dump MySQL 8 / emoji
- Verifikasi `CREATE TABLE` / `INSERT INTO` sebelum eksekusi
- **Tanpa** `--force` supaya error asli terlihat

### Import Sangat Lambat

- Normal untuk file besar (50MB+ bisa 2-5 menit)
- Contoh nyata: db_simsms 71 MB ≈ 15 detik di SSD lokal
- Jangan tutup command prompt selama proses berjalan
- Script menampilkan timestamp untuk tracking waktu

### Error: Packet Too Large

- Edit `C:\xampp\mysql\bin\my.ini`
- Tambahkan di bawah `[mysqld]`:
  ```ini
  max_allowed_packet=256M
  innodb_buffer_pool_size=256M
  ```
- Restart MySQL di XAMPP Control Panel

## Tips Penggunaan

- ✅ Script ini **tidak memerlukan** konfigurasi khusus
- ✅ Cocok untuk database ukuran **500MB+** dengan encoding handling
- ✅ Import via command line **lebih cepat** dari phpMyAdmin
- ✅ **Auto-fix** BOM / CRLF / TAB
- ✅ Bisa digunakan untuk **semua project** XAMPP Anda
- ✅ **Password support** untuk MySQL yang terproteksi
- ✅ **Auto-deteksi** folder backup cron & file `.sql.gz`

## Alternatif Jika Script Gagal

### Via phpMyAdmin (Backup Plan):

1. Buka `http://localhost/phpmyadmin`
2. Buat/pilih database
3. Tab **Import** → **Choose file**
4. Select SQL file → **Execute**

> ⚠️ Catatan: phpMyAdmin punya batas upload (biasanya 2–40 MB).
> Untuk file 74 MB, edit `php.ini` → `upload_max_filesize=256M` dan `post_max_size=256M`.

### Via MySQL Command Line:

```cmd
cd C:\xampp\mysql\bin
mysql -u root -p --default-character-set=utf8mb4 database_name < "C:\path\to\file.sql"
```

### Jika path Anda berupa folder (kasus db_simsms):

```cmd
cd C:\xampp\mysql\bin
mysql -u root --default-character-set=utf8mb4 mydb < "C:\Users\Mecloud\Downloads\db_simsms_2026-09-28_00-00-05.sql\db_simsms_2026-09-28_00-00-05.sql"
```

Perhatikan nama `.sql` muncul **dua kali** — pertama folder, kedua file.

## Lokasi Script

```
C:\xampp\htdocs\import-db\
├── import_database.bat            (MySQL/MariaDB)
├── create_and_import.bat          (MySQL/MariaDB)
├── sqlserver_import.bat           (SQL Server)
├── sqlserver_create_and_import.bat(SQL Server)
├── README.md
└── SQLSERVER_README.md
```

## Contoh Penggunaan

**Untuk project baru:**

- Database: `myproject_db`
- SQL File: `C:\Users\Mecloud\Downloads\my.sql`
- Password: (kosong atau sesuai setting MySQL Anda)

**Contoh Path yang Didukung (v3.0):**

```
C:\Users\Username\Downloads\database.sql          <-- file langsung
C:\Users\Username\Downloads\backup.sql.gz         <-- auto-ekstrak
C:\backup\backup-2026-09-28.sql\                  <-- folder, auto-cari
C:\backup\backup-2026-09-28.sql\dump.sql          <-- file di dalam folder
D:\data\export.sql
```

## Changelog

**v3.0 (2026-09-28)**

- ➕ **Fix bug utama**: import "sukses" tapi 0 tabel (TAB + `--force`)
- ➕ Auto-deteksi input berupa **folder** (backup cron Ubuntu)
- ➕ Auto-ekstrak file **`.gz`**
- ➕ Auto-sanitize **BOM / CRLF / TAB** sebelum import
- ➕ **Hapus flag `--force`** agar error terlihat
- ➕ Charset **`utf8mb4`** + collation `utf8mb4_unicode_ci`
- ➕ Verifikasi pre-import (`CREATE TABLE` / `INSERT INTO`)
- ➕ Verifikasi post-import (jumlah tabel)
- ➕ Laporan error dengan panduan `max_allowed_packet` & `mysql_upgrade`

**v2.0 (2026-07-11)**

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
**Updated:** 2026-09-28  
**Location:** C:\xampp\htdocs\import-db\

**Tested with:** XAMPP 8.2.x / MariaDB 10.4.32, dump MySQL 8.0.37 (Ubuntu),
file size up to 500MB — terverifikasi import 71 MB → 30 tabel, 86.709 baris data.
