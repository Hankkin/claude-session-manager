# Claude Session Manager

macOS menu bar app for managing Claude CLI chat sessions. View, search, and resume previous Claude conversations with ease.

## Features

- Menu bar app with session history list
- Search sessions by project or message content
- Resume any previous session with one click
- Session details with first message preview
- Time-based grouping (Today, Yesterday, Earlier)
- Swift native macOS app with Python CLI fallback

## Screenshots

![Claude Session Manager](app.png)

## Requirements

- macOS
- Claude CLI (`pip install claude`)
- Python 3.10+ (for CLI version)

## Installation

### Swift App (Recommended)

1. Build the app:
```bash
cd ClaudeSessionManagerSwift
xcodebuild -project ClaudeSessionManager.xcodeproj -scheme ClaudeSessionManager -configuration Release build
```

2. Open `build/Release/ClaudeSessionManager.app` and drag to Applications

### Python CLI Version

```bash
pip install -r requirements.txt
python main.py
```

## Project Structure

```
.
├── main.py                    # Python CLI entry point
├── main_single_file.py        # Single-file Python version
├── ClaudeSessionManagerSwift/ # Swift macOS app
│   ├── Sources/
│   │   ├── AppDelegate.swift
│   │   ├── Components/         # UI components
│   │   ├── ViewControllers/    # View controllers
│   │   └── Theme/              # Colors, fonts, spacing
│   └── Resources/
├── src/                        # Python source
│   ├── app.py
│   └── models.py
├── build.sh                    # Build script
├── dist/                       # Built Python app
└── README.md
```

## Usage

1. Launch the app
2. Browse sessions in the sidebar (grouped by date)
3. Click a session to view details
4. Click "Resume" to continue chatting in terminal

## License

MIT
