`timescale 1ns/1ps

module pfe_tb;

    localparam int DSIZE = 8;
    localparam int N = 8;

    logic             clk_i= 0;
    logic             rst_ni     = 0;
    logic [DSIZE-1:0] in_data_i  = '0;
    logic             in_valid_i = 0;
    logic             in_ready_o;
    logic [DSIZE-1:0] out_data_o;
    logic             out_valid_o;
    logic             out_ready_i = 1;

    logic [DSIZE-1:0] buff_o_0;
    logic [DSIZE-1:0] buff_o_1;
    logic [DSIZE-1:0] buff_o_2;
    logic [DSIZE-1:0] buff_o_3;
    logic [DSIZE-1:0] buff_o_4;
    logic [DSIZE-1:0] buff_o_5;
    logic [DSIZE-1:0] buff_o_6;
    logic [DSIZE-1:0] buff_o_7;
    logic [DSIZE-1:0] reading_i_0;
    logic [DSIZE-1:0] reading_i_1;
    logic [DSIZE-1:0] reading_i_2;
    logic [DSIZE-1:0] reading_i_3;
    logic [DSIZE-1:0] reading_i_4;
    logic [DSIZE-1:0] reading_i_5;
    logic [DSIZE-1:0] reading_i_6;
    logic [DSIZE-1:0] reading_i_7;
    logic [DSIZE-1:0] ffs_0;
    logic [DSIZE-1:0] ffs_1;
    logic [DSIZE-1:0] ffs_2;
    logic [DSIZE-1:0] ffs_3;
    logic [DSIZE-1:0] ffs_4;
    logic [DSIZE-1:0] ffs_5;
    logic [DSIZE-1:0] ffs_6;
    logic [DSIZE-1:0] ffs_7;

    logic [DSIZE-1:0] sent [N];
    assign sent[0] = DSIZE'(1);
    assign sent[1] = DSIZE'(2);
    assign sent[2] = DSIZE'(5);
    assign sent[3] = DSIZE'(7);
    assign sent[4] = DSIZE'(8);
    assign sent[5] = DSIZE'(6);
    assign sent[6] = DSIZE'(4);
    assign sent[7] = DSIZE'(3);
    logic [DSIZE-1:0] receved[N];

    pfe #(.DSIZE(DSIZE), .N(N)) dut (.*);

    // assign clk_i = 0;
    always #5 clk_i = ~clk_i;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0,pfe_tb);

        repeat (2) @(posedge clk_i);
        rst_ni = 1;

        for (int i = 0; i < N; i++) begin
            @(negedge clk_i);
            in_data_i  = sent[i];
            in_valid_i = 1;
            @(posedge clk_i); #1;
            // assert (out_data_o === in_data_i) else $error("data mismatch: in=0x%02h out=0x%02h", in_data_i, out_data_o);
            // $display("data=0x%02h out=0x%02h %s",
            //          in_data_i, out_data_o, (out_data_o === in_data_i) ? "PASS" : "FAIL");
        end

        @(posedge out_valid_o);
        for (int i = 0; i < N; i++) begin
            @(negedge clk_i);
            receved[i] = out_data_o;
            @(posedge clk_i); #1;
        end

        for (int i = 0; i < N; i++) begin
            $display("data=0x%02h out=0x%02h",
                     sent[i], receved[i]);
        end

        #10000;
        $display(
buff_o_0,
buff_o_1,
buff_o_2,
buff_o_3,
buff_o_4,
buff_o_5,
buff_o_6,
buff_o_7,
reading_i_0,
reading_i_1,
reading_i_2,
reading_i_3,
reading_i_4,
reading_i_5,
reading_i_6,
reading_i_7,
ffs_0,
ffs_1,
ffs_2,
ffs_3,
ffs_4,
ffs_5,
ffs_6,
ffs_7
        );
        $display("Done"); $finish;
    end

endmodule
