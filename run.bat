@echo off
setlocal
pushd "%~dp0" || goto directory_error

if exist ".venv\Scripts\python.exe" (
    ".venv\Scripts\python.exe" -c "import sys; sys.exit(sys.version_info < (3, 11))" >nul 2>&1
    if not errorlevel 1 goto use_venv
)

py -3 -c "import sys; sys.exit(sys.version_info < (3, 11))" >nul 2>&1
if not errorlevel 1 (
    set "SLOT_PYTHON=py -3"
    goto prepare
)

for /d %%D in ("%LocalAppData%\Programs\Python\Python3*") do (
    if exist "%%~fD\python.exe" (
        "%%~fD\python.exe" -c "import sys; sys.exit(sys.version_info < (3, 11))" >nul 2>&1
        if not errorlevel 1 (
            set SLOT_PYTHON="%%~fD\python.exe"
            goto prepare
        )
    )
)

where python.exe 2>nul | findstr /i /v /c:"\Microsoft\WindowsApps\" >nul
if not errorlevel 1 (
    python -c "import sys; sys.exit(sys.version_info < (3, 11))" >nul 2>&1
    if not errorlevel 1 (
        set "SLOT_PYTHON=python"
        goto prepare
    )
)

echo Python 3.11 or newer is required. Install it from https://www.python.org/downloads/windows/
goto failed

:prepare
%SLOT_PYTHON% -c "from importlib.metadata import version; from packaging.requirements import Requirement; import sys; deps=[Requirement(line.strip()) for line in open('requirements.txt') if line.strip()]; sys.exit(not all(version(dep.name) in dep.specifier for dep in deps))" >nul 2>&1
if not errorlevel 1 goto launch
echo Creating the local Python environment...
%SLOT_PYTHON% -m venv .venv
if errorlevel 1 goto failed

:use_venv
set SLOT_PYTHON=".venv\Scripts\python.exe"
%SLOT_PYTHON% -c "from importlib.metadata import version; from packaging.requirements import Requirement; import sys; deps=[Requirement(line.strip()) for line in open('requirements.txt') if line.strip()]; sys.exit(not all(version(dep.name) in dep.specifier for dep in deps))" >nul 2>&1
if errorlevel 1 (
    echo Installing the dependencies. An internet connection is required.
    %SLOT_PYTHON% -m pip install -r requirements.txt
    if errorlevel 1 goto failed
)

:launch
%SLOT_PYTHON% -m streamlit run app.py --server.address=127.0.0.1 --server.headless=false --browser.gatherUsageStats=false
if errorlevel 1 goto failed
popd
exit /b 0

:failed
popd
:directory_error
echo Could not start the app. Check the message above.
pause
exit /b 1
