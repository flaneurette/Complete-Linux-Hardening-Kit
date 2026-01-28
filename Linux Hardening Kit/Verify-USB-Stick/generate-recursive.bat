@echo off
setlocal enabledelayedexpansion

REM Choose mode: GENERATE or VERIFY
set MODE=GENERATE

echo.
echo ===============================
echo Hash batch started
echo Mode: %MODE%
echo ===============================
echo.

REM --- GENERATE HASHES ---
if /I "%MODE%"=="GENERATE" (
    for /R %%F in (*) do (
        if /I not "%%~xF"==".sha256" (
            echo Generating hash for %%F
            certutil -hashfile "%%F" SHA256 > "%%F.sha256"
        )
    )
    echo.
    echo All hashes generated.
)

REM --- VERIFY HASHES ---
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
    )
    echo.
    echo All files verified.
)

echo.
echo Press any key to exit...
pause >nul
