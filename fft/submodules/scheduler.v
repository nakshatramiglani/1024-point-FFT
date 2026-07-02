module scheduler#(
    parameter IN_WIDTH = 36,
    parameter WIDTH = 1024,
    parameter NUM_BANKS = 32, // the M in the MxN representation of the transform (number of banks)
    parameter BANK_DEPTH = 32 // the N in the MxN representation of the transform (depth of each bank)
)(
    input logic clk,
    input logic rst_n,
    //input logic ready 
    input signed [IN_WIDTH - 1:0] in_real,
    input signed [IN_WIDTH - 1:0] in_imag,
    input [$clog2(WIDTH) - 1:0] count

    // Outputs to the ping-pong memory banks
    output reg signed [IN_WIDTH - 1:0] out_real,
    output reg signed [IN_WIDTH - 1:0] out_imag,
    output reg [NUM_BANKS - 1:0] bank_we, // One-hot write enable
    output reg [$clog2(BANK_DEPTH) - 1:0] bank_waddr, // Shared write address for all banks
    );

     
endmodule