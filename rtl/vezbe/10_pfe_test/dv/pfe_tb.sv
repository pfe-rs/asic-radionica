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

    logic [DSIZE-1:0] sent[N];
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
            sent[i] = DSIZE'($urandom_range(0, 255));
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
        $display("Done"); $finish;
    end

endmodule
