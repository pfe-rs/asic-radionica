module adder_N # (
  parameter int N = 8
    ) (
  input  [N-1:0] a_i,
  input  [N-1:0] b_i,
  input          c_i,
  output [N-1:0] sum_o,
  output         overflow_o
  );

  logic [N:0] c_o;
  assign c_o[0] = c_i;

  genvar i;

  generate
    for (i = 0; i < N; i++) begin : g_ime
        assign sum_o[i] = a_i[i] ^ b_i[i] ^ c_o[i];
        assign c_o[i+1] = (a_i[i] && b_i[i]) || (c_o[i] && (a_i[i] ^ b_i[i]));
  end
  endgenerate

  assign overflow_o = c_o[N] ^ c_o[N-1];

  // Vaš kod ovde
endmodule
