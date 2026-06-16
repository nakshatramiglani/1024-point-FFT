module bit_reversal_tb;
    reg [2:0] A[7:0];
    wire [2:0] B[7:0];
    wire [2:0] out[7:0];
    integer i;
    bit_reversal uut1(.in(A), .out(B));
    add_sub uut2(.in(B), .out(out));
    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, bit_reversal_tb);
        $display("Test testbench");
        A = '{3'b000, 3'b001, 3'b010, 3'b011, 3'b100, 3'b101, 3'b110, 3'b111};
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