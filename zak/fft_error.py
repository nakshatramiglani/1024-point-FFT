import json
import numpy as np

WIDTH = 1024

def main():
    print("Fetching Verilog output and MATLAB reference data...")
    try:
        with open("results/output.json", 'r') as f:
            verilog_data = json.load(f)
    except FileNotFoundError:
        print("Error: Verilog output JSON not found.")
        return
    
    # Sized to exactly WIDTH (1024)
    verilog_real = np.zeros(WIDTH)
    verilog_imag = np.zeros(WIDTH)

    try:
        with open("data/ref.json", "r") as f:
            matlab_data = json.load(f)
    except FileNotFoundError:
        print("Error: MATLAB reference JSON not found.")
        return
    
    # Sized to exactly WIDTH (1024)
    matlab_real = np.zeros(WIDTH)
    matlab_imag = np.zeros(WIDTH)

    for i in range(1, WIDTH+1):
        key_in = f"in_{i}"
        key_out = f"out_{i}"
        
        # Shift to 0-based indexing by subtracting 1
        if key_in in matlab_data:
            matlab_real[i-1] = matlab_data[key_in][0]
            matlab_imag[i-1] = matlab_data[key_in][1]
        else:
            print(f"Warning: Key {key_in} missing in MATLAB JSON.")
            
        if key_out in verilog_data:
            verilog_real[i-1] = verilog_data[key_out][0]
            verilog_imag[i-1] = verilog_data[key_out][1]
        else:
            print(f"Warning: Key {key_out} missing in Verilog JSON.")
            
    print("\nCalculating Error Metrics...")

    # Construct complex-valued vectors
    matlab_complex = matlab_real + 1j * matlab_imag
    verilog_complex = verilog_real + 1j * verilog_imag

    print("\n" + "="*90)
    print("                     FIRST 20 FFT BINS COMPARISON")
    print("="*90)
    print(f"{'Bin':>4} | {'MATLAB (Re, Im)':>28} | {'Verilog (Re, Im)':>28} | {'Error (Re, Im)':>28}")
    print("-"*90)

    for i in range(20):
        err = verilog_complex[i] - matlab_complex[i]

        print(
            f"{i:4d} | "
            f"({matlab_real[i]:9.0f}, {matlab_imag[i]:9.0f}) | "
            f"({verilog_real[i]:9.0f}, {verilog_imag[i]:9.0f}) | "
            f"({err.real:9.0f}, {err.imag:9.0f})"
        )

    print("="*90)

    # Complex error vector
    error = verilog_complex - matlab_complex

    # RMSE
    rmse = np.sqrt(np.mean(np.abs(error) ** 2))

    # Reference RMS
    reference_rms = np.sqrt(np.mean(np.abs(matlab_complex) ** 2))

    # Normalized RMSE
    if reference_rms > 0:
        nrmse = rmse / reference_rms
    else:
        nrmse = 0.0

    # Percentage
    nrmse_percent = nrmse * 100

    # Additional useful metrics
    max_abs_error = np.max(np.abs(error))
    mean_abs_error = np.mean(np.abs(error))

    error = verilog_complex - matlab_complex

    print(np.mean(error))

    error = error - np.mean(error)
    # Add a tiny epsilon to prevent divide-by-zero in empty FFT bins
    epsilon = 1e-12 

    # Calculate magnitude percentage error per bin safely
    bin_percent_error = (np.abs(error) / (np.abs(matlab_complex) + epsilon)) * 100

    # Print the overall mean and maximum percentage errors
    print(f"Mean Bin Percentage Error : {np.mean(bin_percent_error):.6f}%")
    print(f"Max Bin Percentage Error  : {np.max(bin_percent_error):.6f}%")

    rmse = np.sqrt(np.mean(np.abs(error)**2))
    reference = np.sqrt(np.mean(np.abs(matlab_complex)**2))

    print(rmse/reference*100)

    print("Mean complex error :", np.mean(error))
    print("Mean real error    :", np.mean(error.real))
    print("Mean imag error    :", np.mean(error.imag))

    print("Std real error     :", np.std(error.real))
    print("Std imag error     :", np.std(error.imag))

    print("-" * 50)
    print(" FFT Verification Results ")
    print("-" * 50)
    print(f"Complex RMSE           : {rmse:.8f}")
    print(f"Reference RMS          : {reference_rms:.8f}")
    print(f"Normalized RMSE        : {nrmse:.8f}")
    print(f"Normalized RMSE (%)    : {nrmse_percent:.6f}%")
    print(f"Mean Absolute Error    : {mean_abs_error:.8f}")
    print(f"Maximum Absolute Error : {max_abs_error:.8f}")
    print("-" * 50)
    ratio = np.mean(np.abs(verilog_complex)) / np.mean(np.abs(matlab_complex))
    print(ratio)
    mag_ref = np.abs(matlab_complex)
    mag_fpga = np.abs(verilog_complex)

    mag_err = mag_fpga - mag_ref

    print("Mean magnitude error:", np.mean(mag_err))
    print("Std magnitude error :", np.std(mag_err))
    rho = np.vdot(matlab_complex, verilog_complex) / (
    np.linalg.norm(matlab_complex) * np.linalg.norm(verilog_complex)
    )
    print(abs(rho))
    evm = (
    np.sqrt(np.mean(np.abs(verilog_complex - matlab_complex)**2))
    / np.sqrt(np.mean(np.abs(matlab_complex)**2))
    ) * 100 
    print("EVM:", evm)

if __name__ == "__main__":
    main()