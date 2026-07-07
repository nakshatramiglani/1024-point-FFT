
`timescale 1 ns / 1 ps


module scheduler #(
    parameter WIDTH = 1024,
    parameter NUM_BANKS = 32,  
    parameter BANK_DEPTH = 32 
)(
    input logic clk,
    input logic rst_n,
    
    input logic [$clog2(WIDTH):0] counter, 
    output logic [$clog2(NUM_BANKS) - 1:0]  bank_select,
    output logic [$clog2(BANK_DEPTH) - 1:0] bank_raddr,
    output logic [NUM_BANKS - 1:0]          bank_re,
    output logic                            ping_pong_sel_r,

    output logic read_valid 
);

    localparam TRIGGER_VAL = WIDTH - NUM_BANKS - BANK_DEPTH + 2;

    logic reading;
    logic trigger_now;
    logic read_last_cycle;
    logic write_buffer_sel;
    logic [$clog2(NUM_BANKS)-1:0] next_bank_select;


    logic [$clog2(BANK_DEPTH) - 1:0] internal_raddr;
    assign bank_raddr = {internal_raddr[0], internal_raddr[$clog2(BANK_DEPTH)-1:1]};

    assign trigger_now     = (counter == TRIGGER_VAL);
    assign read_last_cycle = reading && (internal_raddr == BANK_DEPTH - 1) && (bank_select == NUM_BANKS - 1);
    
    // Look-ahead bank logic
    assign next_bank_select = (internal_raddr == BANK_DEPTH - 1) ? (bank_select + 1'b1) : bank_select;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_buffer_sel <= 1'b0;
        end else if (counter == WIDTH - 1) begin
            write_buffer_sel <= ~write_buffer_sel; 
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reading         <= 1'b0;
            bank_select     <= '0;
            internal_raddr  <= '0;
            bank_re         <= '0;
            read_valid      <= 1'b0;
            ping_pong_sel_r <= 1'b0;
        end else begin
            // new frame trigger hits
            if (trigger_now) begin
                reading         <= 1'b1;
                read_valid      <= 1'b1;
                bank_select     <= '0;
                internal_raddr  <= '0;
                bank_re         <= NUM_BANKS'(1); 
                ping_pong_sel_r <= write_buffer_sel; 
            end 
            // readout in progress
            else if (reading) begin
                if (read_last_cycle) begin
                    reading         <= 1'b0;
                    read_valid      <= 1'b0;
                    bank_select     <= '0;
                    internal_raddr  <= '0;
                    bank_re         <= '0;
                end else begin
                    read_valid      <= 1'b1;

                    if (internal_raddr == BANK_DEPTH - 1) begin
                        internal_raddr <= '0;
                        bank_select    <= bank_select + 1'b1;
                    end else begin
                        internal_raddr <= internal_raddr + 1'b1;
                    end

                    bank_re <= (NUM_BANKS'(1) << next_bank_select);
                end
            end 
            else begin
                read_valid          <= 1'b0;
                bank_re             <= '0;
            end
        end
    end

endmodule
