# First Order Ambisonic Sound Processing Research Project

## Overview
This repository contains the research project on **First Order Ambisonic (FOA) sound processing algorithms** developed during an internship at Universidad Politécnica de Madrid (UPM) from February to June 2025, in collaboration with professor Rubén Fraile.

The project explores the theoretical foundations of First Order Ambisonics and implements three distinct experiments to analyze spatial audio processing, direction of arrival (DOA) estimation, and virtual microphone beamforming techniques.

## Project Structure

### Main Scripts

1. **`Virtual_Mic_DOA_Experiment.m`** - First experiment
2. **`Virtual_Mic_DOA_Different_Sources_fullband_analysis.m`** - Second experiment (part 1)
3. **`Virtual_Mic_DOA_Different_Sources_frequency_bands_analysis.m`** - Second experiment (part 2)
4. **`FOA_playback_pipeline.m`**  - Third experiment


### Utility Functions (`utils/`)
- `compute_doa.m` - Direction of arrival calculation
- `rotation_over_a_plane.m` - 3D rotation computations for virtual microphone steering
- `draw_3D_representation.m` - 3D visualization of spatial audio setup
- `draw_powerometer.m` - Power level visualization
- `ShortTermPower.m` - Short-term power analysis
- Additional geometric and visualization utilities

## Experiments

### Experiment 1: Virtual Microphone DOA Analysis
**Script:** `Virtual_Mic_DOA_Experiment.m`

- **Objective:** Simulate a virtual figure-of-eight microphone oriented in arbitrary directions using FOA recordings.
- **Data:** Phone ringing recordings from 6 spatial positions (`sounds/first_experiment/`), tracked in 3D via OptiTrack.
- **Key Features:**
  - DOA estimation via 3D tracking and coordinate transformation
  - Virtual microphone rotation on a defined plane (Rodrigues' formula)
  - Power computation across orientations to evaluate directivity
  - Real-time 3D animation, dynamic power meter, and polar plot visualization


### Experiment 2: Multi-Source DOA Analysis (Fullband & Frequency Bands)
**Scripts:**  
- `Virtual_Mic_DOA_Different_Sources_fullband_analysis.m`  
- `Virtual_Mic_DOA_Different_Sources_frequency_bands_analysis.m`

- **Objective:** Compare directional behavior of various Foley sound sources using a virtual figure-of-eight microphone.
- **Data:** Normalized 4-channel FOA recordings of multiple sources (`sounds/second_experiment/all_sources_norm/`)
  - Includes: throat clear, door slam, typing, keys jangling, knocking, page turn, phone ring, speech
- **Preprocessing:** `norm_foley.m` – power normalization preserving directivity.
- **Analysis:**
  - **Fullband:** Power computed across full frequency range, plotted per source over 360° rotation.
  - **Frequency bands:** Low (20–500 Hz), mid (500–2000 Hz), high (2–8 kHz) – each filtered and analyzed separately.
- **Output:** Polar power plots comparing directional response across sources and bands.


### Experiment 3: FOA Playback Pipeline
**Script:** `FOA_playback_pipeline.m`

- **Objective:** Full First-Order Ambisonic (FOA) encoding, processing, and decoding for loudspeaker playback.
- **Data:** 4 cardioid mic recordings in tetrahedral configuration + OptiTrack loudspeaker coordinates.
- **Pipeline:**
  1. **Encoding:** Convert raw mic signals to FOA (W, X, Y, Z)
  2. **Processing:** Apply per-channel gains for spatial clarity
  3. **Decoding:** Map FOA signals to 4 loudspeakers using direction vectors
- **Output:** 4-channel decoded audio for Ableton playback + visualization of energy distribution
- **Applications:** Spatial audio, immersive playback, VR/AR audio rendering



## Data Organization

```
sounds/
├── first_experiment/          # Phone ringing tests (6 positions)
│   └── phone_ringing_test_1-6/
├── second_experiment/         # Multi-source Foley analysis
│   ├── cropped_foley/         # Original Foley sounds
│   ├── cropped_normalized_foley/  # Power-normalized versions
│   └── all_sources_norm/      # Ambisonic recordings of each source
└── third_experiment/          # Additional test recordings
```

## Requirements

- **MATLAB** (tested with recent versions)
- **Audio System Toolbox** (for filter design)
- **Signal Processing Toolbox**


## Academic Context

This work was conducted as part of an internship research program at Universidad Politécnica de Madrid (UPM), focusing on advanced spatial audio processing techniques and their practical implementation in MATLAB.

**Supervisor:** Professor Rubén Fraile  
**Institution:** Universidad Politécnica de Madrid (UPM)  
**Period:** February - June 2025
