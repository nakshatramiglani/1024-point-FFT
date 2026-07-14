import numpy as np

HW_FILE = "hardware_output.txt"
REF_FILE = "golden_reference.txt"


def load_complex_file(filename):
    real = []
    imag = []

    with open(filename, "r") as f:
        for line in f:
            line = line.strip()

            if line == "":
                continue

            tokens = line.split()

            if len(tokens) != 2:
                continue

            real.append(float(tokens[0]))
            imag.append(float(tokens[1]))

    return np.array(real), np.array(imag)


def main():

    print("Loading files...")

    hw_real, hw_imag = load_complex_file(HW_FILE)
    ref_real, ref_imag = load_complex_file(REF_FILE)

    if len(hw_real) != len(ref_real):
        print(f"ERROR: Different number of samples.")
        print(f"Hardware : {len(hw_real)}")
        print(f"Reference: {len(ref_real)}")
        return

    hw = hw_real + 1j * hw_imag
    ref = ref_real + 1j * ref_imag

    print(f"Loaded {len(hw)} samples.\n")

    print("=" * 110)
    print("First 20 Samples")
    print("=" * 110)
    print(
        f"{'Idx':>4} | {'Reference':>24} | {'Hardware':>24} | {'Complex Error':>24}"
    )
    print("-" * 110)

    for i in range(min(20, len(hw))):
        err = hw[i] - ref[i]

        print(
            f"{i:4d} | "
            f"({ref_real[i]:10.6f}, {ref_imag[i]:10.6f}) | "
            f"({hw_real[i]:10.6f}, {hw_imag[i]:10.6f}) | "
            f"({err.real:10.6f}, {err.imag:10.6f})"
        )

    print("=" * 110)

    error = hw - ref

    rmse = np.sqrt(np.mean(np.abs(error) ** 2))
    ref_rms = np.sqrt(np.mean(np.abs(ref) ** 2))

    nrmse = rmse / ref_rms
    evm = nrmse * 100

    max_abs_error = np.max(np.abs(error))
    mean_abs_error = np.mean(np.abs(error))

    epsilon = 1e-12
    percent_error = (
        np.abs(error) /
        (np.abs(ref) + epsilon)
    ) * 100

    rho = np.vdot(ref, hw) / (
        np.linalg.norm(ref) *
        np.linalg.norm(hw)
    )

    print("\n")
    print("=" * 60)
    print("Verification Results")
    print("=" * 60)

    print(f"Samples                 : {len(hw)}")
    print(f"Complex RMSE            : {rmse:.10f}")
    print(f"Reference RMS           : {ref_rms:.10f}")
    print(f"Normalized RMSE         : {nrmse:.10f}")
    print(f"EVM (%)                 : {evm:.8f}")
    print(f"Mean Absolute Error     : {mean_abs_error:.10f}")
    print(f"Maximum Absolute Error  : {max_abs_error:.10f}")
    print(f"Mean Percent Error (%)  : {np.mean(percent_error):.8f}")
    print(f"Max Percent Error (%)   : {np.max(percent_error):.8f}")
    print(f"Mean Real Error         : {np.mean(error.real):.10f}")
    print(f"Mean Imag Error         : {np.mean(error.imag):.10f}")
    print(f"Std Real Error          : {np.std(error.real):.10f}")
    print(f"Std Imag Error          : {np.std(error.imag):.10f}")
    print(f"Correlation Magnitude   : {abs(rho):.10f}")



if __name__ == "__main__":
    main()