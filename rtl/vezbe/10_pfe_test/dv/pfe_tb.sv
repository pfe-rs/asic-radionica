`timescale 1ns/1ps

module pfe_tb;

    parameter int DSIZE = 16;

    logic clk_i;
    logic rst_ni;
    logic [DSIZE-1:0] phase_increment;
    logic [1:0] sel;
    logic [DSIZE/2-1:0] out;

    pfe #(
        .DSIZE(DSIZE)
    ) dut (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .phase_increment(phase_increment),
        .sel(sel),
        .out(out)
    );

    initial clk_i = 0;
    always #5 clk_i = ~clk_i;

    initial begin
        rst_ni = 0;
        phase_increment = 16'd655;
        #2;
        rst_ni = 1;
        sel = 0;

        for (int i = 0; i < 4; i++) begin
            sel = i;
            #100;


            case(sel)
                2'b00: begin // sinus
                    if (out <= 8'sd127 && out >= -8'sd127)
                        $display("PASSED: Sinus output %0d", out);
                    else
                        $display("FAILED: Sinus output out of range %0d", out);
                end
                2'b01: begin // pravougaonik
                    if (out == 8'sd127 || out == -8'sd128)
                        $display("PASSED: Square output %0d", out);
                    else
                        $display("FAILED: Square output invalid %0d", out);
                end
                2'b10: begin // testera
                    if (out >= -8'sd128 && out <= 8'sd127)
                        $display("PASSED: Sawtooth output %0d", out);
                    else
                        $display("FAILED: Sawtooth output out of range %0d", out);
                end
                2'b11: begin // trougao
                    if (out >= -8'sd128 && out <= 8'sd127)
                        $display("PASSED: Triangle output %0d", out);
                    else
                        $display("FAILED: Triangle output out of range %0d", out);
                end
            endcase

            #10000;
        end


        $finish;
    end

    initial begin
         $dumpfile("pfe_tb.vcd");
        $dumpvars(0, pfe_tb);
        end

endmodule
