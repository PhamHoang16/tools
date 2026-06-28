@echo off
REM ===================================================================
REM  Run-Test.bat - Double-click de chay Test-LaptopCu.ps1
REM  Tu dong xin quyen Administrator (de doc duoc do hao mon SSD).
REM ===================================================================
setlocal
cd /d "%~dp0"

REM --- Kiem tra quyen admin, neu chua co thi xin nang quyen (UAC) ---
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Dang xin quyen Administrator... [bam YES khi cua so UAC hien ra]
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo ============================================================
echo   Bat dau kiem tra laptop... (vui long cho ~30-60 giay)
echo ============================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-LaptopCu.ps1"

endlocal
