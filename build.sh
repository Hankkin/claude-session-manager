#!/bin/bash
# Rebuild the macOS app

cd "$(dirname "$0")"

# Install py2app if not present
source .venv/bin/activate 2>/dev/null || python3 -m venv .venv && source .venv/bin/activate
pip install py2app -q

# Rebuild
rm -rf build dist
python3 setup.py py2app

# Copy to Applications
rm -rf "/Applications/ClaudeSessionManager.app"
cp -R dist/Claude.app "/Applications/ClaudeSessionManager.app"

echo "Done! App installed to /Applications/ClaudeSessionManager.app"
