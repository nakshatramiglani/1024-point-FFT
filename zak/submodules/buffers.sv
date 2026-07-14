module buffer #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 8
)(
    input  wire                         clk,
    input  wire                         nrst,

    input  wire signed [DATA_WIDTH-1:0] in_real,
    input  wire signed [DATA_WIDTH-1:0] in_imag,

    output signed [DATA_WIDTH-1:0] delayed_real,
    output signed [DATA_WIDTH-1:0] delayed_imag
);

localparam PTR_LEN = (DEPTH <= 1) ? 1 : $clog2(DEPTH);

(* ram_style = "distributed" *)
reg signed [DATA_WIDTH-1:0] mem_real [0:DEPTH-1];
(* ram_style = "distributed" *)
reg signed [DATA_WIDTH-1:0] mem_imag [0:DEPTH-1];

reg [PTR_LEN-1:0] ptr;

integer i;

// Combinational Read (Removes the extra 1-cycle delay)
assign delayed_real = mem_real[ptr];
assign delayed_imag = mem_imag[ptr];

initial begin
    ptr = '0;
    for (i = 0; i < DEPTH; i = i + 1) begin
        mem_real[i] = '0;
        mem_imag[i] = '0;
    end
end

always @(posedge clk) begin
    mem_real[ptr] <= in_real;
    mem_imag[ptr] <= in_imag;
    if (ptr == DEPTH - 1)
        ptr <= '0;
    else
        ptr <= ptr + 1'b1;
end

endmodule