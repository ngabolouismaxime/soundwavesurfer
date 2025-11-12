#!/bin/bash
# Quick script to analyze audio files for Sound Wave Surfer

if [ -z "$1" ]; then
    echo "Usage: ./analyze.sh [audio_file.mp3]"
    echo "Example: ./analyze.sh ../assets/music.mp3"
    exit 1
fi

echo "Building audio-analyzer..."
cargo build --release

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo ""
echo "Analyzing $1..."
echo ""

./target/release/audio-analyzer --input "$1"

echo ""
echo "Done! Files generated in the same directory as your input file."
echo "Now run the game with: love ."

