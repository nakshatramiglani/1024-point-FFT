import random

# FFT Parameters
WIDTH = 1024
MAX_AMPLITUDE = 1000  # Safe range to prevent overflow during butterfly additions

with open("input.txt", "w") as f:
    for i in range(WIDTH):
        # Generate random integers for both real and imaginary parts
        real_val = random.randint(-MAX_AMPLITUDE, MAX_AMPLITUDE)
        imag_val = random.randint(-MAX_AMPLITUDE, MAX_AMPLITUDE)
        
        # Write to file in "real imag" decimal format
        f.write(f"{real_val} {imag_val}\n")

print(f"Generated input_data.txt with {WIDTH} lines of random complex noise.")