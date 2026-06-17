module testbench_tb;
    reg [2:0] A[7:0];
    wire [2:0] B[7:0];
    wire signed [23:0] out_real[7:0];
    wire signed [23:0] out_imag[7:0];
    reg signed [23:0] B_new_real[7:0];
    reg signed [23:0] B_new_imag[7:0];
    integer i;
    bit_reversal uut1(.in(A), .out(B));
    add_sub uut2(.in_real(B_new_real), .in_imag(B_new_imag), .out_real(out_real), .out_imag(out_imag));
    always @(*) begin
        for (i = 0; i < 8; i = i + 1) begin
            B_new_real[i] = $signed({21'b0, B[i]} <<< 15);
            B_new_imag[i] = 24'sd0;
        end
    end
    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, testbench_tb);
        $display("Test testbench");
        A[0] = 3'd0;
        A[1] = 3'd1;
        A[2] = 3'd2;
        A[3] = 3'd3;
        A[4] = 3'd4;
        A[5] = 3'd5;
        A[6] = 3'd6;
        A[7] = 3'd7;
        #10;
        $display("Bit reversal module");
        for (i = 0; i < 8; i = i + 1) begin
            $display("%b %b", A[i], B[i]);
        end
        $display("Add-Sub");
        for (i = 0; i < 8; i = i + 1) begin
            if ($itor($signed(out_imag[i])) < 0)
                $display("%0d + 0j : %.4f - %.4f j", B[i], $itor($signed(out_real[i])) / 32768.0, -$itor($signed(out_imag[i])) / 32768.0);
            else
                $display("%0d + 0j : %.4f + %.4f j", B[i], $itor($signed(out_real[i])) / 32768.0, $itor($signed(out_imag[i])) / 32768.0);
        end
    end
    
endmodule
