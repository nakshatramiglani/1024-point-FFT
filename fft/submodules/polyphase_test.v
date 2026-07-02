`timescale 1ns/1ps

module polyphase_demux_tb;

    // Parameters (Matching the DUT)
    localparam IN_WIDTH = 36;
    localparam NUM_BANKS = 4;
    localparam WIDTH = 1024;
    localparam BANK_DEPTH = 4;

    // DUT Signals
    logic clk;
    logic rst_n;
    logic signed [IN_WIDTH - 1:0] in_real;
    logic signed [IN_WIDTH - 1:0] in_imag;

    logic signed [IN_WIDTH - 1:0] broadcast_real;
    logic signed [IN_WIDTH - 1:0] broadcast_imag;
    logic [NUM_BANKS - 1:0] bank_we;
    logic [$clog2(BANK_DEPTH) - 1:0] bank_waddr;
    logic frame_done;
    logic [$clog2(WIDTH):0]counter;
    reg signed [35:0] i = 0;

    // Instantiate the Device Under Test (DUT)
    polyphase_demux #(
        .IN_WIDTH(IN_WIDTH),
        .NUM_BANKS(NUM_BANKS),
        .BANK_DEPTH(BANK_DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_real(in_real),
        .in_imag(in_imag),
        .broadcast_real(broadcast_real),
        .broadcast_imag(broadcast_imag),
        .bank_we(bank_we),
        .bank_waddr(bank_waddr),
        .frame_done(frame_done),
        .counter(counter)
    );

    // Clock Generation (100 MHz -> 10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // Stimulus Generation
    initial begin
        // Setup waveform dumping for viewing in GTKWave/Vivado
        $dumpfile("polyphase_demux_tb.vcd");
        $dumpvars(0, polyphase_demux_tb);

        // Initial State
        rst_n = 0;
        in_real = 0;
        in_imag = 0;

        // Apply Reset
        #25; 
        rst_n = 1;

        // Feed Continuous Data
        // A full frame is NUM_BANKS * BANK_DEPTH = 32 * 32 = 1024 samples.
        // We will feed 2100 samples to verify exactly two full frame completions 
        // and the start of a third frame.
        for (i = 0; i < 2100; i++) begin
            @(posedge clk);
            in_real <= i; 
            $display          // Increasing ramp for easy tracking
            in_imag <= -i;          // Decreasing ramp for I/Q distinction
        end

        // Wait a few cycles and finish
        #100;
        $display("Simulation complete.");
        $finish;
    end
endmodule