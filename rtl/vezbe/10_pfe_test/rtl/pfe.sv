`timescale 1ns/1ps

module pfe #(
    parameter int DSIZE  = 16
)(
    input  logic             clk_i,
    input  logic             rst_ni,
    input  logic [DSIZE-1:0] phase_increment,
    input logic [1:0] sel,
    output logic [DSIZE/2-1:0] out
);

    logic [DSIZE-1:0] acc;

    logic [DSIZE-1:0] sum;
    logic overflow_unused;
    logic [DSIZE-1:0] out_2;
    logic [DSIZE/2-1:0] out_3;

    logic signed [7:0] prav;
    logic signed [7:0] tes;
    logic signed [7:0] tres;
    logic signed [8:0] temp;

    adder_N #(
        .N(DSIZE)
    ) u_adder (
        .a_i(out_2),
        .b_i(phase_increment),
        .c_i(1'b0),
        .sum_o(sum),
        .overflow_o(overflow_unused)
    );

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            acc <= '0;
        else
            acc <= sum;
    end

    assign out_2 = acc;

    assign out_3 = out_2[DSIZE-1:8];

    logic signed [7:0] rom [256];
    initial begin
    $readmemh("/home/pfe/asic-radionica/rtl/vezbe/10_pfe_test/rtl/lutSin.txt", rom);
    end
    logic signed [DSIZE/2-1:0] sin;
    assign sin=$signed(rom[out_3]);

    assign prav = ((out_3) < 128) ? 127 : -128;

    assign tes = (out_3) - 128;

    assign temp = (out_3 < 128) ? (out_3 + out_3 - 128) : (382 - out_3 - out_3);

    assign tres = temp[7:0];

    mux #(
        .N(DSIZE/2)
    ) u_mux (
        .sinus(sin),
        .pravougaonik(prav),
        .testera(tes),
        .trougao(tres),
        .sel(sel),
        .izlaz(out)
    );

endmodule
