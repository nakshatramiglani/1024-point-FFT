module bit_reversal_tb;
    reg [2:0] A[7:0];
    wire [2:0] B[7:0];
    wire [7:0] out[7:0];
    reg [7:0] B_new[7:0];
    integer i;
    bit_reversal uut1(.in(A), .out(B));
    add_sub uut2(.in(B_new), .out(out));
    always @(*) begin
        for (i = 0; i < 8; i = i + 1) begin
            B_new[i] = {5'b0, B[i]};
        end
    end
    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, bit_reversal_tb);
        $display("Test testbench");
        A = '{3'd7, 3'd6, 3'd5, 3'd4, 3'd3, 3'd2, 3'd1, 3'd0};
        #10;
        $display("Bit reversal module");
        for (i = 0; i < 8; i = i + 1) begin
            $display("%b %b", A[i], B[i]);
        end
        $display("Add-sub module");
        for (i = 0; i < 8; i = i + 1) begin
            $display("%b %b", B[i], out[i]);
        end
    end
    
endmodule