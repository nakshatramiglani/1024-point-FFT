# 1024-Point Fixed-Point FFT Hardware Implementation

This repository contains the hardware design, simulation testbench, and complete automated verification pipeline for a 1024-point Radix-2 Fast Fourier Transform (FFT). The core is implemented in Verilog using 16-bit Q15 fixed-point arithmetic and is verified against a 64-bit floating-point MATLAB golden reference.

## Repository Structure

* **`data/fft/`**: Contains generated input test vectors (`input.txt`) and reference JSONs.
* **`results/fft/`**: Destination folder for simulation outputs (`output.json`).
* **`fft.v`**: The core Verilog RTL implementing the bit-reversal and butterfly add/sub modules.
* **`fft-test.v`**: The Verilog testbench that handles file I/O and Q-format shifting.
* **`fft_reference.m`**: The MATLAB golden reference script that computes the ideal FFT and exports the results for comparison.
* **`fft_error.py`**: Python verification script that compares Verilog hardware outputs against the MATLAB reference to calculate Mean Squared Error (MSE) and Root Mean Squared Error (RMSE).
* **`generate_input.py`**: Python script to generate real/imaginary test vectors (e.g., sine waves or white noise).
* **`generate_twiddle.py`**: Python script to pre-calculate and generate the 16-bit two's complement twiddle factors (`.hex` files).
* **`run.sh`**: The master bash script that automates the entire generation, simulation, and verification pipeline.
* **`tasks.md`**: Project tracking and to-do lists.
* **`.gitignore`**: Git ignore rules for simulation binaries and temporary data files.

## Prerequisites

To run the full automated verification pipeline, ensure the following are installed and added to your system `PATH`:

* **Icarus Verilog (`iverilog` & `vvp`)**: For compiling and simulating the RTL.
* **MATLAB** (or GNU Octave): For generating the golden reference data.
* **Python 3.x**: For test vector generation and error calculation.
    * Required pip package: `numpy`

## Usage

The entire simulation and verification flow is automated via the `run.sh` shell script.

### Standard Verification Run

To run the Verilog simulation using the existing data in `data/fft/input.txt`, followed by the MATLAB reference and Python error calculation:

```bash
chmod +x run.sh
./run.sh
```

### Randomized Stress Test

To generate a completely new set of randomized complex inputs before running the simulation pipeline, use the `-r` (or `--random`) flag:

```bash
./run.sh -r
```

## Verification Methodology

1.  **Stimulus Generation:** `generate_input.py` creates 1024 lines of complex base-10 integers.
2.  **Hardware Simulation:** The Verilog testbench (`fft-test.v`) reads the text inputs, injects them into the fixed-point FFT core, and writes the scaled results to a JSON file.
3.  **Golden Reference:** `fft_reference.m` processes the exact same input file using double-precision floating-point arithmetic and exports the ideal results.
4.  **Error Analysis:** `fft_error.py` parses both output sets and calculates the quantization noise. Due to the 16-bit fractional truncation inherent in the hardware butterfly stages, a small but non-zero RMSE (typically < 10 units for large signals) is expected and mathematically validates the fixed-point precision.
