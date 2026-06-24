`include "complex_multiply.v"
`include "add_sub.v"
`include "twiddle_fetch.v"
`include "buffers.v"

module stage #(
    parameter WIDTH = 16,
    parameter IN_WIDTH = 16,
    parameter TWIDDLE_WIDTH = 16,
    parameter STAGE = 1 //stages start from 1
)(
    input logic clk,
    input logic rst_n,
    input logic signed [IN_WIDTH-1:0] in_real,
    input logic signed [IN_WIDTH-1:0] in_imag,
    input logic [$clog2(WIDTH) - 1:0] sample_count,

    output logic signed [FFT_WIDTH-1:0] out_real,
    output logic signed [FFT_WIDTH-1:0] out_imag
);

localparam SIZE       = $clog2(WIDTH);
localparam DATA_WIDTH = IN_WIDTH + STAGE - 1;
localparam FFT_WIDTH  = DATA_WIDTH + SIZE;
localparam DELAY = 1 << (SIZE - STAGE);

wire signed [DATA_WIDTH-1:0] delay_in_real;
wire signed [DATA_WIDTH-1:0] delay_in_imag;

wire signed [DATA_WIDTH-1:0] delayed_real;
wire signed [DATA_WIDTH-1:0] delayed_imag;

wire signed [TWIDDLE_WIDTH - 1:0] twiddle_real;
wire signed [TWIDDLE_WIDTH - 1:0] twiddle_imag;

logic [SIZE - 2:0] angle_idx;

wire signed [DATA_WIDTH-1:0] in_even_real;
wire signed [DATA_WIDTH-1:0] in_even_imag;

wire signed [DATA_WIDTH-1:0] odd_real;
wire signed [DATA_WIDTH-1:0] odd_imag;

wire signed [DATA_WIDTH-1:0] multiplied_real;
wire signed [DATA_WIDTH-1:0] multiplied_imag;

wire signed [DATA_WIDTH:0] added_real;
wire signed [DATA_WIDTH:0] added_imag;

wire signed [DATA_WIDTH:0] subtracted_real;
wire signed [DATA_WIDTH:0] subtracted_imag;

assign angle_idx = sample_count << (STAGE - 1);

//generating all buffers
    buffer #(.DEPTH(DELAY), .DATA_WIDTH(DATA_WIDTH))
        buff_inst(
            .clk(clk),
            .nrst(rst_n),
            .in_real(delay_in_real),
            .in_imag(delay_in_imag),
            .delayed_real(delayed_real),
            .delayed_imag(delayed_imag)
    );

//generate twiddle factors
    twiddle_factors #(
        .WIDTH(WIDTH),
        .TWIDDLE_WIDTH(TWIDDLE_WIDTH)
    ) twiddle_inst(
        .clk(clk),
        .rst_n(rst_n),
        .angle_idx(angle_idx),
        .twiddle_real(twiddle_real),
        .twiddle_imag(twiddle_imag)
    );

//multiply twiddle factor with even input
    complex_multiply #(.FFT_WIDTH(DATA_WIDTH))
        cmplx_mult_inst(
            .clk(clk),
            .rst_n(rst_n),
            .mul1_real(twiddle_real),
            .mul1_imag(twiddle_imag),
            .mul2_real(in_even_real),
            .mul2_imag(in_even_imag),
            .out_real(multiplied_real),
            .out_imag(multiplied_imag)
    );

//add and subtract the even and odd inputs
    add_sub #(.DATA_WIDTH(DATA_WIDTH))
        addsub_inst(
            .clk(clk),
            .in1_real(odd_real),
            .in1_imag(odd_imag),
            .in2_real(delayed_real),
            .in2_imag(delayed_imag),
            .out1_real(added_real),
            .out1_imag(added_imag),
            .out2_real(subtracted_real),
            .out2_imag(subtracted_imag)
    );
endmodule