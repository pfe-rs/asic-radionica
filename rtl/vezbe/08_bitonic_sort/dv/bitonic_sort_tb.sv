// =============================================================================
// Testbench: bitonic_sort_tb
// Opis: Verifikacija pipeline bitoničnog sortera.
//       Kompatibilan sa iverilog -g2012.
//
// Testovi:
//   1. Već sortiran niz (uzlazno)
//   2. Obrnuto sortiran niz (silazno)
//   3. Svi jednaki elementi
//   4. Niz sa min/max/srednje vrednostima
//   5. Nasumični nizovi (100 iteracija)
//   6. Pipeline propusnost — 4 uzastopna niza bez praznina
//   7. Reset briše pipeline (valid_o mora biti 0 posle reseta)
// =============================================================================

`timescale 1ns/1ps

module bitonic_sort_tb;

  // ---------------------------------------------------------------------------
  // Parametri
  // ---------------------------------------------------------------------------
  localparam int DATA_WIDTH   = 8;
  localparam int NUM_ELEMENTS = 8;
  localparam int LOG2N        = 3;                          // log2(8)
  localparam int NUM_STAGES   = (LOG2N * (LOG2N + 1)) / 2; // 6
  localparam int BUS_W        = NUM_ELEMENTS * DATA_WIDTH;  // 64

  localparam int CLK_PERIOD   = 10; // ns

  // ---------------------------------------------------------------------------
  // DUT signali
  // ---------------------------------------------------------------------------
  logic             clk_i;
  logic             rst_ni;
  logic             valid_i;
  logic [BUS_W-1:0] data_i;
  logic [BUS_W-1:0] data_o;
  logic             valid_o;

  // ---------------------------------------------------------------------------
  // DUT instanca
  // ---------------------------------------------------------------------------
  bitonic_sort #(
    .DATA_WIDTH   (DATA_WIDTH),
    .NUM_ELEMENTS (NUM_ELEMENTS)
  ) dut (
    .clk_i    (clk_i),
    .rst_ni   (rst_ni),
    .valid_i  (valid_i),
    .data_i   (data_i),
    .data_o   (data_o),
    .valid_o  (valid_o)
  );

  // ---------------------------------------------------------------------------
  // Takt
  // ---------------------------------------------------------------------------
  initial clk_i = 1'b0;
  always #(CLK_PERIOD/2) clk_i = ~clk_i;

  // ---------------------------------------------------------------------------
  // Pomocne funkcije
  //
  // Sve operacije nad nizovima rade na spakovanim magistralama (BUS_W bita)
  // kako bi se izbeglo ograničenje iverilog-a sa unpacked nizovima kao
  // argumentima funkcija/taskova.
  // ---------------------------------------------------------------------------

  // Izlucuje element k iz spakovane magistrale
  function automatic logic [DATA_WIDTH-1:0] get_elem(
    input logic [BUS_W-1:0] bus,
    input int                k
  );
    get_elem = bus[k*DATA_WIDTH +: DATA_WIDTH];
  endfunction

  // Upisuje element val na poziciju k u spakovanoj magistrali
  function automatic logic [BUS_W-1:0] set_elem(
    input logic [BUS_W-1:0]    bus,
    input int                   k,
    input logic [DATA_WIDTH-1:0] val
  );
    logic [BUS_W-1:0] tmp;
    tmp = bus;
    tmp[k*DATA_WIDTH +: DATA_WIDTH] = val;
    set_elem = tmp;
  endfunction

  // Referentno sortiranje (bubble sort) — vraca sortiranu magistralu
  function automatic logic [BUS_W-1:0] ref_sort(
    input logic [BUS_W-1:0] in_bus
  );
    logic [BUS_W-1:0]    sorted;
    logic [DATA_WIDTH-1:0] tmp;
    sorted = in_bus;
    for (int i = 0; i < NUM_ELEMENTS-1; i++) begin
      for (int j = 0; j < NUM_ELEMENTS-1-i; j++) begin
        if (get_elem(sorted, j) > get_elem(sorted, j+1)) begin
          tmp    = get_elem(sorted, j);
          sorted = set_elem(sorted, j,   get_elem(sorted, j+1));
          sorted = set_elem(sorted, j+1, tmp);
        end
      end
    end
    ref_sort = sorted;
  endfunction

  // Provera rezultata: poredi data_o sa ref_sort(original)
  // Ispisuje PASS/FAIL i vraca 0 (pass) ili 1 (fail)
  task automatic check_result(
    input logic [BUS_W-1:0] original,
    input string             test_name,
    output logic             failed
  );
    logic [BUS_W-1:0] expected;
    expected = ref_sort(original);
    failed = 1'b0;

    if (!valid_o) begin
      $display("FAIL [%s] — valid_o nije visok!", test_name);
      failed = 1'b1;
    end else if (data_o !== expected) begin
      $display("FAIL [%s] — sortiranje netacno!", test_name);
      $write("  Ulaz:     ");
      for (int k = 0; k < NUM_ELEMENTS; k++) $write("%0d ", get_elem(original, k));
      $display("");
      $write("  DUT izlaz:");
      for (int k = 0; k < NUM_ELEMENTS; k++) $write("%0d ", get_elem(data_o, k));
      $display("");
      $write("  Ocekivano:");
      for (int k = 0; k < NUM_ELEMENTS; k++) $write("%0d ", get_elem(expected, k));
      $display("");
      failed = 1'b1;
    end else begin
      $write("PASS [%s] — ", test_name);
      for (int k = 0; k < NUM_ELEMENTS; k++) $write("%0d ", get_elem(data_o, k));
      $display("");
    end
  endtask

  // Pošalji jednu magistralu i sačekaj NUM_STAGES taktova
  task automatic send_and_wait(input logic [BUS_W-1:0] bus);
    @(posedge clk_i); #1;
    valid_i = 1'b1;
    data_i  = bus;
    @(posedge clk_i); #1;
    valid_i = 1'b0;
    data_i  = '0;
    repeat (NUM_STAGES) @(posedge clk_i);
    #1;
  endtask

  // ---------------------------------------------------------------------------
  // Stimulus
  // ---------------------------------------------------------------------------
  integer seed;
  logic [BUS_W-1:0] test_bus;
  logic             failed;
  int               total_fails;

  initial begin
    rst_ni      = 1'b0;
    valid_i     = 1'b0;
    data_i      = '0;
    seed        = 42;
    total_fails = 0;

    repeat (3) @(posedge clk_i);
    #1;
    rst_ni = 1'b1;
    @(posedge clk_i); #1;

    $display("===================================================");
    $display(" Bitonic Sort Testbench  (N=%0d, W=%0d, stages=%0d)",
             NUM_ELEMENTS, DATA_WIDTH, NUM_STAGES);
    $display("===================================================");

    // -----------------------------------------------------------------
    // Test 1: Već uzlazno sortiran niz
    // -----------------------------------------------------------------
    test_bus = '0;
    for (int k = 0; k < NUM_ELEMENTS; k++)
      test_bus = set_elem(test_bus, k, DATA_WIDTH'(k + 1));
    send_and_wait(test_bus);
    check_result(test_bus, "Uzlazno sortiran ulaz", failed);
    total_fails += failed;

    // -----------------------------------------------------------------
    // Test 2: Silazno sortiran niz
    // -----------------------------------------------------------------
    test_bus = '0;
    for (int k = 0; k < NUM_ELEMENTS; k++)
      test_bus = set_elem(test_bus, k, DATA_WIDTH'(NUM_ELEMENTS - k));
    send_and_wait(test_bus);
    check_result(test_bus, "Silazno sortiran ulaz", failed);
    total_fails += failed;

    // -----------------------------------------------------------------
    // Test 3: Svi jednaki elementi
    // -----------------------------------------------------------------
    test_bus = '0;
    for (int k = 0; k < NUM_ELEMENTS; k++)
      test_bus = set_elem(test_bus, k, 8'hAB);
    send_and_wait(test_bus);
    check_result(test_bus, "Svi jednaki elementi", failed);
    total_fails += failed;

    // -----------------------------------------------------------------
    // Test 4: Min/Max/Srednji
    // -----------------------------------------------------------------
    test_bus = '0;
    test_bus = set_elem(test_bus, 0, 8'hFF);
    test_bus = set_elem(test_bus, 1, 8'h55);
    test_bus = set_elem(test_bus, 2, 8'h55);
    test_bus = set_elem(test_bus, 3, 8'h00);
    test_bus = set_elem(test_bus, 4, 8'h55);
    test_bus = set_elem(test_bus, 5, 8'h55);
    test_bus = set_elem(test_bus, 6, 8'h55);
    test_bus = set_elem(test_bus, 7, 8'hFF);
    send_and_wait(test_bus);
    check_result(test_bus, "Min/Max/Srednji", failed);
    total_fails += failed;

    // -----------------------------------------------------------------
    // Test 5: 100 nasumičnih nizova
    // -----------------------------------------------------------------
    begin
      int rand_fails;
      logic [BUS_W-1:0] rand_bus;
      rand_fails = 0;

      for (int iter = 0; iter < 100; iter++) begin
        rand_bus = '0;
        for (int k = 0; k < NUM_ELEMENTS; k++)
          rand_bus = set_elem(rand_bus, k, DATA_WIDTH'($random(seed)));

        send_and_wait(rand_bus);

        if (!valid_o) begin
          $display("FAIL [Random iter=%0d] valid_o nije visok!", iter);
          rand_fails++;
        end else if (data_o !== ref_sort(rand_bus)) begin
          $display("FAIL [Random iter=%0d] sortiranje netacno!", iter);
          $write("  Ulaz:     ");
          for (int k = 0; k < NUM_ELEMENTS; k++) $write("%0d ", get_elem(rand_bus, k));
          $display("");
          $write("  DUT izlaz:");
          for (int k = 0; k < NUM_ELEMENTS; k++) $write("%0d ", get_elem(data_o, k));
          $display("");
          rand_fails++;
        end
      end

      if (rand_fails == 0)
        $display("PASS [100 nasumicnih nizova]");
      else begin
        $display("FAIL [Nasumicni] — %0d gresaka od 100", rand_fails);
        total_fails += rand_fails;
      end
    end

    // -----------------------------------------------------------------
    // Test 6: Pipeline propusnost — 4 uzastopna niza bez praznina
    // -----------------------------------------------------------------
    begin
      logic [BUS_W-1:0] in0, in1, in2, in3;
      logic [BUS_W-1:0] out_buf [0:3];
      int               out_cnt;
      logic             pipe_fail;

      in0 = '0; in1 = '0; in2 = '0; in3 = '0;
      for (int k = 0; k < NUM_ELEMENTS; k++) begin
        in0 = set_elem(in0, k, DATA_WIDTH'($random(seed)));
        in1 = set_elem(in1, k, DATA_WIDTH'($random(seed)));
        in2 = set_elem(in2, k, DATA_WIDTH'($random(seed)));
        in3 = set_elem(in3, k, DATA_WIDTH'($random(seed)));
      end

      // Pošalji 4 niza uzastopno (flood pipeline)
      @(posedge clk_i); #1;
      valid_i = 1'b1; data_i = in0; @(posedge clk_i); #1;
      valid_i = 1'b1; data_i = in1; @(posedge clk_i); #1;
      valid_i = 1'b1; data_i = in2; @(posedge clk_i); #1;
      valid_i = 1'b1; data_i = in3; @(posedge clk_i); #1;
      valid_i = 1'b0; data_i = '0;

      // Prikupi 4 izlaza
      out_cnt = 0;
      repeat (NUM_STAGES + 6) begin
        if (valid_o && out_cnt < 4) begin
          out_buf[out_cnt] = data_o;
          out_cnt++;
        end
        @(posedge clk_i); #1;
      end

      pipe_fail = 1'b0;
      if (out_cnt !== 4) begin
        $display("FAIL [Pipeline] — ocekivano 4 izlaza, dobijeno %0d", out_cnt);
        pipe_fail = 1'b1;
      end else begin
        if (out_buf[0] !== ref_sort(in0)) pipe_fail = 1'b1;
        if (out_buf[1] !== ref_sort(in1)) pipe_fail = 1'b1;
        if (out_buf[2] !== ref_sort(in2)) pipe_fail = 1'b1;
        if (out_buf[3] !== ref_sort(in3)) pipe_fail = 1'b1;
        if (pipe_fail)
          $display("FAIL [Pipeline] — jedan ili vise izlaza netacno");
        else
          $display("PASS [Pipeline propusnost — 4 uzastopna niza]");
      end
      total_fails += pipe_fail;
    end

    // -----------------------------------------------------------------
    // Test 7: Reset briše pipeline
    // -----------------------------------------------------------------
    begin
      test_bus = '0;
      for (int k = 0; k < NUM_ELEMENTS; k++)
        test_bus = set_elem(test_bus, k, DATA_WIDTH'(8'hFF - k));

      @(posedge clk_i); #1;
      valid_i = 1'b1;
      data_i  = test_bus;
      @(posedge clk_i); #1;
      valid_i = 1'b0;
      data_i  = '0;

      // Resetuj 2 takta posle slanja
      repeat (2) @(posedge clk_i); #1;
      rst_ni = 1'b0;
      @(posedge clk_i); #1;
      rst_ni = 1'b1;

      // Sačekaj — valid_o ne sme biti visok
      repeat (NUM_STAGES + 2) @(posedge clk_i);
      #1;

      if (valid_o) begin
        $display("FAIL [Reset] — valid_o je visok nakon reseta!");
        total_fails++;
      end else begin
        $display("PASS [Reset brise pipeline]");
      end
    end

    // -----------------------------------------------------------------
    // Završetak
    // -----------------------------------------------------------------
    $display("===================================================");
    if (total_fails == 0)
      $display(" Svi testovi prosli!");
    else
      $display(" GRESKA: %0d test(ova) nije proslo!", total_fails);
    $display("===================================================");
    $finish;
  end

  // Tajmaut
  initial begin
    #(CLK_PERIOD * 20000);
    $display("TIMEOUT!");
    $finish;
  end

endmodule