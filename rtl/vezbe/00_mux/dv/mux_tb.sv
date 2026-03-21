// Ovaj fajl sadrzi testbench za modul mux, koji se koristi u vezbama. 
// Testbench generise nasumicne ulazne podatke i proverava da li je izlaz modula mux 
// ispravan na osnovu vrednosti selektora.

// timescale direktiva definise vremensku jedinicu i preciznost simulacije. U ovom slucaju,
// vremenska jedinica je 1 nanosekunda, a preciznost je 100 pikosekundi.  
`timescale 1ns/100ps

// Ako N nije definisan pre ukljucivanja ovog fajla, onda ce biti definisan na 8.
// Ovo omogucava fleksibilnost u sirini signala, a istovremeno omogucava da se testbench ///
// koristi sa razlicitim sirinama bez potrebe za izmenom koda testbencha.
`ifndef N
  `define N 8
`endif
`define MAX_RANGE ((1 << `N) - 1)


// Nesintetizovani testbench modul koji se koristi za testiranje funkcionalnosti modula mux.
// U ovom modulu se generisu nasumicni ulazni podaci i proverava se da li je izlaz modula 
// mux ispravan na osnovu vrednosti selektora. Testbench takodje generise VCD  fajl koji se 
// moze koristiti za vizuelizaciju signala tokom simulacije.

module mux_tb ();
  logic          sel_i;
  logic [`N-1:0] a_i;
  logic [`N-1:0] b_i;
  logic [`N-1:0] c_o;

  mux #(.N (`N)) i_mux (
    .a_i(a_i),
    .b_i(b_i),
    .sel_i(sel_i),
    .c_o(c_o)
  );

  // Generisanje nasumicnih ulaznih podataka
  // initial blok se koristi za inicijalizaciju i generisanje test vektora. U ovom bloku se 
  // koristi petlja koja se izvrsava 40 puta, a u svakom prolazu se generisu nasumicni 
  // podaci za ulaze a_i, b_i i sel_i. Nakon generisanja svakog seta ulaznih podataka, // 
  // simulacija se pauzira na 2 nanosekunda kako bi se omogucilo da se promene na ulazima 
  // propagiraju kroz modul mux i da se proveri izlaz c_o. Nakon zavrsetka petlje, /
  //simulacija se zavrsava nakon dodatnih 10 nanosekundi.
  initial begin
    for (int i = 0; i < 40; i++) begin
      /* verilator lint_off WIDTHTRUNC */
      a_i   = $urandom_range(0, `MAX_RANGE);
      b_i   = $urandom_range(0, `MAX_RANGE);
      sel_i = $urandom_range(0, 1);
      /* verilator lint_on WIDTHTRUNC */
      #2;
    end
    #10 
    $finish;
  end

  // Generisanje VCD fajla za vizuelizaciju signala
  // initial blok se koristi za generisanje VCD fajla koji se moze koristiti
  // za vizuelizaciju signala tokom simulacije. $dumpfile funkcija se koristi za
  // definisanje imena VCD fajla, dok se $dumpvars funkcija koristi za specificiranje
  // nivoa detalja koji ce biti ukljuceni u VCD fajl.
  initial begin
    $dumpfile("mux.vcd");
    $dumpvars(0, mux_tb);
  end

  // Check the results
  always @(c_o) begin
    if (sel_i) begin: gen_expect_a
      if (c_o === a_i) begin
        $display("%02d [ns]: [PASSED]: c_o (hex: %02H) == a_i (hex: %02H) when sel_i=1", $time, c_o, a_i);
      end else begin
        $error("%02d [ns]: [FAILED]: c_o (hex: %02H) != a_i (hex: %02H) when sel_i=1", $time, c_o, a_i);
      end
    end
    else begin: gen_expect_b
      if (c_o === b_i) begin
        $display("%02d [ns]: [PASSED]: c_o (hex: %02H) == b_i (hex: %02H) when sel_i=0", $time, c_o, a_i);
      end else begin
        $error("%02d [ns]: [FAILED]: c_o (hex: %02H) != b_i (hex: %02H) when sel_i=0", $time, c_o, a_i);
      end
    end
  end
endmodule
