`timescale 1ns/1ps

module pfe_tb;

    localparam int DSIZE = 8;

    logic             clk_i      = 0;
    logic             rst_ni     = 0;
    logic [DSIZE-1:0] in_data_i  = '0;
    logic             in_valid_i = 0;
    logic             in_ready_o;
    logic [DSIZE-1:0] out_data_o;
    logic             out_valid_o;
    logic             out_ready_i = 1;

    pfe #(.DSIZE(DSIZE)) dut (.*);

    always #5 clk_i = ~clk_i;

    initial begin
        repeat (2) @(posedge clk_i);
        rst_ni = 1;

        for (int i = 0; i < 8; i++) begin
            @(negedge clk_i);
            in_data_i  = $urandom_range(0, 255);
            in_valid_i = 1;
            @(posedge clk_i); #1;
            assert (out_data_o === in_data_i) else $error("data mismatch: in=0x%02h out=0x%02h", in_data_i, out_data_o);
            $display("data=0x%02h out=0x%02h %s",
                     in_data_i, out_data_o, (out_data_o === in_data_i) ? "PASS" : "FAIL");
        end

        $display("Done"); $finish;
    end

endmodule