module bitonic_sort #(
  parameter int DATA_WIDTH   = 8,
  parameter int NUM_ELEMENTS = 8
) (
  input  logic                              clk_i,
  input  logic                              rst_ni,
  input  logic                              valid_i,
  input  logic [NUM_ELEMENTS*DATA_WIDTH-1:0] data_i,
  output logic [NUM_ELEMENTS*DATA_WIDTH-1:0] data_o,
  output logic                              valid_o
);

  // Vaš kod ovde

endmodule