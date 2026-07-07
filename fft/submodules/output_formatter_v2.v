`timescale 1 ns / 1 ps

module zak_output_formatter #(
    parameter IN_WIDTH = 36,
    parameter FFT_WIDTH = 32 // the N in the M x N representation of the transform (depth of each bank)
) (
    // Control signals
    input logic clk,
    input logic rst_n,

    // Data inputs
    input logic signed [IN_WIDTH - 1:0] fft_in_real,
    input logic signed [IN_WIDTH - 1:0] fft_in_imag,
    input  logic [$clog2(FFT_WIDTH)-1:0] fft_sample_count,
    
    // Data outputs
    output logic signed [IN_WIDTH-1:0] zak_out_real,
    output logic signed [IN_WIDTH-1:0] zak_out_imag,
    output logic [$clog2(FFT_WIDTH)-1:0] zak_out_count
);

    localparam SCALING_FACTOR = $clog2(FFT_WIDTH);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            zak_out_real <= '0;
            zak_out_imag <= '0;
            zak_out_count <= '0;
        end
        else begin
            zak_out_real <= fft_in_real >>> SCALING_FACTOR;
            zak_out_imag <= fft_in_imag >>> SCALING_FACTOR;
            zak_out_count <= fft_sample_count;
        end
    end

endmodule