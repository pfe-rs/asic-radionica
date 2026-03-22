`default_nettype none

module simpleRegister
  # (
  parameter int N = 8
  )(
    input logic [N-1:0] in,
    output logic [N-1:0] out,
    input clk,
    input res
  );

  genvar i;

  generate
    for (i = 0; i < N; i++) begin : g_ime
      always_ff @(posedge clk or negedge res) begin
        if (~res) begin out[i] <= 0; end
        else begin out[i] <= in[i]; end
    end
  end
  endgenerate

endmodule
`default_nettype wire
