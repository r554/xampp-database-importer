@echo off
setlocal EnableDelayedExpansion
title XAMPP Drop Database Script

REM ===============================================================
REM  XAMPP Drop Database Script (v1.4)
REM  Input nomor / nama database + konfirmasi + proteksi sistem.
REM  - Argumen %1 (opsional) = password MySQL ("-" = kosong).
REM  - Mode uji non-interaktif: set DROPTEST=1,
REM    DROPTEST_CHOICE=<nomor/nama>, DROPTEST_CONFIRM=Y/N.
REM ===============================================================

set "MYSQL_BIN=C:\xampp\mysql\bin\mysql.exe"
set "LISTFILE=%TEMP%\xampp_dblist.txt"

echo ========================================
echo XAMPP Drop Database Script (v1.4)
echo ========================================
echo.

if not exist "%MYSQL_BIN%" (
    echo ERROR: mysql.exe tidak ditemukan di:
    echo   %MYSQL_BIN%
    echo Pastikan XAMPP terinstall dan path sudah benar.
    echo.
    call :pauseit
    exit /b 1
)

REM ---------------------------------------------------------------
REM  STEP 1 - Password MySQL
REM  Argumen %1 (opsional) = password, untuk mode non-interaktif.
REM ---------------------------------------------------------------
set "DB_PASS="
if not "%~1"=="" (
    set "DB_PASS=%~1"
    if "!DB_PASS!"=="-" set "DB_PASS="
) else (
    set /p "DB_PASS=Password MySQL (kosong jika tidak ada): "
    call :trim DB_PASS
)
set "MYSQL_AUTH=-u root"
if not "!DB_PASS!"=="" set "MYSQL_AUTH=-u root -p!DB_PASS!"

REM ---------------------------------------------------------------
REM  STEP 2 - Ambil daftar database ke file
REM ---------------------------------------------------------------
echo.
echo Mengambil daftar database...
echo -------------------------------------------------------

"%MYSQL_BIN%" !MYSQL_AUTH! -N -B -e "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('information_schema','mysql','performance_schema','sys') ORDER BY schema_name;" > "%LISTFILE%" 2>nul

set /a TOTAL=0
for /f "delims=" %%A in ('type "%LISTFILE%"') do (
    set /a TOTAL+=1
    echo   [!TOTAL!] %%A
)

if "!TOTAL!"=="0" goto :emptylist

echo -------------------------------------------------------
echo Total database: !TOTAL!
echo.

REM ---------------------------------------------------------------
REM  STEP 3 - Input pilihan (nomor atau nama)
REM ---------------------------------------------------------------
echo Pilih database yang ingin di-DROP:
echo   - Ketik NOMOR, contoh:  5
echo   - Ketik NAMA,  contoh:  db_simsms
echo   - Ketik 0 untuk batal
echo.
set "USER_CHOICE="
if defined DROPTEST_CHOICE (
    set "USER_CHOICE=!DROPTEST_CHOICE!"
) else (
    set /p "USER_CHOICE=Pilihan Anda: "
    call :trim USER_CHOICE
)

if "!USER_CHOICE!"=="" goto :cancelled
if "!USER_CHOICE!"=="0" goto :cancelled

set "TARGET_DB="

REM --- Deteksi angka murni: jika ada karakter selain 0-9, bukan angka ---
set "IS_NUMBER=Y"
for /f "delims=0123456789" %%X in ("!USER_CHOICE!") do set "IS_NUMBER=N"

if "!IS_NUMBER!"=="Y" (
    set /a LINE_NO=USER_CHOICE
    set /a C=0
    for /f "delims=" %%L in ('type "%LISTFILE%"') do (
        set /a C+=1
        if !C! EQU !LINE_NO! set "TARGET_DB=%%L"
    )
) else (
    set "TARGET_DB=!USER_CHOICE!"
)

if "!TARGET_DB!"=="" (
    echo.
    echo ERROR: Pilihan [!USER_CHOICE!] tidak valid / nomor di luar rentang.
    del "%LISTFILE%" 2>nul
    echo.
    call :pauseit
    exit /b 1
)

REM ---------------------------------------------------------------
REM  STEP 4 - Proteksi database sistem
REM ---------------------------------------------------------------
if /i "!TARGET_DB!"=="information_schema" goto :protected
if /i "!TARGET_DB!"=="mysql" goto :protected
if /i "!TARGET_DB!"=="performance_schema" goto :protected
if /i "!TARGET_DB!"=="sys" goto :protected

REM ---------------------------------------------------------------
REM  STEP 5 - Verifikasi target ada di daftar
REM ---------------------------------------------------------------
findstr /x /i /c:"!TARGET_DB!" "%LISTFILE%" >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo.
    echo ERROR: Database [!TARGET_DB!] tidak ditemukan!
    del "%LISTFILE%" 2>nul
    echo.
    call :pauseit
    exit /b 1
)
del "%LISTFILE%" 2>nul

REM ---------------------------------------------------------------
REM  STEP 6 - Konfirmasi
REM ---------------------------------------------------------------
echo.
echo ========================================================
echo PERINGATAN: data di dalamnya akan HILANG PERMANEN!
echo Database target: !TARGET_DB!
echo ========================================================
echo.
set "CONFIRM="
if defined DROPTEST_CONFIRM (
    set "CONFIRM=!DROPTEST_CONFIRM!"
) else (
    set /p "CONFIRM=Ketik Y lalu Enter untuk lanjut: "
    call :trim CONFIRM
)

if /i not "!CONFIRM!"=="Y" (
    echo.
    echo DIBATALKAN.
    echo.
    call :pauseit
    exit /b 0
)

REM ---------------------------------------------------------------
REM  STEP 7 - Drop
REM ---------------------------------------------------------------
echo.
echo Menghapus database [!TARGET_DB!]...

"%MYSQL_BIN%" !MYSQL_AUTH! -e "DROP DATABASE `!TARGET_DB!`;"

if !ERRORLEVEL! EQU 0 (
    echo.
    echo ========================================================
    echo SUKSES^^! Database [!TARGET_DB!] sudah dihapus.
    echo ========================================================
) else (
    echo.
    echo ========================================================
    echo GAGAL menghapus database [!TARGET_DB!].
    echo ========================================================
)

echo.
call :pauseit
exit /b 0

REM ---------------------------------------------------------------
:cancelled
echo.
echo Dibatalkan.
del "%LISTFILE%" 2>nul
echo.
call :pauseit
exit /b 0

REM ---------------------------------------------------------------
:emptylist
echo   (Tidak ada database ditemukan, atau gagal koneksi ke MySQL)
echo -------------------------------------------------------
del "%LISTFILE%" 2>nul
echo.
call :pauseit
exit /b 0

REM ---------------------------------------------------------------
:protected
echo.
echo ========================================================
echo DITOLAK: [!TARGET_DB!] database sistem, tidak boleh dihapus!
echo ========================================================
del "%LISTFILE%" 2>nul
echo.
call :pauseit
exit /b 1

REM ---------------------------------------------------------------
REM  SUBROUTINE: trim %1 (hapus spasi di awal & akhir)
REM ---------------------------------------------------------------
:trim
set "_T=!%~1!"
:trim_lead
if "!_T:~0,1!"==" " (
    set "_T=!_T:~1!"
    goto :trim_lead
)
:trim_tail
if "!_T:~-1!"==" " (
    set "_T=!_T:~0,-1!"
    goto :trim_tail
)
if "!_T:~-1!"=="	" (
    set "_T=!_T:~0,-1!"
    goto :trim_tail
)
set "%~1=!_T!"
goto :eof

REM ---------------------------------------------------------------
:pauseit
if defined DROPTEST goto :eof
pause
goto :eof
