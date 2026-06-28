`timescale 1ns/1ps

`include "stage.v"
`include "bit-reversal.v"

module fft_top #(
    parameter WIDTH = 1024,
    parameter IN_WIDTH = 36,
    parameter TWIDDLE_WIDTH = 16
)(
    input  logic clk,
    input  logic rst_n,
    input  logic signed [IN_WIDTH-1:0] in_real,
    input  logic signed [IN_WIDTH-1:0] in_imag,
    input  logic [$clog2(WIDTH)-1:0] sample_count,

    output logic signed [IN_WIDTH-1:0] out_real,
    output logic signed [IN_WIDTH-1:0] out_imag
);

    //localparameters
    localparam NUM_STAGES = $clog2(WIDTH);
    localparam QUARTER_WIDTH = WIDTH/4;

    // Arrays to interconnect the data and control signals
    wire signed [IN_WIDTH-1:0] stage_real [0:NUM_STAGES];
    wire signed [IN_WIDTH-1:0] stage_imag [0:NUM_STAGES];
    logic [$clog2(WIDTH)-1:0]  stage_count [0:NUM_STAGES];

    assign stage_real[0] = in_real;
    assign stage_imag[0] = in_imag;
    assign stage_count[0] = sample_count;

    // ROM arrays for twiddle factors
    (* ram_style="distributed" *) logic signed [TWIDDLE_WIDTH-1:0] rom_real [0:QUARTER_WIDTH-1];
    (* ram_style="distributed" *) logic signed [TWIDDLE_WIDTH-1:0] rom_imag [0:QUARTER_WIDTH-1];

    initial begin
        $readmemh("data/fft/twiddles_real.hex", rom_real);
        $readmemh("data/fft/twiddles_imag.hex", rom_imag);
    end

    genvar i;
    generate
        for (i = 1; i <= NUM_STAGES; i = i + 1) begin : gen_fft_stages

            stage #(
                .WIDTH(WIDTH), 
                .IN_WIDTH(IN_WIDTH), 
                .TWIDDLE_WIDTH(TWIDDLE_WIDTH), 
                .STAGE(i)
            ) stg_inst (
                .clk(clk), 
                .rst_n(rst_n),
                .in_real(stage_real[i-1]), 
                .in_imag(stage_imag[i-1]), 
                .sample_count(stage_count[i-1]), 
                .rom_imag(rom_imag), 
                .rom_real(rom_real),
                .out_real(stage_real[i]), 
                .out_imag(stage_imag[i])
            );

            begin : gen_delay
                // Delay = (Buffer Depth of current stage) + 4 cycles
                localparam DELAY_DEPTH = (WIDTH >> i) + 4; 
                
                logic [$clog2(WIDTH)-1:0] delay_pipe [0:DELAY_DEPTH-1];
                
                always_ff @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        for (int j = 0; j < DELAY_DEPTH; j++) begin
                            delay_pipe[j] <= '0;
                        end
                    end else begin
                        delay_pipe[0] <= stage_count[i-1];
                        for (int j = 1; j < DELAY_DEPTH; j++) begin
                            delay_pipe[j] <= delay_pipe[j-1];
                        end
                    end
                end
                
                // Connect the end of the shift register to the next stage's input
                assign stage_count[i] = delay_pipe[DELAY_DEPTH-1];
            end
        end
    endgenerate

    bit_reversal #(
        .WIDTH(WIDTH),
        .IN_WIDTH(IN_WIDTH)
    ) bit_rev_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in_real(stage_real[NUM_STAGES]),
        .in_imag(stage_imag[NUM_STAGES]),
        .in_count(stage_count[NUM_STAGES]),
        .out_real(out_real),
        .out_imag(out_imag)
    );

endmodule