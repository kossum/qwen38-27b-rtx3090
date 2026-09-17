@echo off
setlocal

docker -v >nul 2>&1
if errorlevel 1 (
    echo Docker is not installed.
    pause
    exit /b 1
)

docker info >nul 2>&1
if errorlevel 1 (
    echo Docker Engine is not running. Starting Docker Desktop...
    docker desktop start --detach
) else (
  goto start_qwen
)

echo Waiting for Docker Engine...
:wait_docker
docker info >nul 2>&1
if errorlevel 1 (
    timeout /t 2 /nobreak >nul
    goto wait_docker
)

:start_qwen
cd /d "%~dp0"

echo === Starting Qwen3.8-27B (single-user, DFlash2) ===
echo.

echo [1/2] docker compose --profile single down
docker compose --profile single down || (echo [FAIL] down & pause & exit /b 1)
echo.

echo [2/2] docker compose --profile single up -d --force-recreate
docker compose --profile single up -d --force-recreate || (echo [FAIL] up & pause & exit /b 1)
echo.

timeout /t 5 /nobreak >nul
docker compose --profile single ps
echo.
echo   Monitor: docker compose --profile single logs -f
echo   GPU:     nvidia-smi
echo.
echo.
docker compose --profile single logs -f
pause
