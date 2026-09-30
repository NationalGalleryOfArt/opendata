:: Ensure Python is installed
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo Python is not installed! Install Python and try again.
    exit /b
)

:: Create virtual environment (optional but recommended)
python -m venv venv
call venv\Scripts\activate

:: Install dependencies
pip install --upgrade pip
pip install pandas requests tqdm

:: Run Python script
python download_dataset.py
