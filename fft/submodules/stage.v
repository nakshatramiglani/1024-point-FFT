`include "complex_multiply.v"
`include "add_sub.v"
`include "twiddle_fetch.v"
`include "buffers.v"

module stage #(
parameter WIDTH = 16,
parameter IN_WIDTH = 32,
parameter TWIDDLE_WIDTH = 16,
parameter STAGE = 1 // stages start from 1
)(
input logic clk,
input logic rst_n,
input logic signed [IN_WIDTH-1:0] in_real,
input logic signed [IN_WIDTH-1:0] in_imag,
input logic [$clog2(WIDTH) - 1:0] sample_count,
input logic signed [TWIDDLE_WIDTH-1:0] rom_real [0:WIDTH/4-1],
input logic signed [TWIDDLE_WIDTH-1:0] rom_imag [0:WIDTH/4-1],

output logic signed [IN_WIDTH-1:0] out_real,
output logic signed [IN_WIDTH-1:0] out_imag
);

localparam SIZE = $clog2(WIDTH);
localparam DATA_WIDTH = IN_WIDTH;
localparam SCALE = 32768.0;
// --- LATENCY REDUCTION LOGIC FOR i=0 (STAGE==1) ---
// If Stage 1, your scheduler makes pairs arrive back-to-back, so depth is just 1.
localparam DELAY = (STAGE == 1) ? 1 : (1 << (SIZE - STAGE));

wire signed [DATA_WIDTH-1:0] delay_in_real;
wire signed [DATA_WIDTH-1:0] delay_in_imag;

wire signed [DATA_WIDTH - 1:0] raw_delayed_real;
wire signed [DATA_WIDTH - 1:0] raw_delayed_imag;

wire signed [DATA_WIDTH - 1:0] delayed_real;
wire signed [DATA_WIDTH - 1:0] delayed_imag;

wire signed [TWIDDLE_WIDTH - 1:0] twiddle_real;
wire signed [TWIDDLE_WIDTH - 1:0] twiddle_imag;

logic [SIZE - 2:0] angle_idx;

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

logic switch;
logic switch_d1, switch_d2, switch_d3, switch_d4;
// Adjust control switch behavior for back-to-back streaming in Stage 1
    assign switch = sample_count[SIZE - STAGE];
assign angle_idx = sample_count << (STAGE - 1);

// Initialization counter to track when buffer garbage is fully flushed
logic [$clog2(DELAY+1):0] init_cnt;
wire buff_out_valid;

always_ff @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
init_cnt <= '0;
end else begin
if (init_cnt < DELAY) begin
init_cnt <= init_cnt + 1;
end
end
end

assign buff_out_valid = (init_cnt == DELAY);

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

assign delay_in_real = (!rst_n) ? '0 : in_real;
assign delay_in_imag = (!rst_n) ? '0 : in_imag;

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

assign delayed_real = buff_out_valid ? raw_delayed_real : '0;
assign delayed_imag = buff_out_valid ? raw_delayed_imag : '0;

assign out_real = (!rst_n) ? {IN_WIDTH{1'b0}} :
(switch_d4 ? added_real_d2[DATA_WIDTH-1:0]: feedback_delayed_real);
assign out_imag = (!rst_n) ? {IN_WIDTH{1'b0}} :
(switch_d4 ? added_imag_d2[DATA_WIDTH-1:0] : feedback_delayed_imag);

// Buffers now automatically size down to DEPTH=1 for Stage 1 (acting as a simple FF)
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

twiddle_factors #(
.WIDTH(WIDTH),
.TWIDDLE_WIDTH(TWIDDLE_WIDTH))
twiddle_inst(
.clk(clk),
.rst_n(rst_n),
.angle_idx(angle_idx),
.rom_real(rom_real),
.rom_imag(rom_imag),
.twiddle_real(twiddle_real),
.twiddle_imag(twiddle_imag)
);

complex_multiply #(
.FFT_WIDTH(IN_WIDTH),
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


always@(posedge clk) begin
    if (STAGE ==1)
        $display("In: (%8f, %8f) | Out: (%8f, %8f)",

                     real'(in_real) / SCALE, real'(in_imag) / SCALE,
                     real'(out_real) / SCALE, real'(out_imag) / SCALE);

end

endmodule 
