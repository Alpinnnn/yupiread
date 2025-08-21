@echo off
echo ========================================
echo Building YupiRead Windows Installer
echo ========================================

echo.
echo [1/4] Cleaning previous builds...
flutter clean

echo.
echo [2/4] Getting Flutter dependencies...
flutter pub get

echo.
echo [3/4] Building Windows release...
flutter build windows --release

echo.
echo [4/4] Creating installer with Inno Setup...
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\yupiread_installer.iss
) else if exist "C:\Program Files\Inno Setup 6\ISCC.exe" (
    "C:\Program Files\Inno Setup 6\ISCC.exe" installer\yupiread_installer.iss
) else (
    echo ERROR: Inno Setup not found!
    echo Please install Inno Setup from: https://jrsoftware.org/isdl.php
    echo Then run this script again.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build completed successfully!
echo Installer created in: build\windows\installer\
echo ========================================
pause
