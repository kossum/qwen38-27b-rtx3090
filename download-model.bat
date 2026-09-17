@echo off
setlocal
cd /d "%~dp0"

set "REPO=leminkozey/Qwen3.8-27B-Uncensored-W4A16-AutoRound"
set "DEST=models\leminkozey-Qwen3.8-27B-Uncensored-W4A16-AutoRound"

echo === Downloading %REPO% ===
echo (Xet protocol, ~17 GB, needs hf_xet in venv)
echo.

python -V >nul 2>&1
if errorlevel 1 (
    echo Python is not installed.
    pause
    exit /b 1
)

if not exist "venv\Scripts\hf.exe" (
    python -m venv venv 2>nul
    echo Install python dependencies.
    echo.
    venv\Scripts\pip install torch==2.14.0
    venv\Scripts\pip install safetensors==0.8.0
    venv\Scripts\pip install compressed-tensors==0.18.0
    venv\Scripts\pip install huggingface_hub==1.31.0
    venv\Scripts\pip install hf-xet==1.6.0
    venv\Scripts\pip install transformers==5.17.0
    echo.
)

if exist "%DEST%\config.json" (
    echo [OK] config.json already present - looks like a previous download.
    echo      To re-download, delete %DEST% first.
    pause
    exit /b 0
)

venv\Scripts\hf.exe download %REPO% --local-dir %DEST% --max-workers 4
if errorlevel 1 (
    echo.
    echo [FAIL] Download errored. Check network / retry.
    pause
    exit /b 1
)

echo.
echo === Download complete ===
for %%f in ("%DEST%\*.safetensors") do set /a CNT+=1
echo %CNT% shard(s) present.
pause
