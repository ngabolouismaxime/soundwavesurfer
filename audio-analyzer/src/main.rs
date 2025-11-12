use clap::Parser;
use rustfft::{FftPlanner, num_complex::Complex};
use std::fs::File;
use std::io::Write;
use std::path::{Path, PathBuf};
use symphonia::core::audio::{AudioBufferRef, Signal};
use symphonia::core::codecs::{CODEC_TYPE_NULL, DecoderOptions};
use symphonia::core::formats::FormatOptions;
use symphonia::core::io::MediaSourceStream;
use symphonia::core::meta::MetadataOptions;
use symphonia::core::probe::Hint;

#[derive(Parser, Debug)]
#[command(author, version, about = "Analyze audio files for beat and amplitude data", long_about = None)]
struct Args {
    /// Input audio file (MP3, WAV, etc.)
    #[arg(short, long)]
    input: PathBuf,

    /// Output directory for generated files (defaults to input file directory)
    #[arg(short, long)]
    output: Option<PathBuf>,

    /// Threshold for beat detection (0.0-1.0, default: 0.3)
    #[arg(short, long, default_value_t = 0.3)]
    threshold: f32,

    /// Sample rate for amplitude data (Hz, default: 60)
    #[arg(short, long, default_value_t = 60.0)]
    sample_rate: f32,
}

struct AudioAnalyzer {
    samples: Vec<f32>,
    sample_rate: u32,
}

impl AudioAnalyzer {
    fn new() -> Self {
        Self {
            samples: Vec::new(),
            sample_rate: 44100,
        }
    }

    fn load_audio(&mut self, path: &Path) -> Result<(), Box<dyn std::error::Error>> {
        let file = File::open(path)?;
        let mss = MediaSourceStream::new(Box::new(file), Default::default());

        let mut hint = Hint::new();
        if let Some(ext) = path.extension() {
            hint.with_extension(ext.to_str().unwrap_or(""));
        }

        let meta_opts: MetadataOptions = Default::default();
        let fmt_opts: FormatOptions = Default::default();

        let probed = symphonia::default::get_probe().format(&hint, mss, &fmt_opts, &meta_opts)?;

        let mut format = probed.format;
        let track = format
            .tracks()
            .iter()
            .find(|t| t.codec_params.codec != CODEC_TYPE_NULL)
            .ok_or("No valid audio track found")?;

        let track_id = track.id;
        self.sample_rate = track.codec_params.sample_rate.unwrap_or(44100);

        let dec_opts: DecoderOptions = Default::default();
        let mut decoder = symphonia::default::get_codecs().make(&track.codec_params, &dec_opts)?;

        println!("Loading audio file...");
        println!("Sample rate: {} Hz", self.sample_rate);

        // Decode all packets
        while let Ok(packet) = format.next_packet() {
            if packet.track_id() != track_id {
                continue;
            }

            match decoder.decode(&packet) {
                Ok(decoded) => {
                    self.append_samples(&decoded);
                }
                Err(_) => break,
            }
        }

        println!(
            "Loaded {} samples ({:.2} seconds)",
            self.samples.len(),
            self.samples.len() as f32 / self.sample_rate as f32
        );

        Ok(())
    }

    fn append_samples(&mut self, buffer: &AudioBufferRef) {
        match buffer {
            AudioBufferRef::F32(buf) => {
                // Mix down to mono if stereo
                let channels = buf.spec().channels.count();
                let frames = buf.frames();

                for frame_idx in 0..frames {
                    let mut sum = 0.0;
                    for ch in 0..channels {
                        sum += buf.chan(ch)[frame_idx];
                    }
                    self.samples.push(sum / channels as f32);
                }
            }
            AudioBufferRef::U8(buf) => {
                let channels = buf.spec().channels.count();
                let frames = buf.frames();

                for frame_idx in 0..frames {
                    let mut sum = 0.0;
                    for ch in 0..channels {
                        sum += (buf.chan(ch)[frame_idx] as f32 - 128.0) / 128.0;
                    }
                    self.samples.push(sum / channels as f32);
                }
            }
            AudioBufferRef::S16(buf) => {
                let channels = buf.spec().channels.count();
                let frames = buf.frames();

                for frame_idx in 0..frames {
                    let mut sum = 0.0;
                    for ch in 0..channels {
                        sum += buf.chan(ch)[frame_idx] as f32 / 32768.0;
                    }
                    self.samples.push(sum / channels as f32);
                }
            }
            AudioBufferRef::S32(buf) => {
                let channels = buf.spec().channels.count();
                let frames = buf.frames();

                for frame_idx in 0..frames {
                    let mut sum = 0.0;
                    for ch in 0..channels {
                        sum += buf.chan(ch)[frame_idx] as f32 / 2147483648.0;
                    }
                    self.samples.push(sum / channels as f32);
                }
            }
            _ => {}
        }
    }

    fn detect_beats(&self, threshold: f32) -> Vec<f64> {
        println!("Detecting beats with threshold {}...", threshold);

        let hop_size = 512;
        let window_size = 2048;

        let mut spectral_flux = Vec::new();
        let mut planner = FftPlanner::new();
        let fft = planner.plan_fft_forward(window_size);

        let mut prev_magnitude = vec![0.0; window_size / 2];

        // Calculate spectral flux for each window
        for i in (0..self.samples.len().saturating_sub(window_size)).step_by(hop_size) {
            let mut buffer: Vec<Complex<f32>> = self.samples[i..i + window_size]
                .iter()
                .enumerate()
                .map(|(j, &s)| {
                    // Apply Hann window
                    let window = 0.5
                        * (1.0
                            - (2.0 * std::f32::consts::PI * j as f32 / window_size as f32).cos());
                    Complex::new(s * window, 0.0)
                })
                .collect();

            fft.process(&mut buffer);

            // Calculate magnitude spectrum
            let magnitude: Vec<f32> = buffer[0..window_size / 2]
                .iter()
                .map(|c| c.norm())
                .collect();

            // Calculate spectral flux (increase in energy)
            let flux: f32 = magnitude
                .iter()
                .zip(prev_magnitude.iter())
                .map(|(m, pm)| (m - pm).max(0.0))
                .sum();

            spectral_flux.push((i, flux));
            prev_magnitude = magnitude;
        }

        // Normalize spectral flux
        let max_flux = spectral_flux
            .iter()
            .map(|(_, f)| f)
            .fold(0.0f32, |a, &b| a.max(b));
        if max_flux > 0.0 {
            for (_, flux) in &mut spectral_flux {
                *flux /= max_flux;
            }
        }

        // Detect peaks in spectral flux
        let mut beats = Vec::new();
        let min_beat_distance = (self.sample_rate as f32 * 0.1) as usize; // Minimum 100ms between beats
        let mut last_beat_sample = 0;

        for i in 1..spectral_flux.len() - 1 {
            let (sample_idx, flux) = spectral_flux[i];
            let (_, prev_flux) = spectral_flux[i - 1];
            let (_, next_flux) = spectral_flux[i + 1];

            // Check if this is a local maximum above threshold
            if flux > threshold && flux > prev_flux && flux > next_flux
                && sample_idx - last_beat_sample > min_beat_distance {
                    let time = sample_idx as f64 / self.sample_rate as f64;
                    beats.push(time);
                    last_beat_sample = sample_idx;
                }
        }

        println!("Detected {} beats", beats.len());
        beats
    }

    fn extract_amplitude_envelope(&self, target_sample_rate: f32) -> Vec<(f64, f32)> {
        println!(
            "Extracting amplitude envelope at {} Hz...",
            target_sample_rate
        );

        let window_size = (self.sample_rate as f32 / target_sample_rate) as usize;
        let mut envelope = Vec::new();

        for i in (0..self.samples.len()).step_by(window_size) {
            let end = (i + window_size).min(self.samples.len());
            let window = &self.samples[i..end];

            // Calculate RMS (Root Mean Square) for this window
            let rms: f32 =
                (window.iter().map(|&s| s * s).sum::<f32>() / window.len() as f32).sqrt();

            let time = i as f64 / self.sample_rate as f64;
            envelope.push((time, rms));
        }

        // Normalize envelope to 0-1 range
        let max_rms = envelope
            .iter()
            .map(|(_, rms)| rms)
            .fold(0.0f32, |a, &b| a.max(b));
        if max_rms > 0.0 {
            for (_, rms) in &mut envelope {
                *rms /= max_rms;
            }
        }

        println!("Extracted {} amplitude samples", envelope.len());
        envelope
    }

    fn save_beats(
        &self,
        beats: &[f64],
        output_path: &Path,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let mut file = File::create(output_path)?;

        writeln!(file, "# Beat timestamps (in seconds)")?;
        writeln!(file, "# Generated by audio-analyzer")?;
        writeln!(file, "# Total beats: {}", beats.len())?;
        writeln!(file)?;

        for &beat_time in beats {
            writeln!(file, "{:.3}", beat_time)?;
        }

        println!("Saved beat data to: {}", output_path.display());
        Ok(())
    }

    fn save_amplitude_envelope(
        &self,
        envelope: &[(f64, f32)],
        output_path: &Path,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let mut file = File::create(output_path)?;

        writeln!(file, "# Amplitude envelope data (time,amplitude)")?;
        writeln!(file, "# Generated by audio-analyzer")?;
        writeln!(file, "# Total samples: {}", envelope.len())?;
        writeln!(file)?;

        for &(time, amplitude) in envelope {
            writeln!(file, "{:.3},{:.4}", time, amplitude)?;
        }

        println!("Saved amplitude data to: {}", output_path.display());
        Ok(())
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    if !args.input.exists() {
        eprintln!("Error: Input file does not exist: {}", args.input.display());
        std::process::exit(1);
    }

    let output_dir = args
        .output
        .unwrap_or_else(|| args.input.parent().unwrap_or(Path::new(".")).to_path_buf());

    let file_stem = args.input.file_stem().unwrap().to_str().unwrap();
    let beats_path = output_dir.join(format!("{}.beats.txt", file_stem));
    let wave_path = output_dir.join(format!("{}.wave.dat", file_stem));

    println!("\n=== Audio Analyzer ===");
    println!("Input: {}", args.input.display());
    println!("Output directory: {}", output_dir.display());
    println!();

    let mut analyzer = AudioAnalyzer::new();
    analyzer.load_audio(&args.input)?;

    println!();
    let beats = analyzer.detect_beats(args.threshold);
    analyzer.save_beats(&beats, &beats_path)?;

    println!();
    let envelope = analyzer.extract_amplitude_envelope(args.sample_rate);
    analyzer.save_amplitude_envelope(&envelope, &wave_path)?;

    println!();
    println!("=== Analysis Complete ===");
    println!("Generated files:");
    println!("  - {}", beats_path.display());
    println!("  - {}", wave_path.display());
    println!();
    println!("Usage in LÖVE2D:");
    println!("  1. Copy these files to your assets/ folder");
    println!("  2. The game will automatically load them when you load the music");

    Ok(())
}
