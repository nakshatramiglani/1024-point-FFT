`timescale 1ns/1ps

module fft_top_tb;

    parameter WIDTH = 32;
    parameter IN_WIDTH = 32;       
    parameter TWIDDLE_WIDTH = 16;
    
    // Using localparam real for Verilog compatibility
    localparam real SCALE = 32768.0; 

    // Calculate exact number of cycles needed to flush the pipeline
    localparam NUM_STAGES   = $clog2(WIDTH);
    localparam BUFFER_DELAY = WIDTH - 1;
    localparam MATH_DELAY   = 4 * NUM_STAGES;
    localparam PING_PONG    = WIDTH; 
    localparam READ_OUT     = WIDTH; 
    
    localparam FLUSH_CYCLES = BUFFER_DELAY + MATH_DELAY + 1;

    // Regs: Driven inside procedural blocks (initial/always)
    reg clk;
    reg rst_n;
    reg signed [IN_WIDTH-1:0] in_real;
    reg signed [IN_WIDTH-1:0] in_imag;
    reg [$clog2(WIDTH)-1:0] sample_count;

    // Wires: Driven by the DUT outputs
    wire signed [IN_WIDTH - 1:0] out_real;
    wire signed [IN_WIDTH - 1:0] out_imag;

    integer file_in;
    integer file_out;
    integer scan_result;
    integer i_file; // Explicit declaration for the file-loading loop
    integer i;      // Declaration for the stimulus loop

    // Reg arrays for memory storage
    reg signed [IN_WIDTH-1:0] input_real [0:WIDTH-1];
    reg signed [IN_WIDTH-1:0] input_imag [0:WIDTH-1];

    fft_top #(
        .WIDTH(WIDTH),
        .IN_WIDTH(IN_WIDTH),
        .TWIDDLE_WIDTH(TWIDDLE_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_real(in_real),
        .in_imag(in_imag),
        .sample_count(sample_count),
        .out_real(out_real),
        .out_imag(out_imag)
    );

    // Clock Generator
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // File I/O Initialization
    initial begin
        $dumpfile("fft_top_tb.vcd");
        $dumpvars(0, fft_top_tb);

        file_in = $fopen("data/input.txt", "r");
        if (file_in == 0) begin
            $display("Error: Input file not found.");
            $finish;
        end

        file_out = $fopen("results/output.json", "w");
        if (file_out == 0) begin
            $display("Error: Could not open output file.");
            $finish;
        end

        $fdisplay(file_out, "{");

        // Standard Verilog loop construct
        for (i_file = 0; i_file < WIDTH; i_file = i_file + 1) begin
            scan_result = $fscanf(file_in, "%d %d",
                                input_real[i_file],
                                input_imag[i_file]);

            if (scan_result != 2)
                $display("Warning: Incorrect input format on line %0d.", i_file);
        end

        $fclose(file_in);
    end

    integer sim_cycle = 0;

    localparam OUTPUT_START = BUFFER_DELAY + MATH_DELAY - 1;
    localparam OUTPUT_END = OUTPUT_START + WIDTH;

    // Monitor and JSON Output Generation
    always @(posedge clk) begin
        if(rst_n) begin
            sim_cycle = sim_cycle + 1;
            
            if (sim_cycle - 1 > OUTPUT_START && sim_cycle <= OUTPUT_END + 1) begin
                integer bin;
                bin = sim_cycle - OUTPUT_START - 1;

                if (bin != WIDTH) begin
                    $fdisplay(file_out, "    \"out_%0d\": [", bin);
                    // Replaced SystemVerilog real'(...) with Verilog-compliant $itor(...)
                    $fdisplay(file_out, "        %0f,", $itor(out_real)/SCALE);
                    $fdisplay(file_out, "        %0f", $itor(out_imag)/SCALE);
                    $fdisplay(file_out, "    ],");
                end
                else begin
                    $fdisplay(file_out, "    \"out_%0d\": [", bin);
                    $fdisplay(file_out, "        %0f,", $itor(out_real)/SCALE);
                    $fdisplay(file_out, "        %0f", $itor(out_imag)/SCALE);
                    $fdisplay(file_out, "    ]");
                end
            end
        end
    end

    // Stimulus Generation
    initial begin
        rst_n = 0;
        in_real = 0;
        in_imag = 0;
        sample_count = 0;

        repeat(5) @(posedge clk);
        #1; 
        
        rst_n = 1;
        
        // Feed Ramp Data
        for(i = 0; i < WIDTH; i = i + 1) begin
            in_real <= (input_real[i] << 15); 
            in_imag <= (input_imag[i] << 15);
            sample_count <= i;
            @(posedge clk);
        end

        // Flush pipeline
        repeat(FLUSH_CYCLES) begin
            in_real <= 0;
            in_imag <= 0;
            sample_count <= (sample_count + 1) % WIDTH; 
            @(posedge clk);
        end

        $fdisplay(file_out, "}");
        $fclose(file_out);
        $finish;
    end

endmodule