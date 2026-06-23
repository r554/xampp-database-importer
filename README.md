# Panduan Import Database XAMPP

Script universal untuk import database MySQL/MariaDB di XAMPP. Bisa digunakan untuk project apapun.

## File yang Tersedia

1. **import_database.bat** - Import ke database yang sudah ada
2. **create_and_import.bat** - Buat database baru + import sekaligus

## Cara Menggunakan

### Opsi 1: Import ke Database yang Sudah Ada

1. Pastikan XAMPP MySQL sudah running
2. Double-click file `import_database.bat`
3. Masukkan nama database (contoh: `myproject_db`)
4. Masukkan path lengkap file SQL Anda, contoh:
   ```
   C:\backup\database.sql
   ```
5. Tekan Y untuk konfirmasi
6. Tunggu proses selesai

### Opsi 2: Buat Database Baru + Import

1. Pastikan XAMPP MySQL sudah running
2. Double-click file `create_and_import.bat`
3. Masukkan nama database baru (contoh: `myproject_db`)
4. Script akan otomatis membuat database
5. Masukkan path file SQL
6. Tunggu proses selesai

## Troubleshooting

### Error: Access Denied

- Pastikan MySQL root tidak ada password
- Atau edit file .bat, ubah baris:
  ```batch
  set DB_USER=root
  ```
  Menjadi:
  ```batch
  set DB_USER=root -pPASSWORD_ANDA
  ```

### Error: File Not Found

- Pastikan path file SQL benar
- Gunakan backslash `\` bukan forward slash `/`
- Gunakan path absolut lengkap

### Import Sangat Lambat

- Normal untuk file besar (50MB+ bisa 2-5 menit)
- Jangan tutup command prompt selama proses berjalan

### Error: Packet Too Large

- Edit `C:\xampp\mysql\bin\my.ini`
- Tambahkan di bawah `[mysqld]`:
  ```ini
  max_allowed_packet=64M
  ```
- Restart MySQL di XAMPP Control Panel

## Tips Penggunaan

- Script ini **tidak memerlukan** konfigurasi khusus
- Cocok untuk database ukuran **50MB+**
- Import via command line **lebih cepat** dari phpMyAdmin
- Bisa digunakan untuk **semua project** XAMPP Anda

## Lokasi Script

```
C:\xampp\htdocs\import-db\
├── import_database.bat
├── create_and_import.bat
└── README.md
```

## Contoh Penggunaan

**Untuk project baru:**

- Database: `nama_db_anda`
- SQL File: `C:\path\to\your\database.sql`

---

Created: 2026-06-23  
Location: C:\xampp\htdocs\import-db\
