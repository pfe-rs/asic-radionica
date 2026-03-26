 module pfe #(
    parameter int DSIZE  = 8,
    parameter int N = 8
)(
    input  logic             clk_i,
    input  logic             rst_ni,
    // Input
    input  logic [DSIZE-1:0] in_data_i,
    input  logic             in_valid_i,
    output logic             in_ready_o,
    // Output
    output logic [DSIZE-1:0] out_data_o,
    output logic             out_valid_o,
    input  logic             out_ready_i,

    output logic [DSIZE-1:0] buff_o_0,
    output logic [DSIZE-1:0] buff_o_1,
    output logic [DSIZE-1:0] buff_o_2,
    output logic [DSIZE-1:0] buff_o_3,
    output logic [DSIZE-1:0] buff_o_4,
    output logic [DSIZE-1:0] buff_o_5,
    output logic [DSIZE-1:0] buff_o_6,
    output logic [DSIZE-1:0] buff_o_7,
    output logic [DSIZE-1:0] reading_i_0,
    output logic [DSIZE-1:0] reading_i_1,
    output logic [DSIZE-1:0] reading_i_2,
    output logic [DSIZE-1:0] reading_i_3,
    output logic [DSIZE-1:0] reading_i_4,
    output logic [DSIZE-1:0] reading_i_5,
    output logic [DSIZE-1:0] reading_i_6,
    output logic [DSIZE-1:0] reading_i_7,
    output logic [DSIZE-1:0] ffs_0,
    output logic [DSIZE-1:0] ffs_1,
    output logic [DSIZE-1:0] ffs_2,
    output logic [DSIZE-1:0] ffs_3,
    output logic [DSIZE-1:0] ffs_4,
    output logic [DSIZE-1:0] ffs_5,
    output logic [DSIZE-1:0] ffs_6,
    output logic [DSIZE-1:0] ffs_7
);
    logic [DSIZE-1:0] reading_i[N];
    logic [DSIZE-1:0] buff_o[N];
    logic [DSIZE-1:0] info_i [N];
    logic [DSIZE-1:0] ffs [N];
    logic state;

    assign in_ready_o = out_ready_i;

    genvar i;
    generate
        for (i = 0; i < N / 2; i++) begin : g_for_cas
            cas # (.N(DSIZE)) i_cas (
                .A_i(ffs[i]),
                .B_i(ffs[i+N/2]),
                .S_i(1'b0),
                .S_A_o(buff_o[2*i]),
                .S_B_o(buff_o[2*i+1])
            );
        end
    endgenerate

    genvar j;
    generate
        for (j = 0; j < N; j++) begin : g_for_mux
            mux # (.DSIZE(DSIZE)) i_mux (
                .input_option1(reading_i[j]),
                .input_option2(buff_o[j]),
                .status(state),
                .output_value(info_i[j])
            );
        end
    endgenerate


    typedef enum logic [1:0] {
        READ    = 2'b00,
        CALC    = 2'b01,
        WRITE   = 2'b10,
        DONE    = 2'b11
    } state_t;
    state_t current_state, next_state;
    logic state_flag;

    localparam int MEM = $clog2(N);
    logic [MEM-1:0] ptr;

    // komponenta za promenu stanja
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            current_state <= READ;
        else if (state_flag)
            current_state <= next_state;
    end

    // komponenta za proveru prelaska u drugo stanje
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ptr <= 0;
            for (int k = 0; k < N; k++) ffs[k] <= 0;
        end
        else begin
            for (int k = 0; k < N; k++) ffs[k] <= info_i[k];
            if (state_flag)
                ptr <= 0;
            else if (in_valid_i) begin
                ptr <= ptr + 1;
            end
        end
    end

    always_comb begin
        case (current_state)
            READ: begin
                state = 0;
                out_valid_o = 0; //dodato
                reading_i[ptr] = in_data_i;
                next_state = CALC;
                state_flag = (ptr === MEM'(N-1));
            end

            CALC: begin
                state = 1;
                next_state = WRITE;
                state_flag = (ptr === 0); // treba da bude jednako MEM'(MEM)
            end

            WRITE: begin
                out_data_o = ffs[ptr];
                out_valid_o = 1;
                next_state = DONE;
                state_flag = (ptr === MEM'(N-1));
            end

            DONE: begin
                // ne znam sta moze da radi kad zavrsi
            end

            default: begin
                next_state = READ;
            end
        endcase
    end

    assign buff_o_0 = buff_o[0];
    assign buff_o_1 = buff_o[1];
    assign buff_o_2 = buff_o[2];
    assign buff_o_3 = buff_o[3];
    assign buff_o_4 = buff_o[4];
    assign buff_o_5 = buff_o[5];
    assign buff_o_6 = buff_o[6];
    assign buff_o_7 = buff_o[7];
    assign reading_i_0 = reading_i[0];
    assign reading_i_1 = reading_i[1];
    assign reading_i_2 = reading_i[2];
    assign reading_i_3 = reading_i[3];
    assign reading_i_4 = reading_i[4];
    assign reading_i_5 = reading_i[5];
    assign reading_i_6 = reading_i[6];
    assign reading_i_7 = reading_i[7];
    assign ffs_0 = ffs[0];
    assign ffs_1 = ffs[1];
    assign ffs_2 = ffs[2];
    assign ffs_3 = ffs[3];
    assign ffs_4 = ffs[4];
    assign ffs_5 = ffs[5];
    assign ffs_6 = ffs[6];
    assign ffs_7 = ffs[7];

endmodule
