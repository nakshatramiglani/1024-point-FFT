import numpy as np

# 1. Robust File Loading (Ignores 'x' and slices trailing zeros)
valid_lines = []
with open("hardware_output.txt", "r") as f:
    for line in f:
        if 'x' not in line.lower() and 'z' not in line.lower():
            valid_lines.append([float(val) for val in line.split()])

hw_data = np.array(valid_lines)

if len(hw_data) > 1024:
    hw_data = hw_data[:1024]

hw_real = hw_data[:, 0]
hw_imag = hw_data[:, 1]
hw_complex = hw_real + 1j * hw_imag

in_data = np.arange(1024)

# 2. THE FIX: Use order='C' to simulate the round-robin Polyphase Demultiplexer
banks = in_data.reshape((32, 32), order='C') 

# 3. Simulate the 32-point FFT down the columns (axis=0)
fft_out = np.fft.fft(banks, axis=0)

# 4. Formatter Scaling
golden_model = fft_out / 32.0

# 5. Flatten column-by-column to match the Scheduler's output order
golden_stream = golden_model.flatten(order='F')

# 6. Automated Error Checking
difference = np.abs(golden_stream - hw_complex)
max_error = np.max(difference)

print(f"Maximum discrepancy between Verilog and Python: {max_error:.2f}")

if max_error < 2.0:  
    print("SUCCESS: Hardware perfectly matches the mathematical model!")
else:
    print("FAILED: Math mismatch detected.")