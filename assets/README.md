# Assets Directory

This directory is for game assets like music and sprites.

## Audio Files

To add background music:

1. Place your music file (`.ogg` or `.mp3`) in this directory
2. In `main.lua`, uncomment the line:
   ```lua
   beat:loadMusic("assets/music.ogg")
   ```
3. Replace `"assets/music.ogg"` with your actual filename
4. Optionally uncomment `beat:playMusic()` to start music automatically

## Sprite Files

Place any `.png` or `.jpg` sprite files here for custom player or background graphics.

## Note

For the prototype, the game works without any assets. Audio is optional!

