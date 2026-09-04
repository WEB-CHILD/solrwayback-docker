@echo off
REM Windows. Double-click this file to stop SolrWayback.
cd /d "%~dp0"

echo.
echo === Stopping SolrWayback ===
echo.

docker info >nul 2>&1
if errorlevel 1 (
    echo Docker Desktop is not running, so SolrWayback is already stopped.
) else (
    docker compose stop
    echo.
    echo SolrWayback has been shut down. Your archive is kept.
    echo Double-click "Start SolrWayback" to use it again.
)

echo.
pause
