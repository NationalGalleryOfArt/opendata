#!/bin/bash

# Ensure Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Python3 not found! Install it and try again."
    exit 1
fi

# Create virtual environment (optional but recommended)
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install pandas requests tqdm

# Run Python script
python3 download_dataset.py
