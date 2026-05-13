@echo off
setlocal enabledelayedexpansion

:: 1. Set variables and paths
set "ModDir=C:\DiscordMods"
set "VencordCliPath=%ModDir%\VencordInstallerCli.exe"
set "OpenAsarLocalPath=%ModDir%\app.asar"
set "VersionCache=%ModDir%\last_version.txt"
set "OpenAsarUrl=https://github.com/GooseMod/OpenAsar/releases/latest/download/app.asar"
set "VencordCliUrl=https://github.com/Vencord/Installer/releases/latest/download/VencordInstallerCli.exe"

set "UpdateNeeded=0"
set "InjectionNeeded=0"

echo [1/5] Checking cache and version status...
if not exist "%ModDir%" mkdir "%ModDir%"

:: Check if files are missing
if not exist "%VencordCliPath%" set "UpdateNeeded=1"
if not exist "%OpenAsarLocalPath%" set "UpdateNeeded=1"

:: 2. Replace PowerShell: Use built-in forfiles to check if files are older than 7 days
if !UpdateNeeded!==0 (
    forfiles /P "%ModDir%" /M app.asar /D -7 >nul 2>&1
    :: If errorlevel == 0, it means files older than 7 days were found, triggering update
    if !errorlevel!==0 set "UpdateNeeded=1"
)

:: 3. Locate the latest Discord core folder in the system
set "DISCORD_DIR=%localappdata%\Discord"
for /f "delims=" %%i in ('dir /b /ad /o-n "%DISCORD_DIR%\app-*"') do (
    set "LATEST_APP_FOLDER=%%i"
    set "TARGET_DIR=%DISCORD_DIR%\%%i\resources"
    goto :found_folder
)
:found_folder

:: Check if Discord has official updates, or if it is the first run
if exist "%VersionCache%" (
    set /p LAST_VERSION=<"%VersionCache%"
    :: If the current version is different from the last record, Discord has just updated itself and needs to be reinjected
    if not "!LAST_VERSION!"=="!LATEST_APP_FOLDER!" set "InjectionNeeded=1"
) else (
    set "InjectionNeeded=1"
)

:: If new files are downloaded from GitHub, reinjection is necessary
if !UpdateNeeded!==1 set "InjectionNeeded=1"

:: 4. Decide whether to connect to GitHub based on status
if !UpdateNeeded!==1 (
    echo [2/5] Triggering update mechanism: Synchronizing the latest version with GitHub...
    curl -L -R -z "%VencordCliPath%" -o "%VencordCliPath%" "%VencordCliUrl%"
    curl -L -R -z "%OpenAsarLocalPath%" -o "%OpenAsarLocalPath%" "%OpenAsarUrl%"
)

:: 5. Decide whether to execute injection based on status (Core optimization point)
if !InjectionNeeded!==1 (
    echo [3/5] Preparing injection environment (Closing Discord)...
    taskkill /F /IM Discord.exe /T >nul 2>&1
    
    echo [4/5] Applying OpenAsar and Vencord...
    copy /Y "%OpenAsarLocalPath%" "%TARGET_DIR%\app.asar" >nul
    "%VencordCliPath%" -install -branch stable >nul
    
    :: Record the successfully injected Discord version number for next boot comparison
    echo !LATEST_APP_FOLDER!>"%VersionCache%"
) else (
    echo [2~4/5] Version up-to-date and cache valid: Skipping installation, launching directly!
)

:: 6. Launching Discord
echo [5/5] Launching Discord...
start "" "%DISCORD_DIR%\Update.exe" --processStart Discord.exe
exit