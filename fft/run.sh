#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Initialize variables
RANDOMIZE=0

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -r|--random) RANDOMIZE=1 ;;
        -h|--help) 
            echo "Usage: ./run_fft.sh [OPTIONS]"
            echo "Options:"
            echo "  -r, --random    Run generate_input.py to create new random inputs before simulating"
            echo "  -h, --help      Show this help message"
            exit 0 
            ;;
        *) 
            echo "Unknown parameter passed: $1"
            echo "Use --help for usage."
            exit 1 
            ;;
    esac
    shift
done

echo "========================================"
echo "      Starting FFT Verification Flow    "
echo "========================================"

# Step 1: Generate Inputs (if flag is set)
if [ $RANDOMIZE -eq 1 ]; then
    echo "[1/4] Generating new random input data..."
    python3 generate_input.py
else
    echo "[1/4] Skipping input generation (using existing data/fft/input.txt)..."
    echo "      Use the -r flag to generate new inputs."
fi

# Step 2: Compile and Run Verilog
echo ""
echo "[2/4] Compiling and Simulating Verilog..."
# Using -g2012 to support SystemVerilog features like always_comb and 2D array ports
iverilog -g2012 -I submodules -o test fft_pipelined.v fft-test.v

# Run the compiled simulation executable
vvp test

# Step 3: Run MATLAB Golden Reference
echo ""
echo "[3/4] Running MATLAB Golden Reference..."
# The -batch flag runs the script without opening the GUI and exits automatically
# Assuming your script is named fft_reference.m
/Applications/MATLAB_R2026a.app/bin/matlab -batch "fft_reference"

# Step 4: Run Python Error Calculation
echo ""
echo "[4/4] Calculating Error Metrics..."
python3 fft_error.py

echo "========================================"
echo "           Pipeline Complete!           "
echo "========================================"