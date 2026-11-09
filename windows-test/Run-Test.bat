@echo off
REM ===================================================================
REM  Run-Test.bat - Double-click de chay Test-LaptopCu.ps1
REM  Tu dong xin quyen Administrator (de doc SSD, BitLocker, mat khau BIOS).
REM ===================================================================
setlocal
cd /d "%~dp0"

REM --- Kiem tra quyen admin, neu chua co thi xin nang quyen (UAC) ---
REM Duong dan truyen qua bien moi truong de khong vo khi thu muc co dau ' hoac ( )
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Dang xin quyen Administrator... [bam YES khi cua so UAC hien ra]
    set "LAPTOPTEST_BAT=%~f0"
    powershell -NoProfile -Command "Start-Process -FilePath $env:LAPTOPTEST_BAT -Verb RunAs"
    exit /b
)

echo.
echo ============================================================
echo   Bat dau kiem tra laptop... (khoang 1-2 phut)
echo   Co buoc ep CPU 30 giay: quat quay to la binh thuong.
echo ============================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-LaptopCu.ps1"

endlocal
