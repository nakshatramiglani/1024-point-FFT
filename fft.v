`include "complex_multiply.v"
`include "add_sub.v"
`include "twiddle_fetch.v"
`include "buffers.v"

module fft #(
    parameter WIDTH = 16,
    parameter DATA_WIDTH = 16,
    parameter TWIDDLE_WIDTH = 16
)(
    input logic clk,
    input logic rst_n,

    input logic signed [DATA_WIDTH-1:0] in_real,
    input logic signed [DATA_WIDTH-1:0] in_imag,

    output logic signed [FFT_WIDTH-1:0] out_real,
    output logic signed [FFT_WIDTH-1:0] out_imag
);

localparam SIZE      = $clog2(WIDTH);
localparam FFT_WIDTH = DATA_WIDTH + SIZE;

//generating all buffers
generate
    for(i=0; i<SIZE; i=i+1) begin : DELAYS
        buffer #(.DEPTH(1 << i), .DATA_WIDTH(FFT_WIDTH - i))
        buff_inst(
            .clk(clk),
            .rst_n(rst_n),
            .in_real(in_real),
            .in_imag(in_imag),
            .delayed_real(delayed_real),
            .delayed_imag(delayed_imag)
        );
    end
endgenerate;

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_real <= 0;
        out_imag <= 0;
    end else begin
    end
end

endmodule