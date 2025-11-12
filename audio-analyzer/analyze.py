#!/usr/bin/env python3
"""
Cross-platform audio analyzer script for Sound Wave Surfer
Works on Windows, macOS, and Linux
"""

import sys
import subprocess
import os
from pathlib import Path

def main():
    if len(sys.argv) < 2:
        print("Usage: python analyze.py [audio_file.mp3]")
        print("Example: python analyze.py ../assets/music.mp3")
        sys.exit(1)
    
    audio_file = sys.argv[1]
    
    if not os.path.exists(audio_file):
        print(f"Error: File not found: {audio_file}")
        sys.exit(1)
    
    print("Building audio-analyzer...")
    build_result = subprocess.run(["cargo", "build", "--release"])
    
    if build_result.returncode != 0:
        print("Build failed!")
        sys.exit(1)
    
    print()
    print(f"Analyzing {audio_file}...")
    print()
    
    # Determine executable name based on platform
    if sys.platform == "win32":
        exe_path = Path("target/release/audio-analyzer.exe")
    else:
        exe_path = Path("target/release/audio-analyzer")
    
    analyze_result = subprocess.run([str(exe_path), "--input", audio_file])
    
    if analyze_result.returncode != 0:
        print("Analysis failed!")
        sys.exit(1)
    
    print()
    print("Done! Files generated in the same directory as your input file.")
    print("Now run the game with: love .")

if __name__ == "__main__":
    main()

