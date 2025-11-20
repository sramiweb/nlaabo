@echo off
echo Installing Python dependencies for icon generation...
pip install -r requirements.txt
echo.
echo Python dependencies installed successfully!
echo You can now run: python tools/generate_icons.py
pause