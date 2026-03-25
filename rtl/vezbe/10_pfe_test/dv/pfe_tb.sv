module pfe_tb;

    localparam bit VERBOSE    = 1;
    localparam int DSIZE      = 24;
    localparam int NUM_INPUTS = 80;

    logic             clk_i, rst_ni;
    logic             btn;               // NEW
    logic [DSIZE-1:0] in_data_i;
    logic             in_valid_i, in_ready_o;
    logic [DSIZE-1:0] out_data_o;
    logic             out_valid_o, out_ready_i;

    logic [DSIZE-1:0] sample_q[$];
    logic [9:0]       expected_word_q[$];
    int               sent_count, recv_count;

    pfe #(.DSIZE(DSIZE)) dut (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .btn        (btn),               // NEW
        .in_data_i  (in_data_i),
        .in_valid_i (in_valid_i),
        .in_ready_o (in_ready_o),
        .out_data_o (out_data_o),
        .out_valid_o(out_valid_o),
        .out_ready_i(out_ready_i)
    );

    initial begin
        clk_i = 1'b0;
        forever #5 clk_i = ~clk_i;
    end

    // ----------------------------------------------------------------
    // Task: send one word and register expected output
    // ----------------------------------------------------------------
    task automatic send_sample(
        input logic [3:0]       opcode,
        input logic signed [7:0] a,
        input logic signed [7:0] b
    );
        logic signed [7:0] result;
        logic zero, overflow;

        case (opcode)
            4'd0: begin
                result   = a + b;
                zero     = (result == 0);
                overflow = (a[7] == b[7]) && (result[7] != a[7]);
            end
            4'd1: begin
                result   = a - b;
                zero     = (a == b);
                overflow = (a[7] != b[7]) && (result[7] != a[7]);
            end
            4'd2: begin result=(a>b)?a:b; zero=(result==0); overflow=0; end
            4'd3: begin result=(a>b)?b:a; zero=(result==0); overflow=0; end
            4'd4: begin result=(a==b)?8'd1:8'd0; zero=(result==0); overflow=0; end
            4'd5: begin result=a<<b; zero=(result==0); overflow=(result<0); end
            4'd6: begin result=a>>b; zero=(result==0); overflow=0; end
            4'd7: begin result=a&b;  zero=(result==0); overflow=0; end
            4'd8: begin result=a|b;  zero=(result==0); overflow=0; end
            4'd9: begin result=a^b;  zero=(result==0); overflow=0; end
            default: begin result=8'hFF; zero=1; overflow=0; end
        endcase

        sample_q.push_back({opcode, a, b, 4'b0});
        expected_word_q.push_back({result, zero, overflow});

        if (VERBOSE)
            $display("Queue sample: opcode=%0d A=%0d B=%0d -> result=%0d z=%0d ov=%0d",
                     opcode, a, b, result, zero, overflow);
    endtask

    // ----------------------------------------------------------------
    // Task: pulse btn for one clock (ANS button press)
    // ----------------------------------------------------------------
    task press_ans_btn();
        @(posedge clk_i);
        btn = 1'b1;
        @(posedge clk_i);
        btn = 1'b0;
        if (VERBOSE) $display("[%0t] ANS button pressed", $time);
    endtask

    // ----------------------------------------------------------------
    // Stimulus
    // ----------------------------------------------------------------
    initial begin
        logic signed [7:0] a, b, last_result;
        logic [3:0] opcode;

        rst_ni      = 1'b0;
        btn         = 1'b0;
        in_data_i   = '0;
        in_valid_i  = 1'b0;
        out_ready_i = 1'b1;
        sent_count  = 0;
        recv_count  = 0;

        // ---- Phase 1: random tests WITHOUT ANS (same as before) ----
        for (int i = 0; i < NUM_INPUTS; i++) begin
            opcode = $urandom();
            a      = $urandom();
            b      = $urandom();
            send_sample(opcode, a, b);
        end

        // ---- Phase 2: ANS chained tests ----
        // First operation: 10 + 20 = 30
        a = 8'sd10; b = 8'sd20; opcode = 4'd0;
        send_sample(opcode, a, b);
        last_result = a + b;   // 30

        // Press ANS, then: ANS - 5  =>  30 - 5 = 25
        // When ANS mode is active, the 'a' field in the packet is ignored by DUT
        // We still need to send *something* in [19:12], put 0 there
        // The expected computation uses last_result as a
        a = 8'sd0; b = 8'sd5; opcode = 4'd1;
        // manually push expected: last_result - b
        begin
            logic signed [7:0] res;
            logic zf, ovf;
            res = last_result - b;
            zf  = (last_result == b);
            ovf = (last_result[7] != b[7]) && (res[7] != last_result[7]);
            sample_q.push_back({opcode, a, b, 4'b0});
            expected_word_q.push_back({res, zf, ovf});
            last_result = res;  // 25
            if (VERBOSE)
                $display("ANS test: ANS(%0d) - %0d -> result=%0d z=%0d ov=%0d",
                         8'sd30, b, res, zf, ovf);
        end

        // Press ANS again: ANS * ... not in ISA, so do ANS | 8  => 25 | 8 = 29
        a = 8'sd0; b = 8'sd8; opcode = 4'd8;
        begin
            logic signed [7:0] res;
            logic zf, ovf;
            res = last_result | b;
            zf  = (res == 0);
            ovf = 0;
            sample_q.push_back({opcode, a, b, 4'b0});
            expected_word_q.push_back({res, zf, ovf});
            last_result = res;
            if (VERBOSE)
                $display("ANS test: ANS(%0d) | %0d -> result=%0d z=%0d ov=%0d",
                         8'sd25, b, res, zf, ovf);
        end

        // ---- Now drive the clock and send everything ----
        repeat (5) @(posedge clk_i);
        rst_ni = 1'b1;
        @(posedge clk_i);

        // Send the NUM_INPUTS random samples normally
        for (int i = 0; i < NUM_INPUTS; i++) begin
            in_data_i  = sample_q[i];
            in_valid_i = 1'b1;
            if (VERBOSE)
                $display("[%0t] OFFER sample[%0d] = 0x%0h", $time, i, sample_q[i]);
            @(posedge clk_i);
            while (!in_ready_o) @(posedge clk_i);
            sent_count++;
        end
        in_valid_i = 1'b0;

        // Wait a few cycles for the result to come back, then press ANS
        repeat (3) @(posedge clk_i);
        press_ans_btn();

        // Send ANS chained sample 1 (NUM_INPUTS + 0): 30 - 5
        in_data_i  = sample_q[NUM_INPUTS];
        in_valid_i = 1'b1;
        @(posedge clk_i);
        while (!in_ready_o) @(posedge clk_i);
        sent_count++;
        in_valid_i = 1'b0;

        // Wait, press ANS again for chained sample 2
        repeat (3) @(posedge clk_i);
        press_ans_btn();

        in_data_i  = sample_q[NUM_INPUTS + 1];
        in_valid_i = 1'b1;
        @(posedge clk_i);
        while (!in_ready_o) @(posedge clk_i);
        sent_count++;
        in_valid_i = 1'b0;

        // Wait for checker to finish
        repeat (20) @(posedge clk_i);
    end

    // ----------------------------------------------------------------
    // Output checker (unchanged logic, works for all samples)
    // ----------------------------------------------------------------
    logic signed [7:0] out_result, expected_result;
    logic out_zero, out_overflow;
    logic expected_zero, expected_overflow;
    logic [9:0] expected_word;

    always @(posedge clk_i) begin
        if (rst_ni && out_valid_o && out_ready_i) begin
            if (expected_word_q.size() == 0) begin
                $error("Unexpected output at word %0d: 0x%0h", recv_count, out_data_o);
                $finish;
            end

            out_result   = out_data_o[9:2];
            out_zero     = out_data_o[1];
            out_overflow = out_data_o[0];

            expected_word     = expected_word_q[0];
            expected_result   = expected_word[9:2];
            expected_zero     = expected_word[1];
            expected_overflow = expected_word[0];

            if (VERBOSE)
                $display("[%0t] CHECK word %0d: expected=%0d got=%0d (z exp=%0d got=%0d, ov exp=%0d got=%0d)",
                         $time, recv_count,
                         expected_result, out_result,
                         expected_zero,   out_zero,
                         expected_overflow, out_overflow);

            if (out_result !== expected_result)
                $error("Result mismatch at word %0d: expected=%0d got=%0d",
                       recv_count, expected_result, out_result);
            if (out_zero !== expected_zero)
                $error("Zero flag mismatch at word %0d: expected=%0d got=%0d",
                       recv_count, expected_zero, out_zero);
            if (out_overflow !== expected_overflow)
                $error("Overflow flag mismatch at word %0d: expected=%0d got=%0d",
                       recv_count, expected_overflow, out_overflow);

            void'(expected_word_q.pop_front());
            recv_count = recv_count + 1;

            if (expected_word_q.size() == 0) begin
                $display("PASS: all %0d output words matched", recv_count);
                $finish;
            end
        end
    end

    initial begin
        #200000;
        $error("Timeout — only %0d/%0d outputs received", recv_count, sent_count);
        $finish;
    end

endmodule