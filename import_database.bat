@echo off
echo ========================================
echo XAMPP Database Import Script
echo ========================================
echo.

REM Set MySQL binary path
set MYSQL_BIN=C:\xampp\mysql\bin\mysql.exe

REM Set database credentials
set DB_USER=root
set /p DB_PASS="Password MySQL (kosong jika tidak ada): "

REM Prompt for database name
echo Masukkan nama database yang akan diimport
set /p DB_NAME="Nama Database: "

REM Prompt for SQL file path
echo.
echo Masukkan path lengkap file SQL Anda
echo Contoh: C:\backup\database.sql
echo PENTING: Pastikan file SQL tidak mengandung BOM atau karakter khusus
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

REM Display file info and encoding tips
echo.
echo File ditemukan: %SQL_FILE%
for %%A in ("%SQL_FILE%") do echo Ukuran: %%~zA bytes
echo.
echo Memeriksa file SQL...
echo TIPS: Jika terjadi error "Unknown command '\-'.", 
echo buka file SQL dengan Notepad++ dan save ulang 
echo dengan encoding UTF-8 (tanpa BOM)
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
echo Memulai import dengan opsi khusus untuk mengatasi error encoding...
echo Mohon tunggu, proses mungkin memakan waktu beberapa menit...
echo.

if "%DB_PASS%"=="" (
    "%MYSQL_BIN%" -u %DB_USER% --default-character-set=utf8 --force %DB_NAME% < "%SQL_FILE%"
) else (
    "%MYSQL_BIN%" -u %DB_USER% -p%DB_PASS% --default-character-set=utf8 --force %DB_NAME% < "%SQL_FILE%"
)

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo SUCCESS! Database berhasil diimport
    echo ========================================
    echo Database: %DB_NAME%
    echo Waktu selesai: %DATE% %TIME%
    echo.
) else (
    echo.
    echo ========================================
    echo ERROR! Import database gagal
    echo ========================================
    echo.
    echo Kemungkinan penyebab error "Unknown command '\-'.":
    echo 1. File SQL mengandung BOM atau encoding yang salah
    echo 2. Karakter khusus atau path dengan spasi bermasalah
    echo 3. Syntax SQL tidak kompatibel dengan versi MySQL
    echo 4. File rusak atau tidak lengkap
    echo.
    echo SOLUSI YANG BISA DICOBA:
    echo.
    echo A. Fix Encoding:
    echo    1. Buka file SQL dengan Notepad++
    echo    2. Menu Encoding ^> Convert to UTF-8 ^(without BOM^)
    echo    3. Save file dan jalankan script lagi
    echo.
    echo B. Alternatif via phpMyAdmin:
    echo    1. Buka http://localhost/phpmyadmin
    echo    2. Pilih database %DB_NAME%
    echo    3. Tab Import ^> Choose file ^> Execute
    echo.
    echo C. Manual MySQL Command:
    echo    mysql -u %DB_USER% --default-character-set=utf8 %DB_NAME% ^< "path\to\file.sql"
    echo.
)

pause
