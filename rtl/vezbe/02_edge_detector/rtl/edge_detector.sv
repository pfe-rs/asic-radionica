`default_nettype none

module edge_detector (
  input logic data_i,
  input logic clk,
  input logic rst_n,
  output logic rising_edge_o,
  output logic falling_edge_o,
  output logic both_edges_o
  // Vaš kod ovde
  );
  logic pom;
  always_ff @(posedge clk) begin
   if (~rst_n) begin pom <=0; end
   else begin pom<=data_i; end
   end
  assign falling_edge_o = ~data_i && pom;
  assign rising_edge_o=(data_i && ~pom);
  assign both_edges_o = (falling_edge_o || rising_edge_o);
  // Vaš kod ovde
endmodule

`default_nettype wire
