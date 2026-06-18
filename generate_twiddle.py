import numpy as np

N = 16

for k in range(N // 2):
    theta = 2 * np.pi * k / N
    
    # Calculate continuous float values
    cos_val = np.cos(theta)
    sin_val = -np.sin(theta)
    
    # Scale to fixed-point Q15
    q15_real = int(round(cos_val * 32768))
    q15_imag = int(round(sin_val * 32768))
    
    # Saturate strictly to 16-bit signed limits [-32768, 32767]
    q15_real = max(min(q15_real, 32767), -32768)
    q15_imag = max(min(q15_imag, 32767), -32768)
    
    # Correct Verilog syntax formatting for negative numbers
    real_str = f"-16'sd{abs(q15_real)}" if q15_real < 0 else f"16'sd{q15_real}"
    imag_str = f"-16'sd{abs(q15_imag)}" if q15_imag < 0 else f"16'sd{q15_imag}"
    
    print(f"twiddle_real[{k}] = {real_str}; twiddle_imag[{k}] = {imag_str};")