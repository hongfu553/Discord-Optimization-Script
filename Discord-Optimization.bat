@echo off
setlocal enabledelayedexpansion

:: 1. Set directory and local cache paths
set "ModDir=C:\DiscordMods"
set "VencordCliPath=%ModDir%\VencordInstallerCli.exe"
set "OpenAsarLocalPath=%ModDir%\app.asar"
set "OpenAsarUrl=https://github.com/GooseMod/OpenAsar/releases/latest/download/app.asar"
set "VencordCliUrl=https://github.com/Vencord/Installer/releases/latest/download/VencordInstallerCli.exe"

set "UpdateNeeded=0"

echo [1/4] Checking local cache status...
if not exist "%ModDir%" mkdir "%ModDir%"

:: If the file does not exist, mark for update
if not exist "%VencordCliPath%" set "UpdateNeeded=1"
if not exist "%OpenAsarLocalPath%" set "UpdateNeeded=1"

:: If the file exists, use PowerShell to check if it's older than 7 days
if !UpdateNeeded!==0 (
    powershell -NoProfile -Command "if ((Get-Item '%OpenAsarLocalPath%').LastWriteTime -lt (Get-Date).AddDays(-7)) { exit 1 } else { exit 0 }"
    if !errorlevel! neq 0 set "UpdateNeeded=1"
)

:: 2. Connect to GitHub only when needed
if !UpdateNeeded!==1 (
    echo [2/4] Triggering update mechanism: sync'ing latest version with GitHub...
    curl -L -R -z "%VencordCliPath%" -o "%VencordCliPath%" "%VencordCliUrl%"
    curl -L -R -z "%OpenAsarLocalPath%" -o "%OpenAsarLocalPath%" "%OpenAsarUrl%"
) else (
    echo [2/4] Cache valid: skipping network check, fast booting!
)

:: 3. Close Discord
echo [3/4] Preparing environment injection...
taskkill /F /IM Discord.exe /T >nul 2>&1

:: Find the latest Discord directory
set "DISCORD_DIR=%localappdata%\Discord"
for /f "delims=" %%i in ('dir /b /ad /o-n "%DISCORD_DIR%\app-*"') do (
    set "TARGET_DIR=%DISCORD_DIR%\%%i\resources"
    goto :found
)
:found

:: 4. Applying OpenAsar and Vencord and starting Discord
echo [4/4] Applying OpenAsar and Vencord, and starting Discord...
copy /Y "%OpenAsarLocalPath%" "%TARGET_DIR%\app.asar" >nul
"%VencordCliPath%" -install -branch stable >nul

start "" "%DISCORD_DIR%\Update.exe" --processStart Discord.exe
exit