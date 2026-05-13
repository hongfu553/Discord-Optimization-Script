@echo off
setlocal enabledelayedexpansion

:: 1. Set variables and paths
set "ModDir=C:\DiscordMods"
set "VencordCliPath=%ModDir%\VencordInstallerCli.exe"
set "OpenAsarLocalPath=%ModDir%\app.asar"
set "VersionCache=%ModDir%\last_version.txt"
set "DISCORD_DIR=%localappdata%\Discord"

if not exist "%ModDir%" mkdir "%ModDir%"

set "UpdateNeeded=0"
set "InjectionNeeded=0"

:: 2. Check cache and version (using efficient forfiles)
if not exist "%VencordCliPath%" set "UpdateNeeded=1"
if not exist "%OpenAsarLocalPath%" set "UpdateNeeded=1"

if !UpdateNeeded!==0 (
    forfiles /P "%ModDir%" /M app.asar /D -7 >nul 2>&1
    if !errorlevel!==0 set "UpdateNeeded=1"
)

:: 3. Get the latest Discord folder path
for /f "delims=" %%i in ('dir /b /ad /o-n "%DISCORD_DIR%\app-*"') do (
    set "LATEST_APP_FOLDER=%%i"
    set "TARGET_DIR=%DISCORD_DIR%\%%i\resources"
    goto :found_folder
)
:found_folder

:: Check if re-injection is needed (version change or cache update)
if exist "%VersionCache%" (
    set /p LAST_VERSION=<"%VersionCache%"
    if not "!LAST_VERSION!"=="!LATEST_APP_FOLDER!" set "InjectionNeeded=1"
) else (
    set "InjectionNeeded=1"
)
if !UpdateNeeded!==1 set "InjectionNeeded=1"

:: 4. Download logic
if !UpdateNeeded!==1 (
    echo [1/4] Synchronizing latest version from GitHub...
    curl -L -R -o "%VencordCliPath%" "https://github.com/Vencord/Installer/releases/latest/download/VencordInstallerCli.exe"
    curl -L -R -o "%OpenAsarLocalPath%" "https://github.com/GooseMod/OpenAsar/releases/latest/download/app.asar"
)

:: 5. Injection logic (keep necessary delay to ensure stability)
if !InjectionNeeded!==1 (
    echo [2/4] Preparing environment...
    taskkill /F /IM Discord.exe /T >nul 2>&1
    timeout /t 2 >nul

    echo [3/4] Installing optimization patches...
    copy /Y "%OpenAsarLocalPath%" "%TARGET_DIR%\app.asar"
    
    :: Execute Vencord injection, do not hide output so user can see errors/prompts
    "%VencordCliPath%" -install -branch stable
    
    echo !LATEST_APP_FOLDER!>"%VersionCache%"
) else (
    echo [1~3/4] Cache and version are valid, skipping installation steps.
)

:: 6. Start Discord
echo [4/4] Starting Discord...
start "" "%DISCORD_DIR%\Update.exe" --processStart Discord.exe
exit