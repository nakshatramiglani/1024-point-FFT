`timescale 1ns/1ps

module tb_zak_top;

    //--------------------------------------------------------
    // Parameters
    //--------------------------------------------------------
    localparam WIDTH      = 1024;
    localparam IN_WIDTH   = 32;
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
    integer samples_written = 0;

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
    // File I/O Descriptors
    //--------------------------------------------------------
    integer data_file;
    integer debug_file;

    //--------------------------------------------------------
    // Stimulus
    //--------------------------------------------------------
    initial begin
        // Open the files for writing
        data_file  = $fopen("hardware_output.txt", "w");
        debug_file = $fopen("zak_debug_log.txt", "w");
        
        if (data_file == 0) begin
            $display("ERROR: Could not open hardware_output.txt for writing!");
            $finish;
        end
        if (debug_file == 0) begin
            $display("ERROR: Could not open zak_debug_log.txt for writing!");
            $finish;
        end

        // Initialize Inputs
        rst_n = 0;
        in_real = 0;
        in_imag = 0;

        repeat (10) @(posedge clk);
        rst_n = 1;

        // Feed one complete frame (1024 samples)
        for (int i = 0; i < WIDTH; i++) begin
            in_real <= (i << 15); 
            in_imag <= 0;
            @(posedge clk);
        end

        in_real <= 0;
        in_imag <= 0;
        
        wait (samples_written == WIDTH);

        // Close the files before finishing the simulation
        $fclose(data_file);
        $fclose(debug_file);
        $finish;
    end

    //--------------------------------------------------------
    // Output Monitor (Original Data Logging)
    //--------------------------------------------------------
    always @(posedge clk) begin
        if (out_valid && !$isunknown(out_real) && samples_written < WIDTH) begin
            // Write purely the raw numbers to the text file (space separated)
            $fdisplay(data_file, "%0f %0f", real'(out_real) / 32768.0, real'(out_imag) / 32768.0);
            samples_written++;
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