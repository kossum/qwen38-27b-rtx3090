@echo off
setlocal
cd /d "%~dp0"

set "REPO=leminkozey/Qwen3.8-27B-Uncensored-W4A16-AutoRound"
set "DEST=models\leminkozey-Qwen3.8-27B-Uncensored-W4A16-AutoRound"
set "VENV=venv"
set "VPY=%VENV%\Scripts\python.exe"
set "UV="

echo === [1/2] Downloading %REPO% ===
echo (Xet protocol, ~17 GB; one shared venv for download + build)
echo.

rem Pin the interpreter via uv (it lives on the user PATH, independent of
rem whatever bare `python`/conda resolves to) so a rebuild is deterministic.
rem Fall back to stdlib venv if uv is not on PATH.
where uv >nul 2>&1
if not errorlevel 1 set "UV=uv"

python -V >nul 2>&1
if errorlevel 1 (
    echo Python is not installed.
    pause
    exit /b 1
)

if not exist "%VPY%" (
    echo Creating shared venv (pinned CPython 3.11 via uv)...
    if defined UV (
        %UV% venv --python 3.11 %VENV%
    ) else (
        python -m venv %VENV%
    )
    rem CPU torch from the PyTorch CPU index (pure CPU; imports without a
    rem GPU / WSL2 CUDA DLLs). The download step never imports torch.
    if defined UV (
        %UV% pip install --python "%VPY%" torch==2.14.0+cpu --index-url https://download.pytorch.org/whl/cpu
    ) else (
        %VPY% -m pip install torch==2.14.0+cpu --index-url https://download.pytorch.org/whl/cpu
    )
    rem download stack (hf CLI + xet) and build stack (tokenizer + safetensors)
    if defined UV (
        %UV% pip install --python "%VPY%" transformers==5.15.0 safetensors==0.8.0 compressed-tensors==0.18.0 huggingface_hub==1.31.0 hf-xet==1.6.0
    ) else (
        %VPY% -m pip install transformers==5.15.0 safetensors==0.8.0 compressed-tensors==0.18.0 huggingface_hub==1.31.0 hf-xet==1.6.0
    )
    echo.
)

if exist "%DEST%\config.json" (
    echo [OK] config.json present - download already done (skipping).
    echo      To re-download, delete %DEST% first.
    goto :build
)

%VENV%\Scripts\hf.exe download %REPO% --local-dir %DEST% --max-workers 4
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

:build
echo.
echo === [2/2] Building MTP draft vocab (vocab-truncated draft head) ===
echo (shared venv: slices lm_head to a 40960-token draft head for SPEC=mtp)
echo.

if exist "%DEST%\mtp_draft_vocab_ids.pt" (
    echo [OK] mtp_draft_vocab_ids.pt present - draft head already built (skip).
    echo      A fresh download resets this; rebuild by re-running this bat.
    goto :done
)

%VPY% prepare\build_draft_vocab.py %DEST% --ids prepare\draft_vocab_ids.json
if errorlevel 1 (
    echo.
    echo [FAIL] draft-vocab build errored.
    pause
    exit /b 1
)

echo.
echo [OK] MTP draft vocab built - this model can now run SPEC=mtp with a fast truncated draft head.
:done
echo.
pause
