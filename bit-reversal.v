`timescale 1ns/1ps

module bit_reversal #(
    parameter WIDTH = 16,
    parameter IN_WIDTH = 32
)(
    input logic clk,
    input logic rst_n,
    input logic signed [IN_WIDTH - 1:0] in_real,
    input logic signed [IN_WIDTH - 1:0] in_imag,
    input logic [$clog2(WIDTH) - 1:0] in_count,
    output logic signed [IN_WIDTH - 1:0] out_real,
    output logic signed [IN_WIDTH - 1:0] out_imag
);

    localparam ADDR_WIDTH = $clog2(WIDTH);

    // Ping-pong RAM arrays (two separate memory architectures for read and write to eliminate latency)
    (* ram_style = "distributed" *) logic signed [IN_WIDTH - 1:0] ram_real_0 [0:WIDTH-1];
    (* ram_style = "distributed" *) logic signed [IN_WIDTH - 1:0] ram_imag_0 [0:WIDTH-1];
    (* ram_style = "distributed" *) logic signed [IN_WIDTH - 1:0] ram_real_1 [0:WIDTH-1];
    (* ram_style = "distributed" *) logic signed [IN_WIDTH - 1:0] ram_imag_1 [0:WIDTH-1];

    logic state;
    logic [ADDR_WIDTH - 1:0] bit_rev_addr;

    // Bit reversal logic

    always_comb begin
        for (int i = 0; i < ADDR_WIDTH; i++) begin
            bit_rev_addr[i] = in_count[ADDR_WIDTH - 1 - i];
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 1'b0;
            out_real <= '0;
            out_imag <= '0;
        end
        else begin
            // Toggle the state every time a full frame finishes writing
            if (in_count == WIDTH - 1) begin
                state <= ~state;
            end
            if (state == 1'b0) begin
                ram_real_0[in_count] <= in_real;
                ram_imag_0[in_count] <= in_imag;
                out_real <= ram_real_1[bit_rev_addr];
                out_imag <= ram_imag_1[bit_rev_addr];
            end
            else begin
                ram_real_1[in_count] <= in_real;
                ram_imag_1[in_count] <= in_imag;
                out_real <= ram_real_0[bit_rev_addr];
                out_imag <= ram_imag_0[bit_rev_addr];
            end
        end
    end

endmodule