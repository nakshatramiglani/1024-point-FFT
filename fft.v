`timescale 1 ns / 1 ps

`define WIDTH 1024
`define SIZE 10
`define HALF_WIDTH (`WIDTH / 2)

`define DATA_WIDTH 32
`define TWIDDLE_WIDTH 16

`define OUT_WIDTH (`DATA_WIDTH + `TWIDDLE_WIDTH - 1 + `SIZE)

`include "complex_multiply.v"
`include "fft_pipelined.v"
`include "twiddle_fetch.v"
`include "buffers.v"

module fft(
    input 
    input signed [`OUT_WIDTH-1:0] in_real[`WIDTH-1:0],
    input signed [`OUT_WIDTH-1:0] in_imag[`WIDTH-1:0],
    output reg signed [`OUT_WIDTH-1:0] out_real[`WIDTH-1:0],
    output reg signed [`OUT_WIDTH-1:0] out_imag[`WIDTH-1:0]
);



endmodule