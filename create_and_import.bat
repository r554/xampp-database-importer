@echo off
echo ========================================
echo XAMPP Create Database + Import Script
echo ========================================
echo.

REM Set MySQL binary path
set MYSQL_BIN=C:\xampp\mysql\bin\mysql.exe

REM Set database credentials
set DB_USER=root

echo Step 1: Membuat database baru
echo.
echo Masukkan nama database yang akan dibuat
set /p DB_NAME="Nama Database: "

echo.
echo Membuat database %DB_NAME% (jika belum ada)...
"%MYSQL_BIN%" -u %DB_USER% -e "CREATE DATABASE IF NOT EXISTS %DB_NAME% CHARACTER SET utf8 COLLATE utf8_general_ci;"

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
echo.
set /p SQL_FILE="Path file SQL: "

if not exist "%SQL_FILE%" (
    echo.
    echo ERROR: File tidak ditemukan!
    pause
    exit /b 1
)

echo.
echo Memulai import ke database %DB_NAME%...
echo.

"%MYSQL_BIN%" -u %DB_USER% %DB_NAME% < "%SQL_FILE%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo SUCCESS! 
    echo Database berhasil dibuat dan diimport
    echo ========================================
    echo.
) else (
    echo.
    echo ERROR! Import gagal
    echo.
)

pause
