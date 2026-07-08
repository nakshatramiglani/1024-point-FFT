`timescale 1ns/1ps

module tb_zak_top;

    //--------------------------------------------------------
    // Parameters
    //--------------------------------------------------------
    localparam WIDTH      = 1024;
    localparam IN_WIDTH   = 36;
    localparam NUM_BANKS  = 32;
    localparam BANK_DEPTH = 32;

    //--------------------------------------------------------
    // Clock / Reset
    //--------------------------------------------------------
    logic clk;
    logic rst_n;

    initial clk = 1'b0;
    always #5 clk = ~clk; // 100 MHz Clock

    //--------------------------------------------------------
    // Signals
    //--------------------------------------------------------
    logic signed [IN_WIDTH-1:0] in_real;
    logic signed [IN_WIDTH-1:0] in_imag;

    wire signed [IN_WIDTH-1:0] out_real;
    wire signed [IN_WIDTH-1:0] out_imag;
    wire out_valid;

    //--------------------------------------------------------
    // DUT: Zak Top
    //--------------------------------------------------------
    zak_top #(
        .WIDTH(WIDTH),
        .IN_WIDTH(IN_WIDTH),
        .NUM_BANKS(NUM_BANKS),
        .BANK_DEPTH(BANK_DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_real(in_real),
        .in_imag(in_imag),
        .out_real(out_real),
        .out_imag(out_imag),
        .out_valid(out_valid)
    );

    //--------------------------------------------------------
    // File I/O Descriptor
    //--------------------------------------------------------
    integer file_handle;

    //--------------------------------------------------------
    // Stimulus
    //--------------------------------------------------------
    initial begin
        // 1. Open the file for writing ("w")
        file_handle = $fopen("hardware_output.txt", "w");
        if (file_handle == 0) begin
            $display("ERROR: Could not open hardware_output.txt for writing!");
            $finish;
        end

        // Initialize Inputs
        rst_n = 0;
        in_real = 0;
        in_imag = 0;

        repeat (10) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // Feed one complete frame (1024 samples)
        for (int i = 0; i < WIDTH; i++) begin
            in_real <= i; 
            in_imag <= 0;
            @(posedge clk);
        end

        in_real <= 0;
        in_imag <= 0;
        
        repeat (2000) @(posedge clk);

        // 2. Close the file before finishing the simulation
        $fclose(file_handle);
        $finish;
    end

    //--------------------------------------------------------
    // Output Monitor
    //--------------------------------------------------------
    integer samples_written = 0;
    always @(posedge clk) begin
        if (out_valid && !$isunknown(out_real) && samples_written < 1024) begin
            // 3. Write purely the raw numbers to the text file (space separated)
            $fdisplay(file_handle, "%0d %0d", out_real, out_imag);
            samples_written++;
            
            // Keep the console print so you can still watch the simulation run
            $display("Time: %10t | Valid Out -> Real: %8d | Imag: %8d", 
                     $time, out_real, out_imag);
        end
    end

    //--------------------------------------------------------
    // Waveform Dumping
    //--------------------------------------------------------
    initial begin
        $dumpfile("zak_top_waves.vcd");
        $dumpvars(0, tb_zak_top);
    end

endmodule