@echo off
REM Quick script to analyze audio files for Sound Wave Surfer

if "%~1"=="" (
    echo Usage: analyze.bat [audio_file.mp3]
    echo Example: analyze.bat ..\assets\music.mp3
    exit /b 1
)

echo Building audio-analyzer...
cargo build --release

if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

echo.
echo Analyzing %1...
echo.

target\release\audio-analyzer.exe --input "%~1"

echo.
echo Done! Files generated in the same directory as your input file.
echo Now run the game with: love .

