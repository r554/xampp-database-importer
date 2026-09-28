# Panduan Import Database SQL Server

Script batch untuk import database ke SQL Server — mendukung koneksi **lokal maupun remote server**.

## File yang Tersedia

| File | Fungsi |
|------|--------|
| `sqlserver_import.bat` | Import ke database yang sudah ada |
| `sqlserver_create_and_import.bat` | Buat database baru + import sekaligus |

---

## Prasyarat

### 1. sqlcmd harus terinstall
Script menggunakan `sqlcmd` sebagai tools koneksi ke SQL Server. Biasanya sudah tersedia jika SQL Server sudah terinstall.

Jika belum ada, download di:
- **sqlcmd utility:** https://learn.microsoft.com/en-us/sql/tools/sqlcmd-utility
- **ODBC Driver:** https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server

Cek apakah sudah terinstall:
```cmd
sqlcmd -?
```

### 2. SQL Server service berjalan
Pastikan service SQL Server dalam kondisi **Running**:
- Buka `services.msc`
- Cari **SQL Server (MSSQLSERVER)** atau **SQL Server (SQLEXPRESS)**
- Pastikan statusnya **Running**

### 3. Koneksi remote (jika import ke server)
Jika tujuan import adalah server remote (VPS, LAN, cloud):
- Port **1433** harus terbuka di firewall server
- SQL Server harus dikonfigurasi untuk menerima remote connection:
  - Buka **SQL Server Configuration Manager**
  - Protocols for MSSQLSERVER → **TCP/IP** → Enable
  - Restart SQL Server service

---

## Cara Menggunakan

### Opsi 1: Import ke Database yang Sudah Ada

1. Pastikan SQL Server service berjalan
2. Double-click `sqlserver_import.bat`
3. Pilih metode autentikasi:
   - `1` → Windows Authentication
   - `2` → SQL Server Authentication (username + password)
4. Masukkan nama atau alamat server
5. Masukkan nama database target
6. Masukkan path lengkap file SQL
7. Pilih apakah perlu buat database baru (`Y/N`)
8. Konfirmasi dengan `Y` untuk mulai import

### Opsi 2: Buat Database Baru + Import

1. Pastikan SQL Server service berjalan
2. Double-click `sqlserver_create_and_import.bat`
3. Pilih metode autentikasi
4. Masukkan nama atau alamat server
5. Masukkan nama database baru
6. Masukkan collation (atau Enter untuk default)
7. Masukkan path lengkap file SQL
8. Konfirmasi dengan `Y` untuk mulai

---

## Format Nama Server

Sesuaikan format nama server dengan kebutuhan:

| Skenario | Format | Contoh |
|----------|--------|--------|
| Lokal default instance | `localhost` | `localhost` |
| Lokal named instance | `.\NAMA_INSTANCE` | `.\SQLEXPRESS` |
| LAN / IP lokal | `192.168.x.x` | `192.168.1.100` |
| LAN + named instance | `192.168.x.x\INSTANCE` | `192.168.1.100\SQLEXPRESS` |
| Remote / VPS (IP publik) | `IP_PUBLIK` | `103.x.x.x` |
| Remote + port custom | `IP,PORT` | `103.x.x.x,1433` |
| Domain server | `nama.domain.com` | `db.perusahaan.com` |

---

## Metode Autentikasi

### Windows Authentication (Opsi 1)
- Tidak memerlukan username dan password
- Menggunakan akun Windows yang sedang login
- Cocok untuk koneksi ke SQL Server lokal atau domain yang sama
- sqlcmd menggunakan flag `-E`

### SQL Server Authentication (Opsi 2)
- Memerlukan username dan password SQL Server
- Cocok untuk koneksi ke remote server atau VPS
- Username umum: `sa` (System Administrator)
- sqlcmd menggunakan flag `-U` dan `-P`

---

## Contoh Skenario

### Lokal (PC sendiri)
```
Pilih autentikasi : 1 (Windows Auth)
Nama Server       : localhost
Nama Database     : myapp_db
Path file SQL     : C:\Users\Mecloud\Downloads\database.sql
```

### Server LAN / Jaringan Kantor
```
Pilih autentikasi : 2 (SQL Auth)
Nama Server       : 192.168.1.100
Username          : sa
Password          : ********
Nama Database     : myapp_db
Path file SQL     : C:\Users\Mecloud\Downloads\database.sql
```

### VPS / Remote Server
```
Pilih autentikasi : 2 (SQL Auth)
Nama Server       : 103.x.x.x,1433
Username          : sa
Password          : ********
Nama Database     : myapp_db
Path file SQL     : C:\Users\Mecloud\Downloads\database.sql
```

---

## Troubleshooting

### ERROR: sqlcmd tidak ditemukan
**Penyebab:** SQL Server Tools belum terinstall

**Solusi:**
1. Download dan install sqlcmd dari:
   https://learn.microsoft.com/en-us/sql/tools/sqlcmd-utility
2. Restart Command Prompt setelah install
3. Jalankan script kembali

---

### ERROR: Koneksi gagal / Login failed
**Penyebab:** Server tidak bisa dijangkau atau kredensial salah

**Solusi:**
1. Pastikan SQL Server service berjalan (`services.msc`)
2. Cek nama server dan port sudah benar
3. Untuk remote: pastikan port 1433 terbuka di firewall
4. Untuk SQL Auth: cek username dan password
5. Untuk Windows Auth: pastikan user Windows punya akses ke SQL Server

---

### ERROR: Database tidak ada
**Penyebab:** Database target belum dibuat

**Solusi:**
- Pada `sqlserver_import.bat`: jawab `Y` saat ditanya "Buat database baru?"
- Gunakan `sqlserver_create_and_import.bat` yang otomatis membuat database

---

### ERROR: Permission denied / Insufficient privilege
**Penyebab:** User tidak punya hak akses yang cukup

**Solusi:**
1. Login menggunakan user `sa` atau user dengan role `sysadmin`
2. Atau minta DBA untuk memberikan permission `dbcreator` dan `db_owner`

---

### ERROR: Syntax error / File tidak kompatibel
**Penyebab:** File SQL dibuat dari versi SQL Server yang berbeda atau mengandung syntax tidak didukung

**Solusi:**
1. Buka file SQL di **SSMS (SQL Server Management Studio)**:
   - File → Open → pilih file `.sql`
   - Tekan `F5` untuk eksekusi
2. Periksa error message yang muncul di SSMS untuk detail lebih lanjut
3. Pastikan versi SQL Server kompatibel dengan file SQL

---

### Import Sangat Lambat
- Normal untuk file besar (100MB+ bisa 5-15 menit)
- Jangan tutup Command Prompt selama proses berjalan
- Script menampilkan timestamp saat selesai untuk tracking waktu

---

## Koneksi ke Cloud SQL Server

### Azure SQL Database
Perlu tambahan parameter SSL. Jalankan manual via sqlcmd:
```cmd
sqlcmd -S server.database.windows.net -U username@server -P password -d database_name -i "C:\path\to\file.sql" -N -C
```

### AWS RDS SQL Server
```cmd
sqlcmd -S myinstance.xxxx.us-east-1.rds.amazonaws.com,1433 -U admin -P password -d database_name -i "C:\path\to\file.sql"
```

> Untuk Azure dan AWS, disarankan menggunakan SSMS atau Azure Data Studio untuk kemudahan koneksi.

---

## Struktur File

```
C:\xampp\htdocs\import-db\
├── sqlserver_import.bat              ← Import ke DB yang sudah ada
├── sqlserver_create_and_import.bat   ← Buat DB baru + import
├── SQLSERVER_README.md               ← Dokumentasi ini
├── import_database.bat               ← Import MySQL/MariaDB
├── create_and_import.bat             ← Buat DB MySQL + import
└── README.md                         ← Dokumentasi MySQL
```

---

## Changelog

**v1.0 (2026-07-17)**
- ✅ Support Windows Authentication dan SQL Server Authentication
- ✅ Support koneksi lokal dan remote server
- ✅ Auto-detect sqlcmd
- ✅ Opsi buat database baru otomatis
- ✅ Konfigurasi collation database
- ✅ Validasi file dan konfirmasi sebelum import
- ✅ Error handling lengkap dengan solusi spesifik
- ✅ Timestamp saat import selesai

---

**Dibuat:** 2026-07-17  
**Kompatibel dengan:** SQL Server 2012, 2014, 2016, 2017, 2019, 2022  
**Tools:** sqlcmd utility  
**OS:** Windows
