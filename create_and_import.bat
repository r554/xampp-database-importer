@echo off
echo ========================================
echo XAMPP Create Database + Import Script
echo ========================================
echo.

REM Set MySQL binary path
set MYSQL_BIN=C:\xampp\mysql\bin\mysql.exe

REM Set database credentials
set DB_USER=root
set /p DB_PASS="Password MySQL (kosong jika tidak ada): "

echo Step 1: Membuat database baru
echo.
echo Masukkan nama database yang akan dibuat
set /p DB_NAME="Nama Database: "

echo.
echo Membuat database %DB_NAME% (jika belum ada)...
if "%DB_PASS%"=="" (
    "%MYSQL_BIN%" -u %DB_USER% -e "CREATE DATABASE IF NOT EXISTS %DB_NAME% CHARACTER SET utf8 COLLATE utf8_general_ci;"
) else (
    "%MYSQL_BIN%" -u %DB_USER% -p%DB_PASS% -e "CREATE DATABASE IF NOT EXISTS %DB_NAME% CHARACTER SET utf8 COLLATE utf8_general_ci;"
)

if %ERRORLEVEL% EQU 0 (
    echo Database %DB_NAME% siap digunakan
    echo.
) else (
    echo ERROR: Gagal membuat database
    pause
    exit /b 1
)

echo Step 2: Import SQL file
echo.
echo Masukkan path lengkap file SQL Anda
echo Contoh: C:\backup\database.sql
echo PENTING: Pastikan file SQL tidak mengandung BOM atau karakter khusus
echo.
set /p SQL_FILE="Path file SQL: "

if not exist "%SQL_FILE%" (
    echo.
    echo ERROR: File tidak ditemukan!
    pause
    exit /b 1
)

echo.
echo Memeriksa file SQL...
echo File size: 
dir "%SQL_FILE%" | find /i ".sql"
echo.
echo TIPS: Jika tetap error, coba buka file SQL dengan Notepad++ 
echo dan save ulang dengan encoding UTF-8 (tanpa BOM)
echo.

echo.
echo Memulai import ke database %DB_NAME%...
echo.

echo Memulai import dengan opsi khusus untuk mengatasi error encoding...
if "%DB_PASS%"=="" (
    "%MYSQL_BIN%" -u %DB_USER% --default-character-set=utf8 --force %DB_NAME% < "%SQL_FILE%"
) else (
    "%MYSQL_BIN%" -u %DB_USER% -p%DB_PASS% --default-character-set=utf8 --force %DB_NAME% < "%SQL_FILE%"
)

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo SUCCESS! 
    echo Database berhasil dibuat dan diimport
    echo ========================================
    echo.
) else (
    echo.
    echo ========================================
    echo ERROR! Import gagal
    echo ========================================
    echo.
    echo Kemungkinan penyebab:
    echo 1. File SQL mengandung BOM atau encoding salah
    echo 2. Karakter khusus di path file
    echo 3. Syntax SQL tidak kompatibel
    echo.
    echo SOLUSI ALTERNATIF:
    echo 1. Buka file SQL dengan Notepad++
    echo 2. Menu Encoding ^> Convert to UTF-8 ^(without BOM^)
    echo 3. Save file dan coba lagi
    echo.
    echo ATAU gunakan phpMyAdmin:
    echo 1. Buka http://localhost/phpmyadmin
    echo 2. Pilih database %DB_NAME%
    echo 3. Tab Import ^> Choose file ^> Execute
    echo.
)

pause
