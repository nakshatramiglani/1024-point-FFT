import json
import numpy as np

WIDTH = 1024

def main():
    print("Fetching Verilog output and MATLAB reference data...")
    try:
        with open("results/fft/output.json", 'r') as f:
            verilog_data = json.load(f)
    except FileNotFoundError:
        print("Error: Verilog output JSON not found.")
        return
    
    verilog_real = np.zeros(WIDTH+1)
    verilog_imag = np.zeros(WIDTH+1)

    try:
        with open("data/fft/ref.json", "r") as f:
            matlab_data = json.load(f)
    except FileNotFoundError:
        print("Error: MATLAB refernece JSON not found.")
        return
    
    matlab_real = np.zeros(WIDTH+1)
    matlab_imag = np.zeros(WIDTH+1)

    for i in range(1, WIDTH+1):
        key_in = f"in_{i}"
        key_out = f"out_{i}"
        if key_in in matlab_data:
            matlab_real[i] = matlab_data[key_in][0]
            matlab_imag[i] = matlab_data[key_in][1]
        else:
            print(f"Warning: Key {key_in} missing in MATLAB JSON.")
        if key_out in verilog_data:
            verilog_real[i] = verilog_data[key_out][0]
            verilog_imag[i] = verilog_data[key_out][1]
        else:
            print(f"Warning: Key {key_out} missing in Verilog JSON.")
    print("\nCalculating Error Metrics...")

    mse_real = np.mean((matlab_real - verilog_real)**2)
    mse_imag = np.mean((matlab_imag - verilog_imag)**2)
    
    rmse_real = np.sqrt(mse_real)
    rmse_imag = np.sqrt(mse_imag)
    
    max_err_real = np.max(np.abs(matlab_real - verilog_real))
    max_err_imag = np.max(np.abs(matlab_imag - verilog_imag))

    print("-" * 40)
    print(" FFT Verification Results ")
    print("-" * 40)
    print(f"Real Part MSE:  {mse_real:.6f}")
    print(f"Imag Part MSE:  {mse_imag:.6f}")
    print("-" * 40)
    print(f"Real Part RMSE: {rmse_real:.6f}")
    print(f"Imag Part RMSE: {rmse_imag:.6f}")
    print("-" * 40)
    print(f"Max Real Error: {max_err_real:.6f}")
    print(f"Max Imag Error: {max_err_imag:.6f}")
    print("-" * 40)

    print("\nCalculating Percentage Error...")
    
    matlab_magnitude = np.sqrt(matlab_real**2 + matlab_imag**2)
    peak_magnitude = np.max(matlab_magnitude)
    
    if peak_magnitude > 0:
        pct_error_real = (rmse_real / peak_magnitude) * 100
        pct_error_imag = (rmse_imag / peak_magnitude) * 100
    else:
        pct_error_real = 0.0
        pct_error_imag = 0.0
        
    print(f"Peak Signal Magnitude: {peak_magnitude:.2f}")
    print(f"Real Part % Error:     {pct_error_real:.6f}%")
    print(f"Imag Part % Error:     {pct_error_imag:.6f}%")
    print("-" * 40)

if __name__ == "__main__":
    main()