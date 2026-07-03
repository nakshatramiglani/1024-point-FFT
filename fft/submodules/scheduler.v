module scheduler#(
    parameter IN_WIDTH = 36,
    parameter WIDTH = 1024,
    parameter NUM_BANKS = 32, // the M in the MxN representation of the transform (number of banks)
    parameter BANK_DEPTH = 32 // the N in the MxN representation of the transform (depth of each bank)
)(
    input logic clk,
    input logic rst_n,
    input [$clog2(WIDTH):0] counter,
    //input ping_pong_select,

    //Outputs to memory bank
    output logic [$clog2(NUM_BANKS) - 1:0] bank_select, // The selection signal received from the scheduler
    output logic [$clog2(BANK_DEPTH) - 1:0] bank_raddr, // The address to be accessed within the selected bank; received from scheduler
    output logic [NUM_BANKS-1:0] bank_re,// The one-hot read-enable signal received from the scheduler
    output logic valid_out
    );

// Calculate the trigger constant requested: size - M - N + 2
    localparam TRIGGER_VAL = WIDTH - NUM_BANKS - BANK_DEPTH + 2;

    // Internal tracking counters for reading
    logic [$clog2(NUM_BANKS) - 1:0] r_bank_sel;
    logic [$clog2(BANK_DEPTH) - 1:0] r_addr_cnt;
    logic reading;
    logic reading_delayed;

    // Assign address read controls directly from internal counters
    assign bank_select = r_bank_sel;
    assign bank_raddr  = r_addr_cnt;

    // Generate the one-hot read enable vector
    always_comb begin
        bank_re = '0;
        if (reading) begin
            bank_re[r_bank_sel] = 1'b1;
        end
    end

    // Sequential matrix readout logic (Column-by-Column Transpose)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_bank_sel      <= '0;
            r_addr_cnt      <= '0;
            reading         <= 1'b0;
            reading_delayed <= 1'b0;
        end else begin
            reading_delayed <= reading;

            if (!reading) begin
                // Check if the current frame write has progressed far enough to start reading
                if (counter == TRIGGER_VAL) begin
                    reading    <= 1'b1;
                    r_bank_sel <= '0;
                    r_addr_cnt <= '0;
                end
            end else begin
                // Traverse down the column of the current memory bank first
                if (r_addr_cnt == BANK_DEPTH - 1) begin
                    r_addr_cnt <= '0;
                    // Move to the next memory bank (next column)
                    if (r_bank_sel == NUM_BANKS - 1) begin
                        reading <= 1'b0; // All elements read out for this frame
                    end else begin
                        r_bank_sel <= r_bank_sel + 1;
                    end
                end else begin
                    r_addr_cnt <= r_addr_cnt + 1;
                end
            end
        end
    end

    assign valid_out = reading;

     
endmodule