#!/bin/bash
cd "$(dirname "$0")"
source .venv/bin/activate 2>/dev/null || python3 -m venv .venv && source .venv/bin/activate
pip install rumps pyobjc-framework-Cocoa -q
python3 main.py
