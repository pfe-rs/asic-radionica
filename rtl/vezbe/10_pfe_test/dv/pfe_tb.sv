`timescale 1ns/1ps
module pfe_tb;
    logic clk;
    logic rst_n;
    logic [255:0] instruction_memory;
    logic in_valid;
    logic in_ready;
    logic [255:0] out_data;
    logic out_valid;
    logic out_ready;

pfe uut (
        .clk_i(clk),
        .rst_ni(rst_n),
        .in_data_i(instruction_memory),
        .in_valid_i(in_valid),
        .in_ready_o(in_ready),
        .out_data_o(out_data),
        .out_valid_o(out_valid),
        .out_ready_i(out_ready)
    );

always #5 clk = ~clk;

task set_instruction(input int index, input [7:0] instr);
    instruction_memory[index*8 +: 8] = instr;
endtask

function automatic [7:0] get_byte(input [255:0] data, input int index);
    return data[index*8 +: 8];
endfunction

task do_reset;
begin
    rst_n = 0;
    #20;
    rst_n = 1;
end
endtask

// Povećano na #400 jer duzi programi trebaju vise ciklusa
task check_result(
    input string test_name,
    input [7:0] expected
);
    #400;
    if (get_byte(out_data, 15) === expected)
        $display("%s: PASS ✅ (value=%0d)", test_name, get_byte(out_data,15));
    else
        $display("%s: FAILED ❌ (expected=%0d, got=%0d)",
                 test_name, expected, get_byte(out_data,15));
endtask

initial begin
    clk     = 0;
    rst_n   = 0;
    in_valid = 1;
    out_ready = 1;

    // =========================
    // TEST 1: HALT odmah
    // tape[15] = 16 (init: i+1)
    // =========================
    instruction_memory = 0;
    set_instruction(0, 8'b00000_101); // HALT
    do_reset();
    check_result("TEST 1 (HALT odmah)", 16);

    // =========================
    // TEST 2: PLUS x2 → 18
    // =========================
    instruction_memory = 0;
    set_instruction(0, 8'b00000_011); // PLUS
    set_instruction(1, 8'b00000_011); // PLUS
    set_instruction(2, 8'b00000_101); // HALT
    do_reset();
    check_result("TEST 2 (PLUS x2)", 18);

    // =========================
    // TEST 3: MINUS x1 → 15
    // =========================
    instruction_memory = 0;
    set_instruction(0, 8'b00000_010); // MINUS
    set_instruction(1, 8'b00000_101); // HALT
    do_reset();
    check_result("TEST 3 (MINUS x1)", 15);

    // =========================
    // TEST 4: SHIFT LEFT x1
    // tape[15] <- stari tape[14] = 15
    // =========================
    instruction_memory = 0;
    set_instruction(0, 8'b00000_000); // LEFT SHIFT
    set_instruction(1, 8'b00000_101); // HALT
    do_reset();
    check_result("TEST 4 (SHIFT LEFT x1)", 15);

    // =========================
    // TEST 5: MINUS x3 → 16-3 = 13
    // =========================
    instruction_memory = 0;
    set_instruction(0, 8'b00000_010); // MINUS
    set_instruction(1, 8'b00000_010); // MINUS
    set_instruction(2, 8'b00000_010); // MINUS
    set_instruction(3, 8'b00000_101); // HALT
    do_reset();
    check_result("TEST 5 (MINUS x3)", 13);

    // =========================
    // TEST 6: PLUS x5 → 16+5 = 21
    // =========================
    instruction_memory = 0;
    set_instruction(0, 8'b00000_011); // PLUS
    set_instruction(1, 8'b00000_011); // PLUS
    set_instruction(2, 8'b00000_011); // PLUS
    set_instruction(3, 8'b00000_011); // PLUS
    set_instruction(4, 8'b00000_011); // PLUS
    set_instruction(5, 8'b00000_101); // HALT
    do_reset();
    check_result("TEST 6 (PLUS x5)", 21);

    // =========================
    // TEST 7: SHIFT RIGHT x1
    // tape[15] <- stari tape[16] = 17
    // =========================
    instruction_memory = 0;
    set_instruction(0, 8'b00000_001); // RIGHT SHIFT
    set_instruction(1, 8'b00000_101); // HALT
    do_reset();
    check_result("TEST 7 (SHIFT RIGHT x1)", 17);

    // =========================
    // TEST 8: SHIFT RIGHT x2
    // tape[15] <- stari tape[17] = 18
    // =========================
    instruction_memory = 0;
    set_instruction(0, 8'b00000_001); // RIGHT SHIFT
    set_instruction(1, 8'b00000_001); // RIGHT SHIFT
    set_instruction(2, 8'b00000_101); // HALT
    do_reset();
    check_result("TEST 8 (SHIFT RIGHT x2)", 18);

    // =========================
    // TEST 9: SHIFT LEFT x2
    // tape[15] <- stari tape[13] = 14
    // =========================
    instruction_memory = 0;
    set_instruction(0, 8'b00000_000); // LEFT SHIFT
    set_instruction(1, 8'b00000_000); // LEFT SHIFT
    set_instruction(2, 8'b00000_101); // HALT
    do_reset();
    check_result("TEST 9 (SHIFT LEFT x2)", 14);

    // =========================
    // TEST 10: PLUS pa MINUS → 16+1-1 = 16
    // =========================
    instruction_memory = 0;
    set_instruction(0, 8'b00000_011); // PLUS
    set_instruction(1, 8'b00000_010); // MINUS
    set_instruction(2, 8'b00000_101); // HALT
    do_reset();
    check_result("TEST 10 (PLUS pa MINUS)", 16);

    // =========================
    // TEST 11: SHIFT RIGHT pa PLUS
    // tape[15] = 17, +1 = 18
    // =========================
    instruction_memory = 0;
    set_instruction(0, 8'b00000_001); // RIGHT SHIFT
    set_instruction(1, 8'b00000_011); // PLUS
    set_instruction(2, 8'b00000_101); // HALT
    do_reset();
    check_result("TEST 11 (SHIFT RIGHT + PLUS)", 18);

    // =========================
    // TEST 12: SHIFT LEFT pa MINUS
    // tape[15] = 15, -1 = 14
    // =========================
    instruction_memory = 0;
    set_instruction(0, 8'b00000_000); // LEFT SHIFT
    set_instruction(1, 8'b00000_010); // MINUS
    set_instruction(2, 8'b00000_101); // HALT
    do_reset();
    check_result("TEST 12 (SHIFT LEFT + MINUS)", 14);

    // =========================
    // TEST 13: IF_JUMP kad je vrednost != 0
    // operand=2 → preskoci PLUS na pc=1, idi na HALT na pc=2
    // ocekivano: 16 (PLUS preskocen)
    // =========================
    instruction_memory = 0;
    set_instruction(0, 8'b00010_100); // IF_JUMP, operand=2
    set_instruction(1, 8'b00000_011); // PLUS (preskocen)
    set_instruction(2, 8'b00000_101); // HALT
    do_reset();
    check_result("TEST 13 (IF_JUMP nonzero, preskoci PLUS)", 16);

    // =========================
    // TEST 14: IF_JUMP kad je vrednost != 0, preskoci MINUS
    // ocekivano: 16 (MINUS preskocen)
    // =========================
    instruction_memory = 0;
    set_instruction(0, 8'b00010_100); // IF_JUMP, operand=2
    set_instruction(1, 8'b00000_010); // MINUS (preskocen)
    set_instruction(2, 8'b00000_101); // HALT
    do_reset();
    check_result("TEST 14 (IF_JUMP nonzero, preskoci MINUS)", 16);

    // =========================
    // TEST 15: SHIFT LEFT x3
    // tape[15] <- stari tape[12] = 13
    // =========================
    instruction_memory = 0;
    set_instruction(0, 8'b00000_000); // LEFT SHIFT
    set_instruction(1, 8'b00000_000); // LEFT SHIFT
    set_instruction(2, 8'b00000_000); // LEFT SHIFT
    set_instruction(3, 8'b00000_101); // HALT
    do_reset();
    check_result("TEST 15 (SHIFT LEFT x3)", 13);

    // =========================
    // TEST 16: SHIFT RIGHT x3
    // tape[15] <- stari tape[18] = 19
    // =========================
    instruction_memory = 0;
    set_instruction(0, 8'b00000_001); // RIGHT SHIFT
    set_instruction(1, 8'b00000_001); // RIGHT SHIFT
    set_instruction(2, 8'b00000_001); // RIGHT SHIFT
    set_instruction(3, 8'b00000_101); // HALT
    do_reset();
    check_result("TEST 16 (SHIFT RIGHT x3)", 19);

    // =========================
    // TEST 17: PLUS x3 pa SHIFT LEFT
    // tape[15] postaje 19, snimi, shift → tape[15] = stari tape[14] = 15
    // Proveravamo da shift ne koristi azurirani head nego staro stanje
    // ocekivano: 15
    // =========================
    instruction_memory = 0;
    set_instruction(0, 8'b00000_011); // PLUS
    set_instruction(1, 8'b00000_011); // PLUS
    set_instruction(2, 8'b00000_011); // PLUS
    set_instruction(3, 8'b00000_000); // LEFT SHIFT
    set_instruction(4, 8'b00000_101); // HALT
    do_reset();
    check_result("TEST 17 (PLUS x3 pa SHIFT LEFT)", 15);

    // =========================
    // TEST 18: PLUS x3 pa SHIFT RIGHT
    // tape[15]=19 posle plus, shift → tape[15] = stari tape[16] = 17
    // ocekivano: 17
    // =========================
    instruction_memory = 0;
    set_instruction(0, 8'b00000_011); // PLUS
    set_instruction(1, 8'b00000_011); // PLUS
    set_instruction(2, 8'b00000_011); // PLUS
    set_instruction(3, 8'b00000_001); // RIGHT SHIFT
    set_instruction(4, 8'b00000_101); // HALT
    do_reset();
    check_result("TEST 18 (PLUS x3 pa SHIFT RIGHT)", 17);

    $display("=== ALL TESTS DONE ===");
    $stop;
end
endmodule