@echo off
setlocal enabledelayedexpansion
REM ============================================================
REM  Commissioner (Appeals-II), Inland Revenue
REM  Appeals Management System - install / update from GitHub
REM
REM  Double-click this file. It works for BOTH cases:
REM    * first time  - clones the project into D:\CIR_Appeal_II
REM    * afterwards  - pulls the latest changes into it
REM
REM  It then rebuilds the environment, applies database changes
REM  and refreshes the static files.
REM
REM  YOUR DATA IS NEVER TOUCHED. db.sqlite3, media and
REM  secret_key.txt are excluded from GitHub, so updating the
REM  code cannot overwrite your appeal records.
REM ============================================================

set "TARGET=D:\CIR_Appeal_II"
set "REPO_HOST=github.com/Tajmalookcs/cira_ii_fsd.git"
set "BRANCH=main"
set "TOKENFILE=%~dp0github_token.txt"

title Appeals System - Update from GitHub

echo.
echo  ============================================================
echo   Appeals System  -  Install / Update from GitHub
echo  ============================================================
echo.
echo   Target folder : %TARGET%
echo.

REM ---------- 1. Prerequisites --------------------------------
where git >nul 2>&1
if errorlevel 1 (
    echo   ERROR: Git is not installed.
    echo.
    echo   Install "Git for Windows" from https://git-scm.com/download/win
    echo   then run this file again.
    echo.
    pause
    exit /b 1
)

set "PY="
where py >nul 2>&1 && set "PY=py -3.12"
if not defined PY (
    where python >nul 2>&1 && set "PY=python"
)
if not defined PY (
    echo   ERROR: Python is not installed, or not on the PATH.
    echo.
    echo   Install Python 3.12 from https://www.python.org/downloads/
    echo   Tick "Add Python to PATH" during setup, then run this again.
    echo.
    pause
    exit /b 1
)

REM ---------- 2. Access token (only needed for a private repo) -
REM Downloading a PUBLIC repository needs no credential at all, so
REM a missing token file is normal and not an error. If the token
REM file exists it is used, which covers the repository being made
REM private later. The token is never written inside this script.
set "TOKEN="
if exist "%TOKENFILE%" (
    for /f "usebackq delims=" %%a in ("%TOKENFILE%") do (
        if not defined TOKEN set "TOKEN=%%a"
    )
)

if defined TOKEN (
    set "REPO_URL=https://!TOKEN!@%REPO_HOST%"
    echo   Using the access token from github_token.txt
) else (
    set "REPO_URL=https://%REPO_HOST%"
    echo   Public repository - no access token needed
)
set "CLEAN_URL=https://%REPO_HOST%"

REM Git output is filtered so a token can never appear on screen.
REM With no token, a sentinel is used so findstr still has something
REM to search for - an empty search string is rejected by findstr.
if defined TOKEN (set "MASK=!TOKEN!") else (set "MASK=__no_token_in_use__")
echo.

REM ---------- 3. Stop the server so files are not locked -------
echo   Stopping the Appeals System if it is running...
powershell -NoProfile -Command ^
  "Get-CimInstance Win32_Process -Filter \"Name='python.exe'\" | Where-Object { $_.CommandLine -like '*CIR_Appeal_II*runserver*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }" >nul 2>&1
timeout /t 2 /nobreak >nul

REM ---------- 4. Clone or pull --------------------------------
if exist "%TARGET%\.git" goto :pull

REM --- first installation ---
if exist "%TARGET%\db.sqlite3" (
    echo.
    echo   STOPPED. %TARGET% already holds a database but is not a
    echo   Git working copy. Cloning over it could destroy records.
    echo.
    echo   Move or rename that folder first, then run this again.
    echo.
    pause
    exit /b 1
)

echo   First installation - downloading the project...
echo.
git clone --branch %BRANCH% "!REPO_URL!" "%TARGET%" 2>&1 | findstr /v /c:"!MASK!"
if not exist "%TARGET%\.git" (
    echo.
    echo   DOWNLOAD FAILED.
    echo   Check your network connection. If the repository has been
    echo   made private, run "Save GitHub Token.bat" first.
    echo.
    pause
    exit /b 1
)
REM Store the address WITHOUT the token, so it is not written to disk.
git -C "%TARGET%" remote set-url origin "%CLEAN_URL%"
echo   Project downloaded.
goto :environment

:pull
echo   Updating the project...
echo.
git -C "%TARGET%" remote set-url origin "%CLEAN_URL%"
git -C "%TARGET%" fetch "!REPO_URL!" %BRANCH% 2>&1 | findstr /v /c:"!MASK!"
if errorlevel 1 (
    echo.
    echo   COULD NOT REACH GITHUB.
    echo   Check your network connection. If the repository has been
    echo   made private, run "Save GitHub Token.bat" first.
    echo.
    pause
    exit /b 1
)

git -C "%TARGET%" merge --ff-only FETCH_HEAD
if errorlevel 1 (
    echo.
    echo   ------------------------------------------------------------
    echo   UPDATE STOPPED - this copy has local changes.
    echo.
    echo   Nothing was changed and no data was lost. Someone has
    echo   edited files here, so the update cannot be applied
    echo   automatically without discarding that work.
    echo.
    echo   Ask for help before continuing.
    echo   ------------------------------------------------------------
    echo.
    pause
    exit /b 1
)
echo   Code updated.

:environment
echo.
echo   ------------------------------------------------------------
echo   Preparing the environment
echo   ------------------------------------------------------------

cd /d "%TARGET%"

if not exist "venv\Scripts\python.exe" (
    echo   Creating the Python environment...
    %PY% -m venv venv
    if not exist "venv\Scripts\python.exe" (
        echo   ERROR: could not create the Python environment.
        pause
        exit /b 1
    )
)

echo   Installing required packages...
venv\Scripts\python.exe -m pip install --quiet --upgrade pip
venv\Scripts\python.exe -m pip install --quiet -r requirements.txt
if errorlevel 1 (
    echo   ERROR: packages could not be installed.
    pause
    exit /b 1
)

REM ---------- 5. Back up the database before touching it ------
if exist "db.sqlite3" (
    if not exist "backups" mkdir "backups"
    for /f %%d in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HHmm"') do set "STAMP=%%d"
    copy /y "db.sqlite3" "backups\db_before_update_!STAMP!.sqlite3" >nul
    echo   Database backed up to backups\db_before_update_!STAMP!.sqlite3
)

echo   Applying database changes...
venv\Scripts\python.exe manage.py migrate --noinput
if errorlevel 1 (
    echo.
    echo   ERROR: the database update failed. Your data is unchanged
    echo   and a backup is in the backups folder.
    pause
    exit /b 1
)

echo   Refreshing static files...
venv\Scripts\python.exe manage.py collectstatic --noinput >nul
if errorlevel 1 (
    echo   WARNING: static files could not be refreshed.
)

REM ---------- 6. Done -----------------------------------------
echo.
echo  ============================================================
echo   UPDATE COMPLETE
echo  ============================================================
for /f "delims=" %%v in ('git -C "%TARGET%" log -1 --pretty^=format:"%%h  %%s"') do echo   Now at: %%v
echo.

choice /c YN /n /m "  Start the Appeals System now? [Y/N] "
if errorlevel 2 goto :finish
if exist "%TARGET%\Start Appeals System.vbs" (
    start "" wscript.exe "%TARGET%\Start Appeals System.vbs"
    echo   Starting...
) else (
    echo   Start Appeals System.vbs was not found.
)

:finish
echo.
timeout /t 4 /nobreak >nul
endlocal
