# Makefile for audio-analyzer
# Cross-platform build helper

.PHONY: build release clean analyze help

# Build in debug mode
build:
	cargo build

# Build in release mode (optimized)
release:
	cargo build --release

# Clean build artifacts
clean:
	cargo clean

# Run with example (change this to your file)
analyze: release
	@echo "Usage: make analyze FILE=../assets/music.mp3"
	@if [ -z "$(FILE)" ]; then \
		echo "Error: Please specify FILE=path/to/audio.mp3"; \
		exit 1; \
	fi
	./target/release/audio-analyzer --input $(FILE)

# Show help
help:
	@echo "Available targets:"
	@echo "  make build      - Build in debug mode"
	@echo "  make release    - Build in release mode (optimized)"
	@echo "  make clean      - Remove build artifacts"
	@echo "  make analyze FILE=../assets/music.mp3  - Analyze an audio file"
	@echo "  make help       - Show this help message"

