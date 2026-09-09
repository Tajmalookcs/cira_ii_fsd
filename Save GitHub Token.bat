@echo off
setlocal
REM ============================================================
REM  Commissioner (Appeals-II), Inland Revenue
REM
REM  Saves your GitHub access token so "Update from GitHub.bat"
REM  can download updates without asking you to sign in.
REM
REM  The token is typed by you and written straight to
REM  github_token.txt beside this script. It is never stored
REM  inside any script, and github_token.txt is excluded from
REM  GitHub, so it stays on this machine only.
REM ============================================================

set "TOKENFILE=%~dp0github_token.txt"

title Appeals System - Save GitHub Token

echo.
echo  ============================================================
echo   Save GitHub Access Token
echo  ============================================================
echo.
echo   The token will be saved to:
echo       %TOKENFILE%
echo.

if exist "%TOKENFILE%" (
    echo   A token file already exists.
    choice /c YN /n /m "  Replace it? [Y/N] "
    if errorlevel 2 (
        echo.
        echo   Left unchanged.
        timeout /t 3 /nobreak >nul
        exit /b 0
    )
    echo.
)

echo   Paste your GitHub token below, then press Enter.
echo   ^(Right-click in this window to paste.^)
echo.
echo   Leave it blank and press Enter if the repository is
echo   public - no token is needed for a public repository.
echo.

set "TOKEN="
set /p "TOKEN=  Token: "

REM Written with no trailing spaces or extra lines.
>"%TOKENFILE%" echo|set /p="%TOKEN%"

echo.
if defined TOKEN (
    echo   Saved. First and last characters: %TOKEN:~0,4%...%TOKEN:~-4%
    echo   ^(shown only so you can confirm it pasted correctly^)
) else (
    echo   Saved as empty - the repository will be treated as public.
)

echo.
echo   You can now run "Update from GitHub.bat".
echo.
echo   Keep this file private. Anyone who can read it can reach
echo   your GitHub account. If it is ever exposed, revoke the
echo   token at github.com/settings/tokens and save a new one.
echo.
pause
endlocal
