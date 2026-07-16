`timescale 1 ns / 1 ps

`include "memory_bank.sv" 

module memory_bank_array #(
    parameter IN_WIDTH = 32,
    parameter NUM_BANKS = 32, 
    parameter BANK_DEPTH = 32 
)(
    input logic clk,
    input logic ping_pong_sel_w, 
    input logic ping_pong_sel_r, 

    input logic signed [IN_WIDTH - 1:0] in_real,
    input logic signed [IN_WIDTH - 1:0] in_imag,

    input logic [NUM_BANKS - 1:0] bank_we, 
    input logic [$clog2(BANK_DEPTH) - 1:0] bank_waddr, 

    input logic [$clog2(NUM_BANKS) - 1:0] bank_select, 
    input logic [$clog2(BANK_DEPTH) - 1:0] bank_raddr, 
    input logic [NUM_BANKS-1:0] bank_re, 

    output logic signed [IN_WIDTH - 1:0] out_real,
    output logic signed [IN_WIDTH - 1:0] out_imag
);

    logic signed [IN_WIDTH - 1:0] mem_out_real [0:NUM_BANKS - 1];
    logic signed [IN_WIDTH - 1:0] mem_out_imag [0:NUM_BANKS - 1];

    logic [$clog2(NUM_BANKS) - 1:0] bank_select_reg;
    always_ff @(posedge clk) begin
        bank_select_reg <= bank_select;
    end

    genvar i;
    generate
        for (i = 0; i < NUM_BANKS; i++) begin: gen_banks
            memory_bank #(
                .IN_WIDTH(IN_WIDTH),
                .BANK_DEPTH(BANK_DEPTH * 2) 
            ) bank_inst (
                .clk(clk),
                .in_real(in_real),
                .in_imag(in_imag),
                .we(bank_we[i]),
                .waddr({ping_pong_sel_w, bank_waddr}), 
                .re(bank_re[i]), 
                .raddr({ping_pong_sel_r, bank_raddr}), 
                .out_real(mem_out_real[i]),
                .out_imag(mem_out_imag[i])
            );
        end
    endgenerate

    always_comb begin
        out_real = mem_out_real[bank_select_reg];
        out_imag = mem_out_imag[bank_select_reg];
    end

endmodule