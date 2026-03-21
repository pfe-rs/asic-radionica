module shift_register 
    # (
    parameter int N = 8
    ) (
    input  logic         clk_i,
    input  logic         rst_ni,    // asinhroni reset aktivan na niskom nivou
    input  logic         en_i,      // omogućavanje pomeranja
    input  logic         serial_i,  // serijski bit se pomera u LSB
    output logic [N-1:0] parallel_o // paralelni izlaz
    );
  
    // Vaš kod ovde
endmodule