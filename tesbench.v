`timescale 1ns/1ps

module stage_tb;

    parameter WIDTH = 16;
    parameter IN_WIDTH = 16;
    parameter TWIDDLE_WIDTH = 16;
    parameter STAGE = 1;

    logic clk;
    logic rst_n;

    logic signed [IN_WIDTH-1:0] in_real;
    logic signed [IN_WIDTH-1:0] in_imag;

    logic [$clog2(WIDTH)-1:0] sample_count;

    logic signed [IN_WIDTH:0] out_real;
    logic signed [IN_WIDTH:0] out_imag;

    //----------------------------------------------------------
    // DUT
    //----------------------------------------------------------

    stage #(
        .WIDTH(WIDTH),
        .IN_WIDTH(IN_WIDTH),
        .TWIDDLE_WIDTH(TWIDDLE_WIDTH),
        .STAGE(STAGE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_real(in_real),
        .in_imag(in_imag),
        .sample_count(sample_count),
        .out_real(out_real),
        .out_imag(out_imag)
    );


    //----------------------------------------------------------
    // Clock
    //----------------------------------------------------------

    initial clk = 0;
    always #5 clk = ~clk;

    //----------------------------------------------------------
    // Dump waves
    //----------------------------------------------------------

    initial begin
        $dumpfile("stage_tb.vcd");
        $dumpvars(0,stage_tb);
        $display("Dumping waves to stage_tb.vcd");
    end

    //----------------------------------------------------------
    // Monitor
    //----------------------------------------------------------

    always @(posedge clk) begin
        if(rst_n) begin
            $display("T=%0t  cnt=%0d  in=(%0d,%0d)  out=(%0d,%0d)",
                     $time,
                     sample_count,
                     in_real,
                     in_imag,
                     out_real,
                     out_imag);
        end
    end

    //----------------------------------------------------------
    // Stimulus
    //----------------------------------------------------------

    integer i;

    initial begin

        rst_n = 0;
        in_real = 0;
        in_imag = 0;
        sample_count = 0;

        repeat(5) @(posedge clk);

        rst_n = 1;

        // Feed WIDTH samples
        for(i=0;i<WIDTH;i=i+1) begin

            @(posedge clk);

            sample_count <= i;
            in_real <= i;
            in_imag <= 0;

        end

        // Continue clocking to flush pipeline
        repeat(20) begin
            @(posedge clk);
            sample_count <= sample_count + 1;
            in_real <= 0;
            in_imag <= 0;
        end

        $finish;

    end

endmodule