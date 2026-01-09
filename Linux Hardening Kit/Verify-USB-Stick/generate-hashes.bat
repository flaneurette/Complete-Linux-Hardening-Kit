@echo off
setlocal

set OUTFILE=hashes_sha256.txt
if exist "%OUTFILE%" del "%OUTFILE%"

echo Generating hashes in the current folder...
echo. >> "%OUTFILE%"

for %%F in (*) do (
    if /I not "%%~nxF"=="%OUTFILE%" (
        echo %%~nxF >> "%OUTFILE%"
        certutil -hashfile "%%F" SHA256 >> "%OUTFILE%"
        echo. >> "%OUTFILE%"
    )
)

echo.
echo All hashes written to %OUTFILE%.
echo Press any key to exit...
pause >nul
