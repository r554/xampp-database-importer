@echo off
echo ========================================
echo XAMPP Database Import Script
echo ========================================
echo.

REM Set MySQL binary path
set MYSQL_BIN=C:\xampp\mysql\bin\mysql.exe

REM Set database credentials
set DB_USER=root

REM Prompt for database name
echo Masukkan nama database yang akan diimport
set /p DB_NAME="Nama Database: "

REM Prompt for SQL file path
echo.
echo Masukkan path lengkap file SQL Anda
echo Contoh: C:\backup\database.sql
echo.
set /p SQL_FILE="Path file SQL: "

REM Check if file exists
if not exist "%SQL_FILE%" (
    echo.
    echo ERROR: File tidak ditemukan!
    echo Path: %SQL_FILE%
    echo.
    pause
    exit /b 1
)

REM Display file info
echo.
echo File ditemukan: %SQL_FILE%
for %%A in ("%SQL_FILE%") do echo Ukuran: %%~zA bytes
echo.

REM Confirm import
echo Database target: %DB_NAME%
echo User: %DB_USER%
echo.
set /p CONFIRM="Lanjutkan import? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo Import dibatalkan.
    pause
    exit /b 0
)

REM Start import
echo.
echo Memulai import database...
echo Mohon tunggu, proses mungkin memakan waktu beberapa menit...
echo.

"%MYSQL_BIN%" -u %DB_USER% %DB_NAME% < "%SQL_FILE%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo SUCCESS! Database berhasil diimport
    echo ========================================
    echo Database: %DB_NAME%
    echo.
) else (
    echo.
    echo ========================================
    echo ERROR! Import database gagal
    echo ========================================
    echo Silakan cek error message di atas
    echo.
)

pause
