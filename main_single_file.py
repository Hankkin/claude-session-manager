#!/usr/bin/env python3
"""Claude Session Manager - macOS menu bar app"""

import sys
from pathlib import Path

# Add src to path for development
sys.path.insert(0, str(Path(__file__).parent / "src"))

from app import SessionManagerApp


if __name__ == "__main__":
    app = SessionManagerApp()
    app.run()
