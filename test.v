`define WIDTH 8
`define SIZE 3

/*module bit_reversal(
    input [`SIZE-1:0] in[`WIDTH-1:0],
    output reg [`SIZE-1:0] out[`WIDTH-1:0]
);
  	integer i, j;
    always @(*) begin
        for (i = 0; i < `WIDTH; i = i + 1) begin
            for (j = 0; j < `SIZE; j = j + 1) begin
                out[i][j] = in[i][`SIZE-1-j]; 
            end
        end
    end
endmodule*/

module bit_reversal(
    input [`SIZE-1:0] in[`WIDTH-1:0],
    output reg [`SIZE-1:0] out[`WIDTH-1:0]
);
    integer i, j;
    reg [`SIZE-1:0] reversed_bits;
    always @(*) begin
        for (i = 0; i < `WIDTH; i = i + 1) begin
            for (j = 0; j < `SIZE; j = j + 1) begin
                reversed_bits[j] = in[i][`SIZE-1-j];
                if (reversed_bits == in[i])
                    out[i] = in[i];
                else
                    out[i] = in[reversed_bits];
            end
        end
    end
endmodule

module add_sub(
    input [`SIZE-1:0] in[`WIDTH-1:0],
    output reg [`SIZE-1:0] out[`WIDTH-1:0]
);
    integer i, j;
    reg minus;
    reg [`SIZE-1:0] num; 
    reg [`SIZE-1:0] inter1[`WIDTH-1:0];
    reg [`SIZE-1:0] inter2[`WIDTH-1:0];
    always @(*) begin
        minus = 1'b0;
        for (i = 0; i < `SIZE; i = i + 1) begin
            num = 2**i;
            for (j = 0; j < `WIDTH; j = j + 1) begin
                if (i == 0) begin
                    inter1[j] = (minus == 1'b0) ? in[j] + in[j+num] : in[j] - in[j+num];
                    minus = ~minus;
                end
                else begin
                    if (i % (2**i) == 0)
                        minus = ~minus;
                    if (i % 2 != 0)
                        inter2[j] = (minus == 1'b0) ? inter1[j] + inter1[j+num] : inter1[j] - inter1[j+num];
                    else
                        inter1[j] = (minus == 1'b0) ? inter2[j] + inter2[j+num] : inter2[j] - inter2[j+num];
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