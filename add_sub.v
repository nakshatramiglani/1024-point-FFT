module add_sub #(
    parameter DATA_WIDTH = 16
)(
    input clk,
    input  signed [DATA_WIDTH-1:0] in1_real,
    input  signed [DATA_WIDTH-1:0] in1_imag,
    input  signed [DATA_WIDTH-1:0] in2_real,
    input  signed [DATA_WIDTH-1:0] in2_imag,
    output reg signed [DATA_WIDTH:0] out1_real,
    output reg signed [DATA_WIDTH:0] out1_imag,
    output reg signed [DATA_WIDTH:0] out2_real,
    output reg signed [DATA_WIDTH:0] out2_imag
);

    reg signed [DATA_WIDTH-1:0] a_real;
    reg signed [DATA_WIDTH-1:0] a_imag;
    reg signed [DATA_WIDTH-1:0] b_real;
    reg signed [DATA_WIDTH-1:0] b_imag;

    always @(posedge clk) begin
        // STAGE 1
        a_real <= in1_real;
        a_imag <= in1_imag;
        b_real <= in2_real;
        b_imag <= in2_imag;
    end

    always @(posedge clk) begin
        // STAGE 2
        out1_real  <= a_real + b_real;
        out1_imag  <= a_imag + b_imag;
        out2_real  <= a_real - b_real;
        out2_imag  <= a_imag - b_imag;
    end

endmodule