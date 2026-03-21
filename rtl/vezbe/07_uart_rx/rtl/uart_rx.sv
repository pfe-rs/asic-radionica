module uart_rx #(
  parameter int CLK_FREQ  = 50_000_000,
  parameter int BAUD_RATE = 115_200
) (
  input  logic       clk_i,          // sistemski takt
  input  logic       rst_ni,         // asinhroni reset aktivan na niskom nivou
  input  logic       rx_i,           // serijska RX linija
  output logic [7:0] rx_data_o,      // primljeni bajt
  output logic       rx_done_o,      // puls: bajt primljen
  output logic       rx_frame_err_o  // puls: greška stop bita
);

  // Vaš kod ovde

endmodule