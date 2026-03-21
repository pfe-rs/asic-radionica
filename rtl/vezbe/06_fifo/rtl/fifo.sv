module fifo #(
  parameter DSIZE = 8,
  parameter ASIZE = 8
  ) (
  input  logic             clk_i,     // takt
  input  logic             rst_ni,    // asinhroni reset aktivan na niskom nivou
  input  logic             wr_en_i,   // omogućavanje pisanja
  input  logic             rd_en_i,   // omogućavanje čitanja
  input  logic [DSIZE-1:0] wr_data_i, // podaci za upis
  output logic [DSIZE-1:0] rd_data_o, // podaci za čitanje
  output logic             wr_full_o, // zastavica punog FIFO-a
  output logic             rd_empty_o // zastavica praznog FIFO-a
  );

  // Vaš kod ovde

endmodule