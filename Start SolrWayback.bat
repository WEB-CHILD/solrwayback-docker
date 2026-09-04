@echo off
REM Windows. Double-click this file to start SolrWayback.
cd /d "%~dp0"

echo.
echo === Starting SolrWayback ===

where docker >nul 2>&1
if errorlevel 1 (
    echo.
    echo Docker Desktop does not seem to be installed.
    echo Install it from https://www.docker.com/products/docker-desktop/ and run this again.
    goto :end
)

REM Docker Desktop may be installed but not running; start it and wait.
docker info >nul 2>&1
if errorlevel 1 (
    echo.
    echo Starting Docker Desktop, please wait...
    start "" "%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
    set WAITED=0
    goto :waitdocker
)
goto :dockerup

:waitdocker
timeout /t 5 /nobreak >nul
docker info >nul 2>&1
if not errorlevel 1 goto :dockerup
set /a WAITED+=1
if %WAITED% LSS 60 goto :waitdocker
echo.
echo Docker Desktop did not start.
echo Open it manually, wait until it says "Running", then run this again.
goto :end

:dockerup

REM Prefer a published image; fall back to building locally if that is not
REM available (no network, or the image was never pushed).
echo.
echo Getting SolrWayback (this can take several minutes the first time)...
docker compose pull --quiet >nul 2>&1
if errorlevel 1 (
    echo.
    echo No published image available, building locally instead...
    docker compose build
    if errorlevel 1 (
        echo.
        echo Could not build SolrWayback. See the messages above.
        goto :end
    )
)

echo.
echo Starting up...
docker compose up -d
if errorlevel 1 (
    echo.
    echo Could not start SolrWayback. See the messages above.
    goto :end
)

REM Read the host port out of .env, defaulting to 8090.
set "PORT=8090"
if exist .env for /f "usebackq tokens=1,* delims==" %%A in (".env") do (
    if /i "%%A"=="SW_HTTP_PORT" set "PORT=%%B"
)
set "URL=http://localhost:%PORT%"

echo.
echo Waiting for SolrWayback to be ready...
set TRIES=0

:waitapp
curl -fsS "%URL%/solrwayback/" >nul 2>&1
if not errorlevel 1 goto :appup
timeout /t 5 /nobreak >nul
set /a TRIES+=1
if %TRIES% LSS 60 goto :waitapp
echo.
echo SolrWayback did not respond in time. Check Docker Desktop is running, then try again.
goto :end

:appup
start "" "%URL%/solrwayback/"
echo.
echo SolrWayback is running.
echo.
echo   Address:    %URL%/solrwayback/
echo   WARC files: %CD%\warcs
echo.
echo To add web archives, put .warc or .warc.gz files in the "warcs" folder,
echo then run this Start file again. New files are indexed automatically -
echo that can take a while, and the archive fills in as it goes.
echo.
echo To shut down, double-click "Stop SolrWayback".

:end
echo.
pause
