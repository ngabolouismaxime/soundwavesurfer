# Sound Wave Surfer

A rhythm game prototype created for GitHub Game Off 2025.

## Theme: WAVES

Ride the sound waves! Jump to match the wave peaks and troughs with the beat to score points.

## Controls

- **SPACE** or **LEFT CLICK** - Jump
- **F1** - Toggle debug mode
- **ESC** - Quit

## How to Play

1. Your character (red circle) automatically follows gravity
2. A blue sine wave scrolls from right to left
3. Jump to land on the wave
4. Watch for the beat indicator (yellow circle at the top)
5. When the beat flashes, be on the wave to score points!

## Running the Game

Make sure you have [LÖVE 2D](https://love2d.org/) installed.

### Windows
```bash
love .
```

Or drag the game folder onto the LÖVE executable.

### macOS
```bash
/Applications/love.app/Contents/MacOS/love .
```

### Linux
```bash
love .
```

## Project Structure

- `main.lua` - Main game loop and Love2D callbacks
- `player.lua` - Player physics and jump mechanics
- `wave.lua` - Audio-reactive scrolling wave generation
- `beat.lua` - Beat timing system and scoring
- `utils.lua` - Helper functions
- `conf.lua` - Love2D configuration
- `assets/` - Directory for audio and sprite files
- `audio-analyzer/` - Rust tool for extracting beat and amplitude data
  - `analyze.bat` - Windows helper script
  - `analyze.sh` - Linux/macOS helper script
  - `analyze.py` - Cross-platform Python script
  - `Makefile` - Make-based build helper

## Features

- **Audio-Reactive Wave**: The wave amplitude responds to music in real-time!
- **Real Beat Detection**: Beats extracted from actual audio files, not hardcoded
- **Sound Effects**: Jump, land, and beat-hit audio feedback
- **Smooth Physics**: Physics-based player movement with gravity
- **Score Tracking**: Points for landing on the wave during beats
- **Debug Mode**: Press F1 to see collision data
- **Forgiving Gameplay**: Collision detection with tolerance

## Adding Your Own Music

### Quick Start

1. Place your audio file (MP3, WAV, etc.) in the `assets/` folder (e.g., `assets/mymusic.mp3`)
2. Analyze it with the Rust tool:
   
   **Windows:**
   ```powershell
   cd audio-analyzer
   .\analyze.bat ..\assets\mymusic.mp3
   ```
   
   **Linux/macOS:**
   ```bash
   cd audio-analyzer
   chmod +x analyze.sh  # First time only
   ./analyze.sh ../assets/mymusic.mp3
   ```
   
   **Any platform (Python):**
   ```bash
   cd audio-analyzer
   python analyze.py ../assets/mymusic.mp3
   ```

3. Update `main.lua` line 39 to use your file:
   ```lua
   beat:loadMusic("assets/mymusic.mp3")
   ```
4. Run the game!

The analyzer generates two files:
- `mymusic.beats.txt` - Beat timestamps for the yellow flash indicator
- `mymusic.wave.dat` - Amplitude envelope for the wave animation

See [audio-analyzer/README.md](audio-analyzer/README.md) for detailed usage.

### Without the Analyzer

The game works without analyzed data! It will:
- Generate beats at 100 BPM automatically
- Use a static sine wave (still looks good!)

## Future Enhancements

- Multiple waves with varying frequencies
- Particle effects on successful hits
- Combo system and score multipliers
- Multiple difficulty levels
- Visual themes and backgrounds
- More sophisticated beat detection algorithms

## License

Created for Game Off 2025. Feel free to use and modify as you wish!

