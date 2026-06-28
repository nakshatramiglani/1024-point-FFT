`timescale 1ns/1ps

module fft_top_tb;

    parameter WIDTH = 1024;
    parameter IN_WIDTH = 36;       
    parameter TWIDDLE_WIDTH = 16;
    
    localparam SCALE = 32768.0; 

    // Calculate exact number of cycles needed to flush the pipeline
    localparam NUM_STAGES   = $clog2(WIDTH);
    localparam BUFFER_DELAY = WIDTH - 1;
    localparam MATH_DELAY   = 4 * NUM_STAGES;
    localparam PING_PONG    = WIDTH; // Wait for frame to buffer
    localparam READ_OUT     = WIDTH; // Wait for frame to stream out
    
    localparam FLUSH_CYCLES = BUFFER_DELAY + MATH_DELAY + PING_PONG + READ_OUT;

    logic clk;
    logic rst_n;
    logic signed [IN_WIDTH-1:0] in_real;
    logic signed [IN_WIDTH-1:0] in_imag;
    logic [$clog2(WIDTH)-1:0] sample_count;

    logic signed [IN_WIDTH - 1:0] out_real;
    logic signed [IN_WIDTH - 1:0] out_imag;

    integer file_in;
    integer file_out;
    integer scan_result;

    logic signed [IN_WIDTH-1:0] input_real [0:WIDTH-1];
    logic signed [IN_WIDTH-1:0] input_imag [0:WIDTH-1];

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

    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    initial begin
        $dumpfile("testbenches/fft_top_tb.vcd");
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

        for (int i = 0; i < WIDTH; i++) begin
            scan_result = $fscanf(file_in, "%d %d",
                                input_real[i],
                                input_imag[i]);

            if (scan_result != 2)
                $display("Warning: Incorrect input format on line %0d.", i);
        end

        $fclose(file_in);
    end

    integer sim_cycle = 0;

    localparam OUTPUT_START = BUFFER_DELAY + MATH_DELAY + PING_PONG;
    localparam OUTPUT_END = OUTPUT_START + WIDTH;

    always @(posedge clk) begin
        if(rst_n) begin
            sim_cycle++;
            // 1. Display Inputs ONLY while the ramp data is being fed
            if (sim_cycle <= WIDTH) begin
                $display("Time: %0t | IN  | Count: %2d | Val: (%8f, %8f)",
                         $time, sample_count, 
                         real'(in_real) / SCALE, real'(in_imag) / SCALE);
            end
            
            // 2. Display Outputs ONLY when the valid FFT frame emerges
            if (sim_cycle - 1 > OUTPUT_START && sim_cycle <= OUTPUT_END + 1) begin
                integer bin;
                bin = sim_cycle - OUTPUT_START - 1;

                if (bin != WIDTH) begin
                    $fdisplay(file_out,
                        "    \"out_%0d\": [", bin);
                    $fdisplay(file_out,
                        "        %0f,", real'(out_real)/SCALE);
                    $fdisplay(file_out,
                        "        %0f", real'(out_imag)/SCALE);
                    $fdisplay(file_out,
                        "    ],");
                end
                else begin
                    $fdisplay(file_out,
                        "    \"out_%0d\": [", bin);
                    $fdisplay(file_out,
                        "        %0f,", real'(out_real)/SCALE);
                    $fdisplay(file_out,
                        "        %0f", real'(out_imag)/SCALE);
                    $fdisplay(file_out,
                        "    ]");
                end
            end
        end
    end

    integer i;
    initial begin
        rst_n = 0;
        in_real = 0;
        in_imag = 0;
        sample_count = 0;

        repeat(5) @(posedge clk);
        #1; 
        
        rst_n = 1;
        
        // Feed 16-point Ramp Data
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