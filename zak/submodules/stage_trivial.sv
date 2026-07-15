`include "add_sub.sv"
`include "buffers.sv"

module stage_trivial #(
    parameter WIDTH = 16,
    parameter IN_WIDTH = 32,
    parameter STAGE = 1 // stages start from 1
)(
    input wire clk,
    input wire rst_n,
    input wire signed [IN_WIDTH-1:0] in_real,
    input wire signed [IN_WIDTH-1:0] in_imag,
    input wire [$clog2(WIDTH) - 1:0] sample_count,

    output wire signed [IN_WIDTH-1:0] out_real,
    output wire signed [IN_WIDTH-1:0] out_imag
);

    localparam SIZE       = $clog2(WIDTH);
    localparam DATA_WIDTH = IN_WIDTH;
    localparam DELAY      = 1 << (SIZE - STAGE);

    wire signed [DATA_WIDTH-1:0] delay_in_real;
    wire signed [DATA_WIDTH-1:0] delay_in_imag;

    // Internal wires for raw buffer output before masking
    wire signed [DATA_WIDTH - 1:0] raw_delayed_real;
    wire signed [DATA_WIDTH - 1:0] raw_delayed_imag;

    wire signed [DATA_WIDTH - 1:0] delayed_real;
    wire signed [DATA_WIDTH - 1:0] delayed_imag;

    // FIX: Bounded size safely to avoid [-1:0] crash for N=2
    wire [SIZE - 1:0] angle_idx; 
    wire done;
    assign done = 1'b1;

    wire signed [DATA_WIDTH:0] raw_added_real, raw_added_imag;
    wire signed [DATA_WIDTH - 1:0] raw_sub_real, raw_sub_imag;

    wire signed [DATA_WIDTH - 1:0] feedback_delayed_real;
    wire signed [DATA_WIDTH - 1:0] feedback_delayed_imag;

    wire signed [DATA_WIDTH:0] added_real = raw_added_real[DATA_WIDTH:0];
    wire signed [DATA_WIDTH:0] added_imag = raw_added_imag[DATA_WIDTH:0];
    wire signed [DATA_WIDTH - 1:0] subtracted_real = raw_sub_real;
    wire signed [DATA_WIDTH - 1:0] subtracted_imag = raw_sub_imag;

    wire signed [DATA_WIDTH - 1:0] multiplied_real;
    wire signed [DATA_WIDTH - 1:0] multiplied_imag;

    wire switch;
    reg switch_d1, switch_d2, switch_d3, switch_d4;
    assign switch = sample_count[SIZE - STAGE];
    
    // FIX: Prevent negative shift amounts when STAGE is 1
    assign angle_idx = (STAGE > 1) ? (sample_count << (STAGE - 1)) : sample_count;

    // Initialization counter to track when buffer garbage is fully flushed
    reg [$clog2(DELAY+1):0] init_cnt;
    wire buff_out_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            init_cnt <= 0;
        end else begin
            if (init_cnt < DELAY) begin
                init_cnt <= init_cnt + 1;
            end
        end
    end

    assign buff_out_valid = (init_cnt == DELAY);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            switch_d1 <= 0;
            switch_d2 <= 0;
            switch_d3 <= 0;
            switch_d4 <= 0;
        end
        else begin
            switch_d1 <= switch;
            switch_d2 <= switch_d1;
            switch_d3 <= switch_d2;
            switch_d4 <= switch_d3;
        end
    end

    // Masked assignments: Feed zeros into the buffer when in reset to prevent X propagation
    assign delay_in_real = (!rst_n) ? {DATA_WIDTH{1'b0}} : in_real;
    assign delay_in_imag = (!rst_n) ? {DATA_WIDTH{1'b0}} : in_imag;

    reg signed [DATA_WIDTH:0] added_real_d1, added_real_d2;
    reg signed [DATA_WIDTH:0] added_imag_d1, added_imag_d2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            added_real_d1 <= 0;
            added_real_d2 <= 0;
            added_imag_d1 <= 0;
            added_imag_d2 <= 0;
        end
        else begin
            added_real_d1 <= added_real;
            added_real_d2 <= added_real_d1;
            added_imag_d1 <= added_imag;
            added_imag_d2 <= added_imag_d1;
        end
    end

    // Mask buffer output with valid signal (strips X values out)
    assign delayed_real = buff_out_valid ? raw_delayed_real : {DATA_WIDTH{1'b0}};
    assign delayed_imag = buff_out_valid ? raw_delayed_imag : {DATA_WIDTH{1'b0}};

    assign out_real = (!rst_n) ? {IN_WIDTH{1'b0}} : 
                      (switch_d4 ? added_real_d2[DATA_WIDTH-1:0]: feedback_delayed_real);
    assign out_imag = (!rst_n) ? {IN_WIDTH{1'b0}} : 
                      (switch_d4 ? added_imag_d2[DATA_WIDTH-1:0] : feedback_delayed_imag);

    buffer #(.DEPTH(DELAY), .DATA_WIDTH(DATA_WIDTH))
        buff_inst(
            .clk(clk),
            .nrst(rst_n),
            .in_real(delay_in_real),
            .in_imag(delay_in_imag),
            .delayed_real(raw_delayed_real),
            .delayed_imag(raw_delayed_imag)
    );

    buffer #(.DEPTH(DELAY), .DATA_WIDTH(DATA_WIDTH))
        feedback_buff_inst(
            .clk(clk),
            .nrst(rst_n),
            .in_real(multiplied_real),
            .in_imag(multiplied_imag),
            .delayed_real(feedback_delayed_real),
            .delayed_imag(feedback_delayed_imag)
    );

    add_sub #(.DATA_WIDTH(DATA_WIDTH))
        addsub_inst(
            .clk(clk),
            .in1_real(delayed_real),
            .in1_imag(delayed_imag),
            .in2_real(in_real),
            .in2_imag(in_imag),
            .out1_real(raw_added_real),
            .out1_imag(raw_added_imag),
            .out2_real(raw_sub_real),
            .out2_imag(raw_sub_imag)
    );

    // =========================================================================
    // TRIVIAL MULTIPLIER REPLACEMENT LOGIC
    // =========================================================================
    reg signed [DATA_WIDTH - 1:0] rot_real, rot_imag;
    reg signed [DATA_WIDTH - 1:0] mult_pipe_real [0:1]; // 2-cycle emulation pipeline
    reg signed [DATA_WIDTH - 1:0] mult_pipe_imag [0:1]; // 2-cycle emulation pipeline

    always @(*) begin
        // If WIDTH is 4, and STAGE is 1, apply the W_4^1 (-j) twiddle factor
        // Multiplication by -j swaps Real and Imag, and negates the new Imag component.
        // Formula: (R + jI) * (-j) = I - jR
        if (WIDTH == 4 && STAGE == 1 && angle_idx[0] == 1'b1) begin
            rot_real = subtracted_imag;
            rot_imag = -subtracted_real;
        end else begin
            // Trivial multiply by 1 (Pass-through for W_2^0 and W_4^0)
            rot_real = subtracted_real;
            rot_imag = subtracted_imag;
        end
    end

    // Emulate the exact 2-cycle latency of the standard complex_multiply block 
    // to keep synchronization tight with the switch_d4 control signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_pipe_real[0] <= 0;
            mult_pipe_real[1] <= 0;
            mult_pipe_imag[0] <= 0;
            mult_pipe_imag[1] <= 0;
        end else begin
            mult_pipe_real[0] <= rot_real;
            mult_pipe_real[1] <= mult_pipe_real[0];
            mult_pipe_imag[0] <= rot_imag;
            mult_pipe_imag[1] <= mult_pipe_imag[0];
        end
    end

    assign multiplied_real = mult_pipe_real[1];
    assign multiplied_imag = mult_pipe_imag[1];

endmodule