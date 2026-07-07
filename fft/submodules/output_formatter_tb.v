`timescale 1ns/1ps

module tb_fft_formatter;

    //--------------------------------------------------------
    // Parameters
    //--------------------------------------------------------
    localparam WIDTH          = 32;
    localparam IN_WIDTH       = 36;
    localparam TWIDDLE_WIDTH  = 16;

    //--------------------------------------------------------
    // Clock / Reset
    //--------------------------------------------------------
    logic clk;
    logic rst_n;

    initial clk = 1'b0;
    always #2.5 clk = ~clk;

    //--------------------------------------------------------
    // FFT Inputs
    //--------------------------------------------------------
    logic signed [IN_WIDTH-1:0] in_real;
    logic signed [IN_WIDTH-1:0] in_imag;
    logic [$clog2(WIDTH)-1:0] in_sample_count;

    //--------------------------------------------------------
    // FFT Outputs
    //--------------------------------------------------------
    wire signed [IN_WIDTH-1:0] fft_out_real;
    wire signed [IN_WIDTH-1:0] fft_out_imag;
    wire [$clog2(WIDTH)-1:0] fft_out_count;

    //--------------------------------------------------------
    // Formatter Outputs
    //--------------------------------------------------------
    wire signed [IN_WIDTH-1:0] zak_out_real;
    wire signed [IN_WIDTH-1:0] zak_out_imag;
    wire out_valid;

    //--------------------------------------------------------
    // DUT : FFT
    //--------------------------------------------------------
    fft_top #(
        .WIDTH(WIDTH),
        .IN_WIDTH(IN_WIDTH),
        .TWIDDLE_WIDTH(TWIDDLE_WIDTH)
    ) dut_fft (

        .clk(clk),
        .rst_n(rst_n),

        .in_real(in_real),
        .in_imag(in_imag),
        .sample_count(in_sample_count),

        .out_real(fft_out_real),
        .out_imag(fft_out_imag),
        .out_sample_count(fft_out_count)
    );

    //--------------------------------------------------------
    // DUT : Output Formatter
    //--------------------------------------------------------
    output_formatter #(
        .IN_WIDTH(IN_WIDTH),
        .FFT_WIDTH(WIDTH)
    ) dut_formatter (

        .clk(clk),
        .rst_n(rst_n),

        .fft_in_real(fft_out_real),
        .fft_in_imag(fft_out_imag),
        .fft_sample_count(fft_out_count),

        .zak_out_real(zak_out_real),
        .zak_out_imag(zak_out_imag),
        .out_valid(out_valid)
    );

    //--------------------------------------------------------
    // Stimulus
    //--------------------------------------------------------

    initial begin

        rst_n = 0;
        in_real = 0;
        in_imag = 0;
        in_sample_count = 0;

        // Hold reset
        repeat (5) @(negedge clk);
        rst_n = 1;

        // Feed four continuous FFT frames
        for (int frame = 0; frame < 4; frame++) begin

            $display("\n==============================");
            $display("Sending Frame %0d", frame);
            $display("==============================");

            for (int i = 0; i < WIDTH; i++) begin

                in_real         = i;
                in_imag         = 0;
                in_sample_count = i;
                @(negedge clk);

            end
        
        end

        for (int i = 0; i < 10; i++) begin
            in_real         = 0;
            in_imag         = 0;
            in_sample_count = i % WIDTH; // Continues 0 to 31 loop
            @(negedge clk);
        end

        // Stop driving
        @(negedge clk);
        in_real = 0;
        in_imag = 0;
        in_sample_count = 0;

        // Flush pipeline
        repeat (200)
            @(posedge clk);

        $display("\nSimulation Complete.");
        $finish;

    end

    //--------------------------------------------------------
    // Output Monitor
    //--------------------------------------------------------

    always @(posedge clk) begin

        if (out_valid)
            $display("%2d  %d  %d",
             dut_formatter.read_count_out,
             zak_out_real,
             zak_out_imag);

    end

    //--------------------------------------------------------
    // Waveforms
    //--------------------------------------------------------

    initial begin

        $dumpfile("zak_pipeline_test.vcd");
        $dumpvars(0,tb_fft_formatter);

    end

endmodule