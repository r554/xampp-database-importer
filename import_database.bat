@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
title XAMPP Database Import Script

echo ========================================
echo XAMPP Database Import Script  (v3.0)
echo ========================================
echo.

REM ---------------------------------------------------------------
REM  SETUP
REM ---------------------------------------------------------------
set "MYSQL_BIN=C:\xampp\mysql\bin\mysql.exe"
set "TMPDIR=%TEMP%\importdb_%RANDOM%%RANDOM%"

if not exist "%MYSQL_BIN%" (
    echo ERROR: mysql.exe tidak ditemukan di:
    echo   %MYSQL_BIN%
    echo Pastikan XAMPP terinstall dan path sudah benar.
    pause
    exit /b 1
)

REM ---------------------------------------------------------------
REM  STEP 1 - Credentials
REM ---------------------------------------------------------------
set "DB_USER=root"
set /p "DB_PASS=Password MySQL (kosong jika tidak ada): "

REM ---------------------------------------------------------------
REM  STEP 2 - Database name
REM ---------------------------------------------------------------
echo.
set /p "DB_NAME=Nama Database target: "
if not defined DB_NAME (
    echo ERROR: Nama database tidak boleh kosong.
    pause
    exit /b 1
)
if "!DB_NAME!"=="" (
    echo ERROR: Nama database tidak boleh kosong.
    pause
    exit /b 1
)

REM ---------------------------------------------------------------
REM  STEP 3 - SQL file path
REM ---------------------------------------------------------------
echo.
echo Masukkan path lengkap file SQL Anda.
echo   Contoh: C:\backup\database.sql
echo   Boleh juga file .gz (hasil backup otomatis / cron)
echo.
set /p "SQL_INPUT=Path file SQL: "

REM Hilangkan tanda kutip jika user menempelkan path dengan quote
if not defined SQL_INPUT (
    echo ERROR: Path file tidak boleh kosong.
    pause
    exit /b 1
)

set "SQL_INPUT=!SQL_INPUT:"=!"

if not exist "!SQL_INPUT!" (
    echo.
    echo ERROR: Path tidak ditemukan!
    echo   !SQL_INPUT!
    pause
    exit /b 1
)

REM ---------------------------------------------------------------
REM  STEP 4 - Normalisasi input: folder / gz / sql
REM ---------------------------------------------------------------
set "SQL_FILE="

REM --- Case A: user memberi sebuah FOLDER ---
if exist "!SQL_INPUT!\" (
    echo.
    echo Terdeteksi FOLDER, mencari file .sql di dalamnya...
    for /f "delims=" %%F in ('dir /b /a-d /o-d "!SQL_INPUT!\*.sql" 2^>nul') do (
        if not defined SQL_FILE set "SQL_FILE=!SQL_INPUT!\%%F"
    )
    if not defined SQL_FILE (
        for /f "delims=" %%F in ('dir /b /a-d /o-d "!SQL_INPUT!\*.gz" 2^>nul') do (
            if not defined SQL_FILE set "SQL_FILE=!SQL_INPUT!\%%F"
        )
    )
    if not defined SQL_FILE (
        echo ERROR: Tidak ada file .sql atau .gz di dalam folder tersebut.
        pause
        exit /b 1
    )
    echo   Ditemukan: !SQL_FILE!
    goto :normalized
)

REM --- Case B: file .sql.gz  -^> decompress dulu ---
echo "!SQL_INPUT!" | findstr /i /e ".gz" >nul
if !ERRORLEVEL! EQU 0 (
    echo.
    echo Terdeteksi file GZIP, mengekstrak...
    if not exist "!TMPDIR!" mkdir "!TMPDIR!"
    tar -xzf "!SQL_INPUT!" -C "!TMPDIR!"
    if !ERRORLEVEL! NEQ 0 (
        echo ERROR: Gagal mengekstrak GZIP. Gunakan 7-Zip atau Git Bash.
        pause
        exit /b 1
    )
    for /f "delims=" %%F in ('dir /b /a-d /o-d "!TMPDIR!\*.sql" 2^>nul') do (
        if not defined SQL_FILE set "SQL_FILE=!TMPDIR!\%%F"
    )
    if not defined SQL_FILE (
        echo ERROR: Hasil ekstraksi tidak berisi file .sql
        pause
        exit /b 1
    )
    echo   Hasil ekstrak: !SQL_FILE!
    goto :normalized
)

REM --- Case C: file .sql biasa ---
set "SQL_FILE=!SQL_INPUT!"

:normalized

REM ---------------------------------------------------------------
REM  STEP 5 - Sanitize SQL: buang BOM, CRLF, dan TAB
REM           (TAB = penyebab "Unknown command" / dump ter-skip
REM            secara diam-diam oleh mysql client)
REM ---------------------------------------------------------------
echo.
echo Membersihkan file SQL (BOM / CRLF / TAB)...
if not exist "!TMPDIR!" mkdir "!TMPDIR!"
set "CLEAN_FILE=!TMPDIR!\clean.sql"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$in='!SQL_FILE!'; $out='!CLEAN_FILE!'; $sw=New-Object System.IO.StreamWriter($out,$false,(New-Object System.Text.UTF8Encoding($false))); $sr=New-Object System.IO.StreamReader($in,(New-Object System.Text.UTF8Encoding($false)),$true); while(($l=$sr.ReadLine()) -ne $null){ $sw.Write($l.Replace([char]9,' ')); $sw.Write([char]10) }; $sr.Close(); $sw.Close(); Write-Host '  OK - file dibersihkan'"

if not exist "!CLEAN_FILE!" (
    echo ERROR: Gagal membersihkan file SQL.
    pause
    exit /b 1
)
for %%A in ("!CLEAN_FILE!") do echo   Ukuran bersih: %%~zA bytes

REM ---------------------------------------------------------------
REM  STEP 6 - Verify SQL integrity (scan cepat)
REM ---------------------------------------------------------------
echo.
echo Memverifikasi file SQL...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=Get-Content -LiteralPath '!CLEAN_FILE!' -TotalCount 5000; $c=($t | Select-String -SimpleMatch 'CREATE TABLE').Count; $i=($t | Select-String -SimpleMatch 'INSERT INTO').Count; Write-Host ('  CREATE TABLE: '+$c); Write-Host ('  INSERT INTO : '+$i); if($c -eq 0){ Write-Host '  PERINGATAN: Tidak ada CREATE TABLE di 5000 baris pertama!' }"

REM ---------------------------------------------------------------
REM  STEP 7 - Create database if missing
REM ---------------------------------------------------------------
echo.
echo Membuat database [!DB_NAME!] bila belum ada...
if "!DB_PASS!"=="" (
    "%MYSQL_BIN%" -u !DB_USER! -e "CREATE DATABASE IF NOT EXISTS `!DB_NAME!` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
) else (
    "%MYSQL_BIN%" -u !DB_USER! -p!DB_PASS! -e "CREATE DATABASE IF NOT EXISTS `!DB_NAME!` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
)
if !ERRORLEVEL! NEQ 0 (
    echo ERROR: Gagal membuat/mengakses database. Cek user ^& password.
    pause
    exit /b 1
)

REM ---------------------------------------------------------------
REM  STEP 8 - Import
REM  CATATAN: TIDAK memakai --force supaya error TERLIHAT!
REM ---------------------------------------------------------------
echo.
echo ========================================
echo Mengimpor ke [!DB_NAME!]...
echo Mohon tunggu (file besar bisa beberapa menit).
echo ========================================
echo.

if "!DB_PASS!"=="" (
    "%MYSQL_BIN%" -u !DB_USER! --default-character-set=utf8mb4 !DB_NAME! < "!CLEAN_FILE!"
) else (
    "%MYSQL_BIN%" -u !DB_USER! -p!DB_PASS! --default-character-set=utf8mb4 !DB_NAME! < "!CLEAN_FILE!"
)

set "RC=!ERRORLEVEL!"
echo.
if !RC! EQU 0 (
    echo ========================================
    echo SUCCESS! Import selesai tanpa error.
    echo ========================================
    echo Database : !DB_NAME!
    echo Selesai  : !DATE! !TIME!
    echo.
    echo Memverifikasi jumlah tabel...
    if "!DB_PASS!"=="" (
        "%MYSQL_BIN%" -u !DB_USER! -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='!DB_NAME!';"
    ) else (
        "%MYSQL_BIN%" -u !DB_USER! -p!DB_PASS! -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='!DB_NAME!';"
    )
    echo ^(angka di atas = jumlah tabel di database !DB_NAME!^)
) else (
    echo ========================================
    echo ERROR! Import gagal (exit code !RC!)
    echo ========================================
    echo Lihat pesan error MySQL di atas untuk detailnya.
    echo.
    echo KEMUNGKINAN PENYEBAB:
    echo  1. max_allowed_packet terlalu kecil -^> edit C:\xampp\mysql\bin\my.ini
    echo     tambahkan di [mysqld]: max_allowed_packet=256M
    echo  2. Versi MySQL/MariaDB berbeda -^> jalankan:
    echo     C:\xampp\mysql\bin\mysql_upgrade -u root -p
    echo  3. Syntax khusus MySQL 8 yang tidak dikenal MariaDB 10.4
    echo     ^(mis. utf8mb4_0900_ai_ci, kolom generated, tipe JSON^)
)

if exist "!TMPDIR!" rd /s /q "!TMPDIR!" 2>nul

echo.
echo ========================================
echo Tekan sembarang tombol untuk keluar...
echo ========================================
pause >nul
endlocal
