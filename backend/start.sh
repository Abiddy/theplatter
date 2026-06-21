#!/bin/bash
# Must use 0.0.0.0 so your iPhone can reach the server over Wi-Fi.
cd "$(dirname "$0")"
source .venv/bin/activate
echo "Starting Platter API on http://0.0.0.0:8000"
echo "iPhone should use: http://$(ipconfig getifaddr en0):8000"
uvicorn main:app --reload --host 0.0.0.0 --port 8000
