`timescale 1 ns / 1 ps
`include "memory_bank.v"

module memory_bank_array #(
    parameter IN_WIDTH = 36,
    parameter NUM_BANKS = 32, // The M in the M x N representation
    parameter BANK_DEPTH = 32 // The N in the M x N representation
)(
    // Control signals
    input logic clk,
    input logic ping_pong_sel_w, // Driven by the polyphase_demux / write controller
    input logic ping_pong_sel_r, // Driven by the new scheduler module

    // Data inputs
    input logic signed [IN_WIDTH - 1:0] in_real,
    input logic signed [IN_WIDTH - 1:0] in_imag,

    // Write interface
    input logic [NUM_BANKS - 1:0] bank_we, 
    input logic [$clog2(BANK_DEPTH) - 1:0] bank_waddr, 

    // Read interface
    input logic [$clog2(NUM_BANKS) - 1:0] bank_select, 
    input logic [$clog2(BANK_DEPTH) - 1:0] bank_raddr, 
    input logic [NUM_BANKS-1:0] bank_re, 

    // Data outputs
    output logic signed [IN_WIDTH - 1:0] out_real,
    output logic signed [IN_WIDTH - 1:0] out_imag
);

    // Internal arrays to capture outputs from all instantiated memory banks
    logic signed [IN_WIDTH - 1:0] mem_out_real [0:NUM_BANKS - 1];
    logic signed [IN_WIDTH - 1:0] mem_out_imag [0:NUM_BANKS - 1];

    /*
    The memory_bank module has a read latency of 1 clock cycle. 
    Hence, the select signal is pipelined in order to align it with the delayed output data.
    */
    logic [$clog2(NUM_BANKS) - 1:0] bank_select_reg;
    always_ff @(posedge clk) begin
        bank_select_reg <= bank_select;
    end

    // Instantiate NUM_BANKS banks
    genvar i;
    generate
        for (i = 0; i < NUM_BANKS; i++) begin: gen_banks
            memory_bank #(
                .IN_WIDTH(IN_WIDTH),
                .BANK_DEPTH(BANK_DEPTH * 2) // Doubles the bank depth for ping-pong buffering
            ) bank_inst (
                .clk(clk),
                .in_real(in_real),
                .in_imag(in_imag),
                .we(bank_we[i]),
                .waddr({ping_pong_sel_w, bank_waddr}), // Write side address space
                .re(bank_re[i]), 
                .raddr({ping_pong_sel_r, bank_raddr}), // Read side address space (driven independently)
                .out_real(mem_out_real[i]),
                .out_imag(mem_out_imag[i])
            );
        end
    endgenerate

    // Multiplex the final output based on the pipelined select signal
    assign out_real = mem_out_real[bank_select_reg];
    assign out_imag = mem_out_imag[bank_select_reg];

endmodule