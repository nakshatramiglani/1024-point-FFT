module twiddle_factors #(
    parameter WIDTH = 16,
    parameter TWIDDLE_WIDTH = 16
)(
    input logic clk,
    input logic rst_n,
    input logic done, 
    input logic [$clog2(WIDTH)-2:0] angle_idx,

    output logic signed [TWIDDLE_WIDTH-1:0] twiddle_real,
    output logic signed [TWIDDLE_WIDTH-1:0] twiddle_imag
);

    localparam SIZE = $clog2(WIDTH);
    localparam QUARTER_WIDTH = WIDTH / 4;

    (* ram_style = "distributed" *)
    logic signed [TWIDDLE_WIDTH-1:0] rom_real [0:QUARTER_WIDTH-1];

    (* ram_style = "distributed" *)
    logic signed [TWIDDLE_WIDTH-1:0] rom_imag [0:QUARTER_WIDTH-1];

    initial begin
        $readmemh("data/fft/twiddles_real.hex", rom_real);
        $readmemh("data/fft/twiddles_imag.hex", rom_imag);
    end

    logic signed [TWIDDLE_WIDTH-1:0] raw_r;
    logic signed [TWIDDLE_WIDTH-1:0] raw_i;
    logic swap_flag;

    always_ff @(posedge clk and posedge done) begin
        raw_r <= rom_real[angle_idx[SIZE-3:0]];
        raw_i <= rom_imag[angle_idx[SIZE-3:0]];
        swap_flag <= angle_idx[SIZE-2];
    end

    always_ff @((posedge clk or negedge rst_n) and posedge done) begin
        if (!rst_n) begin
            twiddle_real <= '0;
            twiddle_imag <= '0;
        end
        else begin
            if (swap_flag) begin
                twiddle_real <= raw_i;
                twiddle_imag <= -raw_r;
            end
            else begin
                twiddle_real <= raw_r;
                twiddle_imag <= raw_i;
            end
        end
    end

endmodule