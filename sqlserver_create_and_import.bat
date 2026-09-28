@echo off
setlocal enabledelayedexpansion
echo ========================================
echo  SQL Server Create DB + Import Script
echo ========================================
echo.

REM ----------------------------------------
REM Cek apakah sqlcmd tersedia
REM ----------------------------------------
where sqlcmd >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: sqlcmd tidak ditemukan!
    echo.
    echo Pastikan SQL Server atau SQL Server Tools sudah terinstall.
    echo Download: https://learn.microsoft.com/en-us/sql/tools/sqlcmd-utility
    echo.
    pause
    exit /b 1
)

echo [OK] sqlcmd ditemukan
echo.

REM ----------------------------------------
REM Pilih metode autentikasi
REM ----------------------------------------
echo Pilih metode login:
echo   1. Windows Authentication (default, tidak perlu username/password)
echo   2. SQL Server Authentication (username + password)
echo.
set /p AUTH_MODE="Pilih (1 atau 2): "

if "%AUTH_MODE%"=="2" goto SQL_AUTH
goto WIN_AUTH

:WIN_AUTH
set USE_WIN_AUTH=true
echo.
echo Menggunakan Windows Authentication
set /p SQL_SERVER="Nama Server SQL (Enter untuk 'localhost'): "
if "%SQL_SERVER%"=="" set SQL_SERVER=localhost
goto GET_DB_INFO

:SQL_AUTH
set USE_WIN_AUTH=false
echo.
set /p SQL_SERVER="Nama Server SQL (Enter untuk 'localhost'): "
if "%SQL_SERVER%"=="" set SQL_SERVER=localhost
set /p SQL_USER="Username: "
set /p SQL_PASS="Password: "
echo.

:GET_DB_INFO
REM ----------------------------------------
REM Input nama database baru
REM ----------------------------------------
echo.
echo Step 1: Buat Database Baru
echo Masukkan nama database yang akan dibuat
set /p DB_NAME="Nama Database: "

if "%DB_NAME%"=="" (
    echo ERROR: Nama database tidak boleh kosong!
    pause
    exit /b 1
)

REM ----------------------------------------
REM Opsi konfigurasi database
REM ----------------------------------------
echo.
echo Konfigurasi database (tekan Enter untuk nilai default):
set /p DB_COLLATION="Collation (default: SQL_Latin1_General_CP1_CI_AS): "
if "%DB_COLLATION%"=="" set DB_COLLATION=SQL_Latin1_General_CP1_CI_AS

REM ----------------------------------------
REM Buat Database
REM ----------------------------------------
echo.
echo Membuat database [%DB_NAME%]...

if "%USE_WIN_AUTH%"=="true" (
    sqlcmd -S "%SQL_SERVER%" -E -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'%DB_NAME%') BEGIN CREATE DATABASE [%DB_NAME%] COLLATE %DB_COLLATION%; PRINT 'Database created'; END ELSE PRINT 'Database already exists';"
) else (
    sqlcmd -S "%SQL_SERVER%" -U "%SQL_USER%" -P "%SQL_PASS%" -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'%DB_NAME%') BEGIN CREATE DATABASE [%DB_NAME%] COLLATE %DB_COLLATION%; PRINT 'Database created'; END ELSE PRINT 'Database already exists';"
)

if !ERRORLEVEL! EQU 0 (
    echo [OK] Database %DB_NAME% siap digunakan
    echo.
) else (
    echo.
    echo ERROR: Gagal membuat database %DB_NAME%
    echo Periksa koneksi dan permission ke SQL Server
    pause
    exit /b 1
)

REM ----------------------------------------
REM Input path file SQL
REM ----------------------------------------
echo Step 2: Import File SQL
echo.
echo Masukkan path lengkap file SQL Anda
echo Contoh: C:\Users\Username\Downloads\database.sql
echo.
set /p SQL_FILE="Path file SQL: "

if not exist "%SQL_FILE%" (
    echo.
    echo ERROR: File tidak ditemukan!
    echo Path: %SQL_FILE%
    echo.
    pause
    exit /b 1
)

echo.
echo File ditemukan: %SQL_FILE%
for %%A in ("%SQL_FILE%") do echo Ukuran: %%~zA bytes
echo.

REM ----------------------------------------
REM Konfirmasi
REM ----------------------------------------
echo ========================================
echo Ringkasan:
echo   Server   : %SQL_SERVER%
if "%USE_WIN_AUTH%"=="true" (
    echo   Auth     : Windows Authentication
) else (
    echo   Auth     : SQL Server Authentication ^(%SQL_USER%^)
)
echo   Database : %DB_NAME%
echo   Collation: %DB_COLLATION%
echo   File     : %SQL_FILE%
echo ========================================
echo.
set /p CONFIRM="Lanjutkan import? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo Import dibatalkan.
    pause
    exit /b 0
)

REM ----------------------------------------
REM Mulai import
REM ----------------------------------------
echo.
echo Memulai import ke database %DB_NAME%...
echo Mohon tunggu, proses mungkin memakan waktu beberapa menit...
echo.

if "%USE_WIN_AUTH%"=="true" (
    sqlcmd -S "%SQL_SERVER%" -E -d "%DB_NAME%" -i "%SQL_FILE%" -b
) else (
    sqlcmd -S "%SQL_SERVER%" -U "%SQL_USER%" -P "%SQL_PASS%" -d "%DB_NAME%" -i "%SQL_FILE%" -b
)

REM ----------------------------------------
REM Hasil
REM ----------------------------------------
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo  SUCCESS!
    echo  Database berhasil dibuat dan diimport
    echo ========================================
    echo  Server  : %SQL_SERVER%
    echo  Database: %DB_NAME%
    echo  Waktu   : %DATE% %TIME%
    echo ========================================
    echo.
) else (
    echo.
    echo ========================================
    echo  ERROR! Import gagal
    echo ========================================
    echo.
    echo Kemungkinan penyebab:
    echo  1. SQL Server service tidak berjalan
    echo  2. Username atau password salah
    echo  3. User tidak punya permission
    echo  4. Syntax SQL tidak kompatibel
    echo.
    echo SOLUSI:
    echo  A. Cek SQL Server service:
    echo     Buka Services.msc ^> cari SQL Server ^> pastikan Running
    echo.
    echo  B. Coba via SSMS ^(SQL Server Management Studio^):
    echo     File ^> Open ^> "%SQL_FILE%"
    echo     Lalu tekan F5 untuk jalankan
    echo.
    echo  C. Cek log error di SQL Server:
    echo     SSMS ^> Management ^> SQL Server Logs
    echo.
)

pause
endlocal
