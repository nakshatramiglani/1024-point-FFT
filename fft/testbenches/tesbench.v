`timescale 1ns/1ps

module stage_tb;

    // =======================================================
    // Parameters (Configured for 32-bit Q17.15 Fractional Datapath)
    // =======================================================
    parameter WIDTH = 16;
    parameter IN_WIDTH = 32;       // Must be 32 to hold the shifted Q15 fractions
    parameter TWIDDLE_WIDTH = 16;
    parameter STAGE = 4;
    
    // Q15 scaling factor for converting to/from floats
    localparam SCALE = 32768.0; 

    // =======================================================
    // Signals
    // =======================================================
    logic clk;
    logic rst_n;

    logic signed [IN_WIDTH-1:0] in_real;
    logic signed [IN_WIDTH-1:0] in_imag;

    logic [$clog2(WIDTH)-1:0] sample_count;

    // Outputs are 32-bit to match your updated stage.v module
    logic signed [IN_WIDTH - 1:0] out_real;
    logic signed [IN_WIDTH - 1:0] out_imag;

    // =======================================================
    // DUT Instantiation
    // =======================================================
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

    // =======================================================
    // Clock Generation
    // =======================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz Clock
    end

    // =======================================================
    // VCD Dump Block (For GTKWave/ModelSim)
    // =======================================================
    initial begin
        $dumpfile("stage_tb.vcd");
        $dumpvars(0, stage_tb);
        $display("Dumping waveforms to stage_tb.vcd...\n");
    end

    // =======================================================
    // Output Monitor
    // =======================================================
    always @(posedge clk) begin
        // Only print when reset is high and the pipeline has valid data moving
        if(rst_n) begin
            $display("Time: %0t | count: %2d | In: (%8f, %8f) | Out: (%8f, %8f)",
                     $time,
                     sample_count,
                     real'(in_real) / SCALE,   // Convert internal 32-bit Q15 back to Float
                     real'(in_imag) / SCALE,
                     real'(out_real) / SCALE,  // Convert output 32-bit Q15 back to Float
                     real'(out_imag) / SCALE
            );
        end
    end

    // =======================================================
    // Stimulus Block
    // =======================================================
    integer i;

    initial begin
        // 1. Initialize Default State
        rst_n = 0;
        in_real = 0;
        in_imag = 0;
        sample_count = 0;

        // Wait a few clock cycles
        repeat(5) @(posedge clk);
        #1; // Offset slightly to avoid race conditions
        
        rst_n = 1;
        $display("--- Starting Stage 1 Pipeline Test ---");

        // 2. Feed a full frame of data (16 samples for WIDTH = 16)
        // We will feed a ramp signal (1.0, 2.0, 3.0...) to easily track it through the buffers.
        for(i = 0; i < WIDTH; i = i + 1) begin
            
            // Shift the integer 'i' left by 15 to convert it to Q15 hardware format!
            in_real <= (i << 15); 
            in_imag <= 0;
            sample_count <= i;
            
            @(posedge clk);
        end

        // 3. Flush the pipeline
        // The SDF stage 1 buffer delays by 8 cycles, and the adder/multiplier add 4 cycles.
        // We need to keep clocking to push the remaining data out.
        repeat(20) begin
            in_real <= 0;
            in_imag <= 0;
            // The sample count naturally wraps around in hardware, simulate that here
            sample_count <= (sample_count + 1) % WIDTH; 
            
            @(posedge clk);
        end

        $display("--- Test Complete ---");
        $finish;
    end

endmodule