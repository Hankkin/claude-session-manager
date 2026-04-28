from setuptools import setup

setup(
    app=['main.py'],
    setup_requires=['py2app'],
    data_files=[
        ('Resources', ['app.icns']),
    ],
    options={
        'py2app': {
            'iconfile': 'app.icns',
            'plist': {
                'LSUIElement': True,
                'CFBundleName': 'Claude',
                'CFBundleDisplayName': 'Claude',
                'CFBundleIdentifier': 'com.claude.session-manager',
            },
            'argv_emulation': False,
        }
    }
)
