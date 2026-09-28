@echo off
setlocal enabledelayedexpansion
echo ========================================
echo    SQL Server Database Import Script
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
echo   1. Windows Authentication (default)
echo   2. SQL Server Authentication (username + password)
echo.
set /p AUTH_MODE="Pilih (1 atau 2): "

if "%AUTH_MODE%"=="2" goto SQL_AUTH
goto WIN_AUTH

:WIN_AUTH
set USE_WIN_AUTH=true
echo.
echo Menggunakan Windows Authentication
echo.

REM Pilih server
set /p SQL_SERVER="Nama Server SQL (contoh: localhost atau .\SQLEXPRESS): "
if "%SQL_SERVER%"=="" set SQL_SERVER=localhost
goto GET_DB_INFO

:SQL_AUTH
set USE_WIN_AUTH=false
echo.
set /p SQL_SERVER="Nama Server SQL (contoh: localhost atau .\SQLEXPRESS): "
if "%SQL_SERVER%"=="" set SQL_SERVER=localhost
set /p SQL_USER="Username SQL Server: "
set /p SQL_PASS="Password SQL Server: "
echo.

:GET_DB_INFO
REM ----------------------------------------
REM Input nama database
REM ----------------------------------------
echo Masukkan nama database target
set /p DB_NAME="Nama Database: "

if "%DB_NAME%"=="" (
    echo ERROR: Nama database tidak boleh kosong!
    pause
    exit /b 1
)

REM ----------------------------------------
REM Input path file SQL
REM ----------------------------------------
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

REM Tampilkan info file
echo.
echo File ditemukan: %SQL_FILE%
for %%A in ("%SQL_FILE%") do echo Ukuran: %%~zA bytes
echo.

REM ----------------------------------------
REM Pilih apakah database perlu dibuat dulu
REM ----------------------------------------
set /p CREATE_DB="Buat database baru jika belum ada? (Y/N): "

REM ----------------------------------------
REM Konfirmasi sebelum eksekusi
REM ----------------------------------------
echo.
echo ========================================
echo Ringkasan Import:
echo   Server  : %SQL_SERVER%
if "%USE_WIN_AUTH%"=="true" (
    echo   Auth    : Windows Authentication
) else (
    echo   Auth    : SQL Server Authentication
    echo   User    : %SQL_USER%
)
echo   Database: %DB_NAME%
echo   File    : %SQL_FILE%
echo ========================================
echo.
set /p CONFIRM="Lanjutkan? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo Import dibatalkan.
    pause
    exit /b 0
)

REM ----------------------------------------
REM Buat database jika diperlukan
REM ----------------------------------------
if /i "%CREATE_DB%"=="Y" (
    echo.
    echo Membuat database %DB_NAME% jika belum ada...

    if "%USE_WIN_AUTH%"=="true" (
        sqlcmd -S "%SQL_SERVER%" -E -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = '%DB_NAME%') CREATE DATABASE [%DB_NAME%]"
    ) else (
        sqlcmd -S "%SQL_SERVER%" -U "%SQL_USER%" -P "%SQL_PASS%" -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = '%DB_NAME%') CREATE DATABASE [%DB_NAME%]"
    )

    if !ERRORLEVEL! EQU 0 (
        echo [OK] Database %DB_NAME% siap
    ) else (
        echo ERROR: Gagal membuat database
        pause
        exit /b 1
    )
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
REM Cek hasil
REM ----------------------------------------
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo  SUCCESS! Database berhasil diimport
    echo ========================================
    echo  Server  : %SQL_SERVER%
    echo  Database: %DB_NAME%
    echo  Waktu   : %DATE% %TIME%
    echo ========================================
    echo.
) else (
    echo.
    echo ========================================
    echo  ERROR! Import database gagal
    echo ========================================
    echo.
    echo Kemungkinan penyebab:
    echo  1. Koneksi ke SQL Server gagal
    echo  2. User tidak punya permission yang cukup
    echo  3. Database tidak ada ^(pilih Y untuk buat database^)
    echo  4. File SQL mengandung syntax yang tidak kompatibel
    echo  5. File SQL dibuat dari versi SQL Server berbeda
    echo.
    echo SOLUSI:
    echo  A. Pastikan SQL Server service sedang berjalan
    echo     - Buka Services.msc
    echo     - Cari SQL Server ^(MSSQLSERVER atau SQLEXPRESS^)
    echo     - Pastikan status Running
    echo.
    echo  B. Untuk Windows Auth, pastikan user Windows punya akses
    echo.
    echo  C. Untuk SQL Auth, cek username dan password
    echo.
    echo  D. Coba jalankan file SQL via SQL Server Management Studio ^(SSMS^)
    echo.
)

pause
endlocal
