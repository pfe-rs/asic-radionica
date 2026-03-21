`timescale 1ns/1ps

module uart_rx_tb;

  localparam integer CLK_FREQ     = 50_000_000;
  localparam integer BAUD_RATE    = 115_200;
  localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
  localparam real    CLK_PERIOD   = 1_000_000_000.0 / CLK_FREQ;

  logic       clk_i;
  logic       rst_ni;
  logic       rx_i;
  logic [7:0] rx_data_o;
  logic       rx_done_o;
  logic       rx_frame_err_o;

  integer pass_cnt;
  integer fail_cnt;

  // Pomocne promenljive za provere
  logic       t_done;
  logic       t_ferr;
  logic [7:0] t_data;
  integer     t_cnt;

  uart_rx #(
    .CLK_FREQ  (CLK_FREQ),
    .BAUD_RATE (BAUD_RATE)
  ) dut (
    .clk_i          (clk_i),
    .rst_ni         (rst_ni),
    .rx_i           (rx_i),
    .rx_data_o      (rx_data_o),
    .rx_done_o      (rx_done_o),
    .rx_frame_err_o (rx_frame_err_o)
  );

  initial clk_i = 0;
  always #(CLK_PERIOD / 2.0) clk_i = ~clk_i;

  // -------------------------------------------------------------------------
  // Task: pošalji jedan UART bajt (8N1)
  //   inject_err = 1 => stop bit ce biti 0 (greška frejma)
  // -------------------------------------------------------------------------
  task send_byte;
    input [7:0] data;
    input       inject_err;
    integer i;
    begin
      // Start bit
      rx_i = 1'b0;
      repeat(CLKS_PER_BIT) @(posedge clk_i);
      // Podatkovni bitovi, LSB prvi
      for (i = 0; i < 8; i = i + 1) begin
        rx_i = data[i];
        repeat(CLKS_PER_BIT) @(posedge clk_i);
      end
      // Stop bit
      rx_i = inject_err ? 1'b0 : 1'b1;
      repeat(CLKS_PER_BIT) @(posedge clk_i);
      // Idle
      rx_i = 1'b1;
    end
  endtask

  // -------------------------------------------------------------------------
  // Task: čekaj done ili frame_err signal (s tajm-autom)
  //   Rezultati se čuvaju u t_done, t_ferr
  // -------------------------------------------------------------------------
  task wait_signal;
    input integer timeout_clks;
    begin
      t_done = 0;
      t_ferr = 0;
      t_cnt  = 0;
      while (t_cnt < timeout_clks) begin
        @(posedge clk_i);
        t_cnt = t_cnt + 1;
        if (rx_done_o) begin
          t_done = 1;
          t_cnt  = timeout_clks; // izlaz iz petlje
        end else if (rx_frame_err_o) begin
          t_ferr = 1;
          t_cnt  = timeout_clks; // izlaz iz petlje
        end
      end
    end
  endtask

  // -------------------------------------------------------------------------
  // Task: provera rezultata
  // -------------------------------------------------------------------------
  task check;
    input [255:0] name;
    input         cond;
    begin
      if (cond) begin
        $display("[PASS] %s", name);
        pass_cnt = pass_cnt + 1;
      end else begin
        $display("[FAIL] %s", name);
        fail_cnt = fail_cnt + 1;
      end
    end
  endtask

  // -------------------------------------------------------------------------
  // Globalni tajm-aut
  // -------------------------------------------------------------------------
  initial begin
    #(CLK_PERIOD * CLKS_PER_BIT * 200);
    $display("GRESKA: Globalni tajm-aut!");
    $finish;
  end

  // -------------------------------------------------------------------------
  // Glavni test
  // -------------------------------------------------------------------------
  initial begin
    pass_cnt = 0;
    fail_cnt = 0;

    // Reset
    rst_ni = 0;
    rx_i   = 1;
    repeat(10) @(posedge clk_i);
    rst_ni = 1;
    repeat(5)  @(posedge clk_i);

    // =========================================================================
    // Test 1: Prijem bajta 0xA5
    // =========================================================================
    $display("\n--- Test 1: Prijem bajta 0xA5 ---");
    fork
      send_byte(8'hA5, 1'b0);
      wait_signal(CLKS_PER_BIT * 15);
    join
    t_data = rx_data_o;
    check("T1: rx_done_o visoka  ", t_done == 1'b1);
    check("T1: frame_err niska   ", t_ferr == 1'b0);
    check("T1: rx_data_o == 0xA5 ", t_data == 8'hA5);
    repeat(5) @(posedge clk_i);

    // =========================================================================
    // Test 2: Back-to-back — 0x12
    // =========================================================================
    $display("\n--- Test 2: Back-to-back prijem 0x12, 0x34, 0x56 ---");
    fork
      send_byte(8'h12, 1'b0);
      wait_signal(CLKS_PER_BIT * 15);
    join
    t_data = rx_data_o;
    check("T2[0]: rx_done_o      ", t_done == 1'b1);
    check("T2[0]: frame_err niska", t_ferr == 1'b0);
    check("T2[0]: data == 0x12   ", t_data == 8'h12);
    repeat(3) @(posedge clk_i);

    // Test 2b: 0x34
    fork
      send_byte(8'h34, 1'b0);
      wait_signal(CLKS_PER_BIT * 15);
    join
    t_data = rx_data_o;
    check("T2[1]: rx_done_o      ", t_done == 1'b1);
    check("T2[1]: frame_err niska", t_ferr == 1'b0);
    check("T2[1]: data == 0x34   ", t_data == 8'h34);
    repeat(3) @(posedge clk_i);

    // Test 2c: 0x56
    fork
      send_byte(8'h56, 1'b0);
      wait_signal(CLKS_PER_BIT * 15);
    join
    t_data = rx_data_o;
    check("T2[2]: rx_done_o      ", t_done == 1'b1);
    check("T2[2]: frame_err niska", t_ferr == 1'b0);
    check("T2[2]: data == 0x56   ", t_data == 8'h56);
    repeat(3) @(posedge clk_i);

    // =========================================================================
    // Test 3: Greška frejma (stop bit = 0)
    // =========================================================================
    $display("\n--- Test 3: Gresja frejma ---");
    fork
      send_byte(8'hBE, 1'b1);
      wait_signal(CLKS_PER_BIT * 15);
    join
    check("T3: frame_err visoka  ", t_ferr == 1'b1);
    check("T3: rx_done niska     ", t_done == 1'b0);
    repeat(CLKS_PER_BIT * 2) @(posedge clk_i);

    // =========================================================================
    // Test 4: Kratki glitch (< pola bita) — DUT mora ostati u IDLE
    // =========================================================================
    $display("\n--- Test 4: Kratki glitch ---");
    rx_i = 1'b0;
    repeat(CLKS_PER_BIT / 4) @(posedge clk_i);
    rx_i = 1'b1;
    repeat(CLKS_PER_BIT * 2) @(posedge clk_i);
    check("T4: Nema done         ", rx_done_o      == 1'b0);
    check("T4: Nema frame_err    ", rx_frame_err_o == 1'b0);
    // Potvrdi da DUT radi normalno posle glitch-a
    fork
      send_byte(8'h7E, 1'b0);
      wait_signal(CLKS_PER_BIT * 15);
    join
    check("T4: DUT radi posle    ", t_done == 1'b1 && rx_data_o == 8'h7E);
    repeat(3) @(posedge clk_i);

    // =========================================================================
    // Test 5: Granične vrednosti 0x00 i 0xFF
    // =========================================================================
    $display("\n--- Test 5: Granicne vrednosti ---");
    fork
      send_byte(8'h00, 1'b0);
      wait_signal(CLKS_PER_BIT * 15);
    join
    check("T5: data == 0x00      ", t_done == 1'b1 && rx_data_o == 8'h00);
    repeat(3) @(posedge clk_i);

    fork
      send_byte(8'hFF, 1'b0);
      wait_signal(CLKS_PER_BIT * 15);
    join
    check("T5: data == 0xFF      ", t_done == 1'b1 && rx_data_o == 8'hFF);

    // =========================================================================
    // Sažetak
    // =========================================================================
    $display("\n========================================");
    $display("Rezultati: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
    $display("========================================");
    if (fail_cnt == 0) $display("Svi testovi su PROSLI!");
    else               $display("Neki testovi su PALI!");
    $finish;
  end

endmodule