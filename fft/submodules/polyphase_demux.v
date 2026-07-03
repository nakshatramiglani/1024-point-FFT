`timescale 1 ns / 1 ps

/*
The idea is to use a "broadcast-and-decode" architecture instead of standard 1-to-32 demultiplexing.
Data is routed to all memory banks at once and uses a one-hot write-enable decoder to select the target bank.
*/

module polyphase_demux #(
    parameter IN_WIDTH = 36,
    parameter WIDTH = 1024, 
    parameter NUM_BANKS = 32, // the M in the M x N representation of the transform (number of banks)
    parameter BANK_DEPTH = 32 // the N in the M x N representation of the transform (depth of each bank)
)(
    // Control signals
    input logic clk,
    input logic rst_n,
    /*input logic valid_in,*/ // Keeping this, just in case we decide to add a valid_in signal (we should ideally)


    input logic signed [IN_WIDTH - 1:0] in_real,
    input logic signed [IN_WIDTH - 1:0] in_imag,

    // Outputs to the memory banks
    output logic signed [IN_WIDTH - 1:0] broadcast_real,
    output logic signed [IN_WIDTH - 1:0] broadcast_imag,
    output logic [NUM_BANKS - 1:0] bank_we, // One-hot write enable (column)
    output logic [$clog2(BANK_DEPTH) - 1:0] bank_waddr, // Shared write address for all banks (row)
    output reg [$clog2(WIDTH) :0] counter,
    output logic frame_done, // Goes high for 1 cycle when a full 2D grid is populated
    output logic ping_pong_reg
    );

    // Calculate bit-widths needed for internal hardware counters
    localparam BANK_BITS = $clog2(NUM_BANKS);
    localparam ADDR_BITS = $clog2(BANK_DEPTH);

    logic [BANK_BITS - 1:0] phase_cnt; // Sweeps horizontally across banks
    logic [ADDR_BITS - 1:0] addr_cnt; // Sweeps vertically through a bank

    /*
    Inferring multiplexers is avoided by simply broadcasting the input data to all banks.
    The banks use the write-enable signal to determine whether or not to latch this data.
    */

    assign broadcast_real = in_real;
    assign broadcast_imag = in_imag;

    assign bank_waddr = addr_cnt;
    reg ping_pong_select;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_cnt <= '0;
            addr_cnt <= '0;
            frame_done <= 1'b0;
            bank_we <= '0;
            counter <= '0;
            ping_pong_select <= '0;
            ping_pong_reg <= '0;
        end
        else begin
            frame_done <= 1'b0;
            bank_we <= '0;
            /*if (valid_in) begin*/ // Subject to inclusion
                bank_we[phase_cnt] <= 1'b1; // Asserts one-hot write-enable only to current bank
                if (phase_cnt == NUM_BANKS - 1) begin
                    phase_cnt <= '0; // Wrap around to zero to start with next row
                    if (addr_cnt == BANK_DEPTH - 1) begin // If this was the last row and it is complete, the entire M x N grid is populated.
                        frame_done <= 1'b1;
                        ping_pong_select <= ~ping_pong_select;
                        addr_cnt <= '0;
                    end
                    else begin
                        addr_cnt <= addr_cnt + 1; // If this wasn't the last row but it is complete, move onto the next one
                    end
                end
                else begin
                    phase_cnt <= phase_cnt + 1;
                end

                if (counter == WIDTH)
                    counter <= 0;
                else
                    counter <= counter + 1;
            /*end*/
        end
    end

    always_ff @(posedge clk) begin
        ping_pong_reg <= ping_pong_select;
    end

endmodule


