`define WIDTH 8
`define SIZE 3
`define DATA_WIDTH 8
`define OUT_WIDTH 24

module twiddle (
    output logic signed [15:0] twiddle_real [0:3],
    output logic signed [15:0] twiddle_imag [0:3]
);

    assign twiddle_real[0] = 16'sd32767;
    assign twiddle_real[1] = 16'sd23170;
    assign twiddle_real[2] = 16'sd0;
    assign twiddle_real[3] = -16'sd23170;

    assign twiddle_imag[0] = 16'sd0;
    assign twiddle_imag[1] = -16'sd23170;
    assign twiddle_imag[2] = -16'sd32767;
    assign twiddle_imag[3] = -16'sd23170;

endmodule

module complex_multiply(
    input logic signed [15:0] mul1_real,
    input logic signed [15:0] mul1_imag,
    input logic [`DATA_WIDTH:0] mul2_real,
    input logic [`DATA_WIDTH:0] mul2_imag,
    output logic signed [15+`DATA_WIDTH:0] out_real,
    output logic signed [15+`DATA_WIDTH:0] out_imag
);
    assign out_real = mul1_real * mul2_real + mul1_imag * mul2_imag;
    assign out_imag = mul1_real * mul2_imag + mul1_imag * mul2_real;
endmodule

module bit_reversal(
    input [`SIZE-1:0] in[`WIDTH-1:0],
    output reg [`SIZE-1:0] out[`WIDTH-1:0]
);
    integer i, j;
    reg [`SIZE-1:0] reversed_bits;
    always @(*) begin
        for (i = 0; i < `WIDTH; i = i + 1) begin
            for (j = 0; j < `SIZE; j = j + 1) begin
                reversed_bits[j] = i[`SIZE-1-j];
                if (reversed_bits == in[i])
                    out[i] = in[i];
                else
                    out[i] = in[reversed_bits];
            end
        end
    end
endmodule

module add_sub(
    input [`DATA_WIDTH-1:0] in_real[`WIDTH-1:0],
    input [`DATA_WIDTH-1:0] in_imag[`WIDTH-1:0],
    output reg [`OUT_WIDTH-1:0] out[`WIDTH-1:0]
);

    integer i, j;
    reg [`SIZE-1:0] num; 
    reg [`DATA_WIDTH-1:0] inter1_real[`WIDTH-1:0];
    reg [`DATA_WIDTH-1:0] inter1_imag[`WIDTH-1:0];
    reg [`DATA_WIDTH-1:0] inter2_real[`WIDTH-1:0];
    reg [`DATA_WIDTH-1:0] inter2_imag[`WIDTH-1:0];

    always @(*) begin
        for (i = 0; i < `SIZE; i = i + 1) begin
            num = 2**i;
            for (j = 0; j < `WIDTH; j = j + 1) begin
                if (i == 0) begin
                    inter1[j] = ((j & num) == 0) ? in[j] + in[j+num] : in[j-num] - in[j];
                end
                else begin
                    if (i % 2 != 0)
                        inter2[j] = ((j & num) == 0) ? inter1[j] + inter1[j+num] : inter1[j-num] - inter1[j];
                    else
                        inter1[j] = ((j & num) == 0) ? inter2[j] + inter2[j+num] : inter2[j-num] - inter2[j];
                end
            end
        end
        for (i = 0; i < `WIDTH; i = i + 1) begin
            if (`SIZE % 2 == 0)
                out[i] = inter2[i];
            else
                out[i] = inter1[i];
        end
    end
    
endmodule

