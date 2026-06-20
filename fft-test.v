`timescale 1 ns / 1 ps

`define WIDTH 1024
`define SIZE 10
`define HALF_WIDTH (`WIDTH / 2)

`define DATA_WIDTH 32
`define TWIDDLE_WIDTH 16

`define OUT_WIDTH (`DATA_WIDTH + `TWIDDLE_WIDTH - 1 + `SIZE)

    module testbench_tb;
        reg signed [`DATA_WIDTH-1:0] A_real[`WIDTH-1:0];
        reg signed [`DATA_WIDTH-1:0] A_imag[`WIDTH-1:0];

        wire signed [`DATA_WIDTH-1:0] B_real[`WIDTH-1:0];
        wire signed [`DATA_WIDTH-1:0] B_imag[`WIDTH-1:0];

        wire signed [`OUT_WIDTH -1:0] out_real[`WIDTH-1:0];
        wire signed [`OUT_WIDTH -1:0] out_imag[`WIDTH-1:0];

        reg signed [`OUT_WIDTH -1:0] B_new_real[`WIDTH-1:0];
        reg signed [`OUT_WIDTH -1:0] B_new_imag[`WIDTH-1:0];

        wire done;
        integer i;

        integer file_in;
        integer file_out;
        integer scan_result;

        real start_time;
        real end_time;
        real display_real;
        real display_imag;

        bit_reversal uut_rev_real(.in(A_real), .out(B_real));
        bit_reversal uut_rev_imag(.in(A_imag), .out(B_imag));

        add_sub uut2(.in_real(B_new_real), .in_imag(B_new_imag), .out_real(out_real), .out_imag(out_imag), .done(done));

        always_comb begin
            for (i = 0; i < `WIDTH; i = i + 1) begin
                B_new_real[i] = $signed(B_real[i]) <<< (`TWIDDLE_WIDTH - 1);       
                B_new_imag[i] = $signed(B_imag[i]) <<< (`TWIDDLE_WIDTH - 1);  
            end
        end

        initial begin
            $dumpfile("test.vcd");
            $dumpvars(0, testbench_tb);
            $display("Test testbench");
            
            file_in = $fopen("data/fft/input.txt", "r");
            if(file_in == 0) begin
                $display("Error: Input file not found.");
                $finish;
            end
            file_out = $fopen("results/fft/output.json", "w");
            if (file_out == 0) begin
                $display("Error: Could not open output file.");
                $finish;
            end

            $fdisplay(file_out, "{");

            for (i = 0; i < `WIDTH; i = i + 1) begin
                scan_result = $fscanf(file_in, "%d %d", A_real[i], A_imag[i]);

                if (scan_result != 2)
                    $display("Warning: Incorrect input format on line %0d.", i);
            end

            $fclose(file_in);

            #5;
            start_time = $realtime;
            #10;
            end_time = $realtime;

            for (i = 0; i < `WIDTH; i = i + 1) begin

                display_real = $signed(out_real[i]);
                display_imag = $signed(out_imag[i]);

                if (i == `WIDTH - 1) begin
                    $fdisplay(file_out, "  \"out_%0d\": [\n    %f,\n    %f\n  ]", 
                          i, display_real / 32768.0, display_imag / 32768.0);
                end 
                else begin
                    $fdisplay(file_out, "  \"out_%0d\": [\n    %f,\n    %f\n  ],", 
                          i, display_real / 32768.0, display_imag / 32768.0);
                end
                    
            end

            $fdisplay(file_out, "}");
            $fclose(file_out);
            $display("Simulation complete.");
            $display("Time: %0f ns", (end_time - start_time));
        end
        
    endmodule