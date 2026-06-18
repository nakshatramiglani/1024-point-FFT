`define WIDTH 16
`define SIZE 4
`define OUT_WIDTH (`WIDTH + 16)
`define HALF_WIDTH (`WIDTH / 2)


module twiddle_factors(output logic signed[15:0]twiddle_real[`HALF_WIDTH-1:0], 
                        output logic signed[15:0]twiddle_imag[`HALF_WIDTH-1:0]);
    initial begin
        twiddle_real[0] = 16'sd32767; twiddle_imag[0] = 16'sd0;
        twiddle_real[1] = 16'sd30274; twiddle_imag[1] = -16'sd12540;
        twiddle_real[2] = 16'sd23170; twiddle_imag[2] = -16'sd23170;
        twiddle_real[3] = 16'sd12540; twiddle_imag[3] = -16'sd30274;
        twiddle_real[4] = 16'sd0; twiddle_imag[4] = -16'sd32768;
        twiddle_real[5] = -16'sd12540; twiddle_imag[5] = -16'sd30274;
        twiddle_real[6] = -16'sd23170; twiddle_imag[6] = -16'sd23170;
        twiddle_real[7] = -16'sd30274; twiddle_imag[7] = -16'sd12540;  
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
            for (j = 0; j < `SIZE; j = j + 1)
                reversed_bits[j] = i[`SIZE-1-j];
            out[i] = in[reversed_bits];
        end
    end
endmodule

module add_sub(
    input signed [`OUT_WIDTH-1:0] in_real[`WIDTH-1:0],
    input signed [`OUT_WIDTH-1:0] in_imag[`WIDTH-1:0],
    output reg signed [`OUT_WIDTH-1:0] out_real[`WIDTH-1:0],
    output reg signed [`OUT_WIDTH-1:0] out_imag[`WIDTH-1:0]
);

    logic signed[15:0] twiddle_real[`HALF_WIDTH-1:0];
    logic signed[15:0] twiddle_imag[`HALF_WIDTH-1:0];

    twiddle_factors uut(twiddle_real, twiddle_imag);

    integer i, j, k, jump;
    reg [`SIZE-1:0] num; 

    reg signed [`OUT_WIDTH-1:0] inter1_real[`WIDTH-1:0];
    reg signed [`OUT_WIDTH-1:0] inter1_imag[`WIDTH-1:0];
    reg signed [`OUT_WIDTH-1:0] inter2_real[`WIDTH-1:0];
    reg signed [`OUT_WIDTH-1:0] inter2_imag[`WIDTH-1:0];

    task complex_multiply;

        input logic signed [15:0] mul1_real;
        input logic signed [15:0] mul1_imag;
        input logic signed [`OUT_WIDTH - 1:0] mul2_real;
        input logic signed [`OUT_WIDTH - 1:0] mul2_imag;
        output reg signed [`OUT_WIDTH - 1:0] out_real;
        output reg signed [`OUT_WIDTH - 1:0] out_imag;

        logic signed [`OUT_WIDTH + 15:0] temp_real;
        logic signed [`OUT_WIDTH + 15:0] temp_imag;

        begin

            temp_real = (mul1_real * mul2_real) - (mul1_imag * mul2_imag);
            temp_imag = (mul1_real * mul2_imag) + (mul1_imag * mul2_real);

            out_real = temp_real >>> 15;
            out_imag = temp_imag >>> 15;

        end

    endtask

    always @(*) begin
        for (i = 0; i < `SIZE; i = i + 1) begin
            num = 2**i;
            k = 0;
            jump = `HALF_WIDTH/num;

            for (j = 0; j < `WIDTH; j = j + 1) begin
                if (i != 0) begin 
                    if ((j & num) != 0) begin
                        k = (j % num) * jump;
                        if (i % 2 != 0) begin
                            complex_multiply(twiddle_real[k], twiddle_imag[k], inter1_real[j], inter1_imag[j], inter1_real[j], inter1_imag[j]);
                        end 
                        else begin
                            complex_multiply(twiddle_real[k], twiddle_imag[k], inter2_real[j], inter2_imag[j], inter2_real[j], inter2_imag[j]);
                        end
                    end
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
                        if ((j & num) == 0) begin
                            inter2_real[j] = inter1_real[j] + inter1_real[j + num];
                            inter2_imag[j] = inter1_imag[j] + inter1_imag[j + num];
                        end
                        else begin
                            inter2_real[j] = inter1_real[j - num] - inter1_real[j];
                            inter2_imag[j] = inter1_imag[j - num] - inter1_imag[j];
                        end
                    end
                    else
                        if ((j & num) == 0) begin
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