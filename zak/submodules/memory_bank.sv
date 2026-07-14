`timescale 1 ns / 1 ps

// Note: This module creates a single block of dual-port RAM. It will be instantiated NUM_BANKS times in memory_bank_array.

module memory_bank #(
    parameter IN_WIDTH = 36,
    parameter BANK_DEPTH = 32 // the N in the M x N representation of the transform (depth of each bank)
)(
    // Control signals
    input logic clk,

    // Data inputs
    input logic signed [IN_WIDTH - 1:0] in_real,
    input logic signed [IN_WIDTH - 1:0] in_imag,

    // Write port
    input logic we,
    input logic [$clog2(BANK_DEPTH) - 1:0] waddr,

    // Read port | Data is available one clock cycle after 're' and 'raddr' are asserted.
    input logic re,
    input logic [$clog2(BANK_DEPTH) - 1:0] raddr,
    
    // Outputs
    output logic signed [IN_WIDTH - 1:0] out_real,
    output logic signed [IN_WIDTH - 1:0] out_imag

);

    logic signed [IN_WIDTH - 1:0] mem_real [0:BANK_DEPTH - 1];
    logic signed [IN_WIDTH - 1:0] mem_imag [0:BANK_DEPTH - 1];

    always_ff @(posedge clk) begin
        // Write port
        if (we) begin
            mem_real[waddr] <= in_real;
            mem_imag[waddr] <= in_imag;
        end

        // Read port
        if (re) begin
            out_real <= mem_real[raddr];
            out_imag <= mem_imag[raddr];
        end
    end

endmodule