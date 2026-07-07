# 1024-Point Pipelined Fixed-Point FFT (Verilog/FPGA)

![Language: Verilog](https://img.shields.io/badge/Language-Verilog-blue.svg)
![Language: Python](https://img.shields.io/badge/Language-Python-green.svg)
![Language: MATLAB](https://img.shields.io/badge/Language-MATLAB-orange.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

A streaming, fully-pipelined **1024-point radix-2 Decimation-in-Frequency FFT core** written in synthesizable Verilog/SystemVerilog, built around a **Single-path Delay Feedback (SDF)** butterfly architecture. The design uses **16-bit Q15 fixed-point twiddle factors** with a **wider 36-bit internal datapath** to preserve precision across all 10 pipeline stages, and is verified end-to-end against a double-precision MATLAB golden reference through a fully automated Python/MATLAB/Verilog co-simulation pipeline.

## Table of Contents
- [Architecture](#architecture)
- [Features](#features)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Verification Methodology](#verification-methodology)
- [Design Notes](#design-notes)
- [Contributors](#contributors)

## Architecture

The core (`fft_top` in `fft_pipelined.v`) instantiates `NUM_STAGES = log2(WIDTH) = 10` cascaded `stage` modules via a Verilog `generate` loop, followed by a final reordering block:

```
in_real/in_imag ──▶ [Stage 1] ─▶ [Stage 2] ─▶ ... ─▶ [Stage 10] ──▶ [Bit-Reversal] ──▶ out_real/out_imag
```

**Each butterfly stage** (`submodules/stage.v`) implements an SDF commutator:
- A circular delay **buffer** (`submodules/buffers.v`) of depth `N / 2^stage`, with combinational reads, holds samples until their butterfly partner arrives.
- A `sample_count`-driven `switch` bit selects between feeding the add/sub unit (`submodules/add_sub.v`) and routing data straight through a second feedback buffer.
- The "sum" path (no twiddle needed) and "difference" path (multiplied by a twiddle factor) recombine through a registered, depth-matched delay chain so every stage adds a fixed, analytically-computed latency.
- A `complex_multiply` unit (`submodules/complex_multiply.v`) performs the twiddle multiply using the 4-real-multiplier method, with rounding and a `>>> (TWIDDLE_WIDTH-1)` rescale back to Q15.

**Twiddle factors** are generated offline (`generate_twiddle.py`) as 16-bit two's-complement Q15 hex values, but only **one quarter of the table (`N/4` entries) is stored in ROM** — `submodules/twiddle_fetch.v` reconstructs the full table at runtime using the symmetry `cos/sin(θ + 90°)` quadrant swap, cutting twiddle ROM size by 4x.

**Output reordering** (`submodules/bit-reversal.v`) uses **ping-pong (double-buffered) distributed RAM**: one bank is written in natural order while the other is read out in bit-reversed order, so the core can stream continuous back-to-back frames without stalling.

## Features
- **Fully pipelined, streaming datapath** — accepts a new complex sample every clock cycle; no control FSM or start/done handshake required.
- **Parameterized for any power-of-2 length** — `WIDTH`, `IN_WIDTH`, and `TWIDDLE_WIDTH` are Verilog parameters; stage count and all delay/buffer depths are derived automatically via `$clog2`.
- **Memory-efficient twiddle ROM** — exploits quarter-wave trigonometric symmetry to store only `N/4` complex coefficients instead of `N`.
- **Guard-bit fixed-point datapath** — 36-bit internal word width prevents bit growth/overflow from accumulating across 10 cascaded butterfly stages, while twiddle multiplication still rounds back to a 16-bit Q15 result each stage.
- **Continuous-flow output reordering** — double-buffered RAM bit-reversal stage with zero added stall cycles between frames.
- **Fully automated, self-checking verification pipeline** — one shell command runs RTL simulation, golden-reference generation, and quantitative error analysis.
- **Randomized stress testing** — a `-r` flag regenerates bounded random complex test vectors for regression/Monte-Carlo-style verification.

## Repository Structure

| File / Directory | Description |
| :--- | :--- |
| 📄 `fft/fft_pipelined.v` | Top-level `fft_top` module — instantiates and pipelines all FFT stages plus the bit-reversal output stage. |
| 📁 `fft/submodules/` | `stage.v` (SDF butterfly), `add_sub.v`, `complex_multiply.v`, `twiddle_fetch.v`, `buffers.v` (circular delay line), `bit-reversal.v` (ping-pong reorder RAM). |
| 📄 `fft/fft-test.v` | Top-level testbench: reads `data/input.txt`, drives the DUT cycle-by-cycle, and writes results to `results/output.json`. |
| 📄 `fft/fft_reference.m` | MATLAB golden-reference script — runs double-precision `fft()` on the same input file and exports `data/ref.json`. |
| 📄 `fft/fft_error.py` | Computes MSE, RMSE, max absolute error, and % error (relative to peak signal magnitude) between RTL and golden-reference outputs. |
| 📄 `fft/generate_input.py` | Generates 1024 lines of bounded random complex integer test vectors (`data/input.txt`). |
| 📄 `fft/generate_twiddle.py` | Pre-computes the `N/4` Q15 twiddle coefficients and writes them as `.hex` ROM init files. |
| 📁 `fft/data/` | `input.txt` (stimulus), `ref.json` (MATLAB reference), `twiddles_real.hex` / `twiddles_imag.hex` (ROM contents). |
| 📁 `fft/results/` | `output.json` — RTL simulation output, consumed by `fft_error.py`. |
| 📄 `fft/run.sh` | Master automation script chaining stimulus generation → Verilog sim → MATLAB reference → Python error analysis. |
| 📄 `tasks.md` | Project task tracking / roadmap. |

## Prerequisites

* **Icarus Verilog** (`iverilog` & `vvp`) — RTL compilation/simulation (uses `-g2012` for SystemVerilog constructs like `always_comb` and 2D array ports).
* **MATLAB** (or GNU Octave) — golden-reference generation.
* **Python 3.x** with `numpy` — stimulus generation and error analysis.

## Usage

```bash
chmod +x fft/run.sh
cd fft

# Standard run — uses existing data/input.txt
./run.sh

# Randomized stress test — regenerates input.txt with new random vectors first
./run.sh -r
```

`run.sh` performs, in order:
1. *(optional)* `generate_input.py` — new random stimulus.
2. `iverilog -g2012 -I submodules -o test fft_pipelined.v fft-test.v && vvp test` — compiles and simulates the RTL.
3. MATLAB `fft_reference.m` — computes the floating-point golden reference.
4. `fft_error.py` — compares the two outputs and reports error metrics.

## Verification Methodology

1. **Stimulus generation** — `generate_input.py` writes 1024 bounded random complex integers (`±10,000`) to avoid overflow in the butterfly adders.
2. **RTL simulation** — `fft-test.v` streams every sample into the DUT, with `FLUSH_CYCLES` analytically pre-computed from the architecture's buffer/math/ping-pong/readout latencies so the testbench knows exactly when valid output begins.
3. **Golden reference** — `fft_reference.m` runs MATLAB's double-precision `fft()` on the identical input file.
4. **Error analysis** — `fft_error.py` reports MSE, RMSE, max absolute error, and RMSE as a percentage of peak signal magnitude, quantifying the quantization noise introduced by 16-bit fixed-point arithmetic.

## Design Notes

- The SDF butterfly relies on a `sample_count`-derived `switch` signal and a chain of delayed copies (`switch_d1`–`switch_d4`) to align the add/sub mux selection with the multi-cycle latency of the adder and twiddle-multiply paths.
- `complex_multiply.v` registers all four partial products before combining them, trading one extra pipeline cycle for better timing closure at synthesis.
- Memories (`buffer`, twiddle ROM, bit-reversal RAM) are tagged `(* ram_style="distributed" *)`, targeting LUT-based distributed RAM rather than block RAM — appropriate given their relatively small, irregular access patterns.

## Contributors
* **[@thehacktivist42](https://github.com/thehacktivist42)**
* **[@nakshatramiglani](https://github.com/nakshatramiglani)**
