@echo off

REM Set your variables
set SERVER_USER=admin
set SERVER_HOST=7.7.7.7
set REMOTE_FILE=/secret/path/backup.tar.gz.gpg
set LOCAL_FOLDER=E:\Backup\Server
set PPK_PATH=%USERPROFILE%\Desktop\Backup\privatekey.ppk

REM Create local folder if it doesn't exist
if not exist "%LOCAL_FOLDER%" mkdir "%LOCAL_FOLDER%"

REM Run pscp
"%USERPROFILE%\Desktop\Backup\pscp.exe" -i "%PPK_PATH%" "%SERVER_USER%@%SERVER_HOST%:%REMOTE_FILE%" "%LOCAL_FOLDER%"

pause
