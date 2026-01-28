@echo off
setlocal enabledelayedexpansion

set MODE=VERIFY

echo.
echo ===============================
echo Hash verification started
echo ===============================
echo.

if /I "%MODE%"=="VERIFY" (
    for /R %%F in (*.sha256) do (
        set HASHFILE=%%F
        set FILE=%%~dpnF%%~xF
        echo Verifying !FILE!
        for /f "skip=1 tokens=*" %%H in ('type "!HASHFILE!"') do (
            certutil -hashfile "!FILE!" SHA256 | find /i "%%H" >nul
            if errorlevel 1 (
                echo Verification FAILED: !FILE!
            ) else (
                echo Verified: !FILE!
            )
        )
        echo.
    )
    echo All files verified.
)

echo.
echo Press any key to exit...
pause >nul
