`define WIDTH 8
`define SIZE 3
`define DATA_WIDTH 8
`define OUT_WIDTH 24
`define HALF_WIDTH (`DATA_WIDTH / 2)

module twiddle_factors(output logic signed[15:0]twiddle_real[3:0], 
                        output logic signed[15:0]twiddle_imag[3:0]);
    initial begin
        twiddle_real[0] = 16'sd32767;
        twiddle_real[1] = 16'sd23170;
        twiddle_real[2] = 16'sd0;
        twiddle_real[3] = -16'sd23170;
        twiddle_imag[0] = 16'sd0;
        twiddle_imag[1] = -16'sd23170;
        twiddle_imag[2] = -16'sd32767;
        twiddle_imag[3] =  -16'sd23170;
    end

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
    output reg [`OUT_WIDTH-1:0] out_real[`WIDTH-1:0],
    output reg [`OUT_WIDTH-1:0] out_imag[`WIDTH-1:0]
);
    logic signed[15:0]twiddle_real[3:0];
    logic signed[15:0]twiddle_imag[3:0];
    twiddle_factors uut(twiddle_real, twiddle_imag);
    integer i, j, k, jump;
    reg [`SIZE-1:0] num; 
    reg [`DATA_WIDTH-1:0] inter1_real[`WIDTH-1:0];
    reg [`DATA_WIDTH-1:0] inter1_imag[`WIDTH-1:0];
    reg [`DATA_WIDTH-1:0] inter2_real[`WIDTH-1:0];
    reg [`DATA_WIDTH-1:0] inter2_imag[`WIDTH-1:0];
    task complex_multiply;
        input logic signed [15:0] mul1_real;
        input logic signed [15:0] mul1_imag;
        input logic signed [`DATA_WIDTH:0] mul2_real;
        input logic signed [`DATA_WIDTH:0] mul2_imag;
        output logic signed [17+`DATA_WIDTH:0] out_real;
        output logic signed [17+`DATA_WIDTH:0] out_imag;
        begin
            out_real = (mul1_real * mul2_real) - (mul1_imag * mul2_imag);
            out_imag = (mul1_real * mul2_imag) + (mul1_imag * mul2_real);
        end
    endtask
    always @(*) begin
        for (i = 0; i < `SIZE; i = i + 1) begin
            num = 2**i;
            k = 0;
            jump = `HALF_WIDTH/num;
            for (j=0; j<`WIDTH; j= j + 1) begin
                if (i != 0) begin 
                    if (i % 2 != 0) begin
                        complex_multiply(twiddle_real[k], twiddle_imag[k], inter1_real[j], inter1_imag[j], inter1_real[j], inter1_imag[j]);
                    end 
                    else begin
                        complex_multiply(twiddle_real[k], twiddle_imag[k], inter2_real[j], inter2_imag[j], inter2_real[j], inter2_imag[j]);
                    end
                    k = k + jump; 
                    if (k >= `HALF_WIDTH) k = 0;
                end
            end
            for (j = 0; j < `WIDTH; j = j + 1) begin
                if (i == 0) begin
                    if ((j & num) == 0) begin
                        inter1_real[j] = in_real[j] + in_real[j + num];
                        inter1_imag[j] = in_imag[j] + in_imag[j + num];
                    end
                    else begin
                        inter1_real[j] = in_real[j - num] - in_real[j];
                        inter1_imag[j] = in_imag[j - num] - in_imag[j];
                    end
                end
                else begin
                    if (i % 2 != 0) begin
                        if ((j & num == 0)) begin
                            inter2_real[j] = inter1_real[j] + inter1_real[j + num];
                            inter2_imag[j] = inter1_imag[j] + inter1_imag[j + num];
                        end
                        else begin
                            inter2_real[j] = inter1_real[j - num] - inter1_real[j];
                            inter2_imag[j] = inter1_imag[j - num] - inter1_imag[j];
                        end
                    end
                    else
                        if ((j & num == 0)) begin
                            inter1_real[j] = inter2_real[j] + inter2_real[j + num];
                            inter1_imag[j] = inter2_imag[j] + inter2_imag[j + num];
                        end
                        else begin
                            inter1_real[j] = inter2_real[j - num] - inter2_real[j];
                            inter1_imag[j] = inter2_imag[j - num] - inter2_imag[j];
                        end
                end
            end
        end
        for (i = 0; i < `WIDTH; i = i + 1) begin
            if (`SIZE % 2 == 0) begin
                out_real[i] = inter2_real[i];
                out_imag[i] = inter2_imag[i];
            end else begin
                out_real[i] = inter1_real[i];
                out_imag[i] = inter1_imag[i];
            end
        end
    end
endmodule

