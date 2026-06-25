`include "complex_multiply.v"
`include "add_sub.v"
`include "twiddle_fetch.v"
`include "buffers.v"

module stage #(
    parameter WIDTH = 16,
    parameter IN_WIDTH = 16,
    parameter TWIDDLE_WIDTH = 16,
    parameter STAGE = 1 //stages start from 1
)(
    input logic clk,
    input logic rst_n,
    input logic signed [IN_WIDTH-1:0] in_real,
    input logic signed [IN_WIDTH-1:0] in_imag,
    input logic [$clog2(WIDTH) - 1:0] sample_count,

    output logic signed [IN_WIDTH:0] out_real,
    output logic signed [IN_WIDTH:0] out_imag
);

    localparam SIZE       = $clog2(WIDTH);
    localparam DATA_WIDTH = IN_WIDTH;
    localparam DELAY = 1 << (SIZE - STAGE);

    wire signed [DATA_WIDTH:0] delay_in_real;
    wire signed [DATA_WIDTH:0] delay_in_imag;

    wire signed [DATA_WIDTH:0] delayed_real;
    wire signed [DATA_WIDTH:0] delayed_imag;

    wire signed [TWIDDLE_WIDTH - 1:0] twiddle_real;
    wire signed [TWIDDLE_WIDTH - 1:0] twiddle_imag;

    logic [SIZE - 2:0] angle_idx;
    logic done;
    assign done = 1'b1;

    wire signed [DATA_WIDTH:0] in_real_ext = {in_real[DATA_WIDTH-1], in_real};
    wire signed [DATA_WIDTH:0] in_imag_ext = {in_imag[DATA_WIDTH-1], in_imag};

    wire signed [DATA_WIDTH+1:0] raw_added_real, raw_added_imag;
    wire signed [DATA_WIDTH+1:0] raw_sub_real, raw_sub_imag;

    wire signed [DATA_WIDTH:0] added_real = raw_added_real[DATA_WIDTH:0];
    wire signed [DATA_WIDTH:0] added_imag = raw_added_imag[DATA_WIDTH:0];
    wire signed [DATA_WIDTH:0] subtracted_real = raw_sub_real[DATA_WIDTH:0];
    wire signed [DATA_WIDTH:0] subtracted_imag = raw_sub_imag[DATA_WIDTH:0];

    wire signed [DATA_WIDTH:0] multiplied_real;
    wire signed [DATA_WIDTH:0] multiplied_imag;

    logic switch;
    logic switch_d1, switch_d2, switch_d3, switch_d4;
    assign switch = sample_count[SIZE - STAGE];
    assign angle_idx = sample_count << (STAGE - 1);

    always_ff @(posedge clk or negedge rst_n) begin
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

    assign delay_in_real = switch_d4 ? multiplied_real : in_real_ext;
    assign delay_in_imag = switch_d4 ? multiplied_imag : in_imag_ext;

    logic signed [DATA_WIDTH:0] added_real_d1, added_real_d2;
    logic signed [DATA_WIDTH:0] added_imag_d1, added_imag_d2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            added_real_d1 <= '0;
            added_real_d2 <= '0;
            added_imag_d1 <= '0;
            added_imag_d2 <= '0;
        end
        else begin
            added_real_d1 <= added_real;
            added_real_d2 <= added_real_d1;
            added_imag_d1 <= added_imag;
            added_imag_d2 <= added_imag_d1;
        end
    end

    assign out_real = switch_d4 ? added_real_d2 : delayed_real;
    assign out_imag = switch_d4 ? added_imag_d2 : delayed_imag;

    buffer #(.DEPTH(DELAY), .DATA_WIDTH(DATA_WIDTH + 1))
        buff_inst(
            .clk(clk),
            .nrst(rst_n),
            .in_real(delay_in_real),
            .in_imag(delay_in_imag),
            .delayed_real(delayed_real),
            .delayed_imag(delayed_imag)
    );

    add_sub #(.DATA_WIDTH(DATA_WIDTH + 1))
        addsub_inst(
            .clk(clk),
            .in1_real(delayed_real),
            .in1_imag(delayed_imag),
            .in2_real(in_real_ext),
            .in2_imag(in_imag_ext),
            .out1_real(raw_added_real),
            .out1_imag(raw_added_imag),
            .out2_real(raw_sub_real),
            .out2_imag(raw_sub_imag)
    );
    twiddle_factors #(
        .WIDTH(WIDTH),
        .TWIDDLE_WIDTH(TWIDDLE_WIDTH))
        twiddle_inst(
            .clk(clk),
            .rst_n(rst_n),
            .angle_idx(angle_idx),
            .done(done),
            .twiddle_real(twiddle_real),
            .twiddle_imag(twiddle_imag)
    );

//multiply twiddle factor with even input
    complex_multiply #(
        .FFT_WIDTH(DATA_WIDTH + 1),
        .TWIDDLE_WIDTH(TWIDDLE_WIDTH))
        cmplx_mult_inst(
            .clk(clk),
            .rst_n(rst_n),
            .mul1_real(twiddle_real),
            .mul1_imag(twiddle_imag),
            .mul2_real(subtracted_real),
            .mul2_imag(subtracted_imag),
            .out_real(multiplied_real),
            .out_imag(multiplied_imag)
    );

endmodule