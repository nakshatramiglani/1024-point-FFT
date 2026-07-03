`timescale 1 ns / 1 ps

module tb_polyphase_transpose;

    // Parameters matching the system setup
    localparam IN_WIDTH   = 36;
    localparam NUM_BANKS  = 32; // M columns
    localparam BANK_DEPTH = 32; // N rows
    localparam WIDTH      = NUM_BANKS * BANK_DEPTH; // 1024 total elements
    
    // Testbench Control Parameter
    localparam NUM_FRAMES = 3;  // Test continuous back-to-back streaming
    localparam TOTAL_ELEM = WIDTH * NUM_FRAMES;

    // Clock and Reset
    logic clk;
    logic rst_n;

    // Inputs to the Streaming Matrix Setup
    logic signed [IN_WIDTH-1:0] in_real;
    logic signed [IN_WIDTH-1:0] in_imag;

    // Interconnect Wires
    logic signed [IN_WIDTH-1:0] broadcast_real;
    logic signed [IN_WIDTH-1:0] broadcast_imag;
    logic [NUM_BANKS-1:0]        bank_we;
    logic [$clog2(BANK_DEPTH)-1:0] bank_waddr;
    logic [$clog2(WIDTH):0]      counter;
    logic                        frame_done;

    logic [$clog2(NUM_BANKS)-1:0] bank_select;
    logic [$clog2(BANK_DEPTH)-1:0] bank_raddr;
    logic [NUM_BANKS-1:0]        bank_re;
    logic                        valid_out;

    logic signed [IN_WIDTH-1:0]  out_real;
    logic signed [IN_WIDTH-1:0]  out_imag;

    // 1. Instantiate the Polyphase Demultiplexer
    polyphase_demux #(
        .IN_WIDTH(IN_WIDTH),
        .WIDTH(WIDTH),
        .NUM_BANKS(NUM_BANKS),
        .BANK_DEPTH(BANK_DEPTH)
    ) u_demux (
        .clk(clk),
        .rst_n(rst_n),
        .in_real(in_real),
        .in_imag(in_imag),
        .broadcast_real(broadcast_real),
        .broadcast_imag(broadcast_imag),
        .bank_we(bank_we),
        .bank_waddr(bank_waddr),
        .counter(counter),
        .frame_done(frame_done)
    );

    // 2. Instantiate the Scheduler
    scheduler u_scheduler (
        .clk(clk),
        .rst_n(rst_n),
        .counter(counter),
        .bank_select(bank_select),
        .bank_raddr(bank_raddr),
        .bank_re(bank_re),
        .valid_out(valid_out)
    );

    // 3. Instantiate the Memory Array
    memory_bank_array #(
        .IN_WIDTH(IN_WIDTH),
        .NUM_BANKS(NUM_BANKS),
        .BANK_DEPTH(BANK_DEPTH)
    ) u_mem_array (
        .clk(clk),
        .in_real(broadcast_real),
        .in_imag(broadcast_imag),
        .bank_we(bank_we),
        .bank_waddr(bank_waddr),
        .bank_select(bank_select),
        .bank_raddr(bank_raddr),
        .bank_re(bank_re),
        .out_real(out_real),
        .out_imag(out_imag)
    );

    // Clock Generator (100MHz / 10ns period)
    always #5 clk = ~clk;

    // Simulation Verification Variables
    int write_count = 0;
    int read_count  = 0;
    int errors      = 0;
    
    logic signed [IN_WIDTH-1:0] expected_real;
    int current_frame;
    int frame_offset;
    int local_read_count;
    int exp_row, exp_col;

    // Stimulus Generation
    initial begin
        // Initialize Inputs
        clk     = 1'b0;
        rst_n   = 1'b0;
        in_real = '0;
        in_imag = '0;

        // Apply Reset
        #20;
        @(posedge clk);
        rst_n = 1'b1;
        $display("[TB INFO] Reset released. Beginning streaming %0d back-to-back frames...", NUM_FRAMES);

        // Stream continuous unique data entries for NUM_FRAMES
        for (int f = 0; f < NUM_FRAMES; f++) begin
            for (int i = 0; i < WIDTH; i++) begin
                // Data equals absolute index across all frames to ensure no stale data is read
                in_real = (f * WIDTH) + i;
                in_imag = -((f * WIDTH) + i); 
                @(posedge clk);
                write_count++;
            end
        end
        
        // Zero out inputs after all frames are sent
        in_real = '0;
        in_imag = '0;

        // Allow system to finish processing the scheduled readouts 
        while (read_count < TOTAL_ELEM) begin
            @(posedge clk);
            // Safety timeout step (adjusted for multiple frames)
            if ($time > (TOTAL_ELEM * 20 + 20000)) begin
                $display("[TB ERROR] Simulation Timeout! Pipeline stalled.");
                break;
            end
        end

        // Final Report Evaluation
        #50;
        $display("\n========================================================");
        $display("                  SIMULATION REPORT                     ");
        $display("========================================================");
        $display("Total Frames Processed    : %0d", NUM_FRAMES);
        $display("Total Samples Streamed In : %0d", write_count);
        $display("Total Samples Read Out    : %0d", read_count);
        $display("Total Error Mismatches    : %0d", errors);
        $display("========================================================");
        
        if (errors == 0 && read_count == TOTAL_ELEM) begin
            $display(">>> SUCCESS: Continuous 2D Matrix Transpose Works Perfectly! <<<");
        end else begin
            $display(">>> FAILURE: Output stream contains errors or missed elements. <<<");
        end
        $display("========================================================\n");
        $finish;
    end

    // Real-Time Self-Checking Scoreboard Logic
    always @(posedge clk) begin
        if (rst_n && valid_out) begin
            
            // 1. Determine which frame we are evaluating
            current_frame    = read_count / WIDTH;
            frame_offset     = current_frame * WIDTH;
            
            // 2. Determine local element index within the current frame (0 to 1023)
            local_read_count = read_count % WIDTH;

            // 3. Derive 2D coordinates for a column-first sweep
            exp_row = local_read_count % BANK_DEPTH;
            exp_col = local_read_count / BANK_DEPTH;
            
            // 4. Map 2D coordinate backwards to original linear write sequence + frame offset
            expected_real = frame_offset + (exp_row * NUM_BANKS) + exp_col;

            // Assert output data validities
            if (out_real !== expected_real) begin
                $display("[MISMATCH ERROR] Frame %0d, Output #%0d! Matrix[%0d][%0d] | Expected: %0d, Received: %0d", 
                         current_frame, local_read_count, exp_row, exp_col, expected_real, out_real);
                errors++;
            end else if (local_read_count % 256 == 0 || local_read_count == WIDTH - 1) begin
                // Sample periodic logs to stdout to show active progress per frame
                $display("[VALIDATION MATCH] Frame %0d, Output #%0d matched Matrix[%0d][%0d] = %0d", 
                         current_frame, local_read_count, exp_row, exp_col, out_real);
            end
            
            read_count++;
        end
    end

    // Monitor Pipelining Alignment
    always @(posedge clk) begin
        // Triggers once per frame
        if (rst_n && frame_done) begin
            $display("[MONITOR ALERT] Demux 'frame_done' pulse asserted. Moving to next frame.");
        end
    end

endmodule