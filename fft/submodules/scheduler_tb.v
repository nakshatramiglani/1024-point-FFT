`timescale 1 ns / 1 ps
module tb_polyphase_system;

    localparam IN_WIDTH   = 32;
    localparam NUM_BANKS  = 16;  // M
    localparam BANK_DEPTH = 4;   // N
    localparam WIDTH      = 64;  // M x N

    // Clock and Reset
    logic clk;
    logic rst_n;

    // Stimulus Inputs
    logic signed [IN_WIDTH-1:0] in_real;
    logic signed [IN_WIDTH-1:0] in_imag;

    // Demux to Array/Scheduler
    logic signed [IN_WIDTH-1:0] broadcast_real;
    logic signed [IN_WIDTH-1:0] broadcast_imag;
    logic [NUM_BANKS-1:0]       bank_we;
    logic [$clog2(BANK_DEPTH)-1:0] bank_waddr;
    logic [$clog2(WIDTH):0]     counter;
    logic                       frame_done;
    logic                       ping_pong_select; 

    // Scheduler to Array
    logic [$clog2(NUM_BANKS)-1:0]  bank_select;
    logic [$clog2(BANK_DEPTH)-1:0] bank_raddr;
    logic [NUM_BANKS-1:0]          bank_re;
    logic                          ping_pong_sel_r;
    logic                          read_valid;

    // Final Outputs from Array
    logic signed [IN_WIDTH-1:0] out_real;
    logic signed [IN_WIDTH-1:0] out_imag;


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
        .frame_done(frame_done),
        .ping_pong_select(ping_pong_select)
    );


    scheduler #(
        .WIDTH(WIDTH),
        .NUM_BANKS(NUM_BANKS),
        .BANK_DEPTH(BANK_DEPTH)
    ) u_scheduler (
        .clk(clk),
        .rst_n(rst_n),
        .counter(counter),
        .bank_select(bank_select),
        .bank_raddr(bank_raddr),
        .bank_re(bank_re),
        .ping_pong_sel_r(ping_pong_sel_r),
        .read_valid(read_valid)
    );


    memory_bank_array #(
        .IN_WIDTH(IN_WIDTH),
        .NUM_BANKS(NUM_BANKS),
        .BANK_DEPTH(BANK_DEPTH)
    ) u_mem_array (
        .clk(clk),
        .ping_pong_sel_w(ping_pong_select),
        .ping_pong_sel_r(ping_pong_sel_r),
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
    always begin
        clk = 1'b0;
        #10;
        clk = 1'b1;
        #10;
    end

    initial begin
        // Initialize Inputs
        rst_n   = 1'b0;
        in_real = '0;
        in_imag = '0;
        #2;
        @(negedge clk);
        rst_n = 1'b1;
        $display("[TB] Reset released. Starting streaming data...");
        // Frame 0: Data 1 to 16
        // Frame 1: Data 17 to 32
        // Frame 2: Data 33 to 48
        for (int frame = 0; frame < 3; frame++) begin
            for (int i = 0; i < WIDTH; i++) begin
                @(negedge clk);
                in_real = (frame * WIDTH) + i + 1; 
                in_imag = -((frame * WIDTH) + i + 1); 
            end
        end
        #20;
        $finish;
    end

    logic read_valid_d1; // Only need 1 cycle of delay to match RAM latency
    always_ff @(posedge clk) begin
        read_valid_d1 <= read_valid;
    end

    always @(posedge clk) begin
        if (read_valid_d1) begin 
            $display("[OUTPUT] Time: %0t | Out Real: %d | Out Imag: %d", $time, out_real, out_imag);
        end
    end

endmodule