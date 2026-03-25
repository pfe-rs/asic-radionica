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

    output logic [DSIZE-1:0] temp1,
    output logic [DSIZE-1:0] temp2,
    output logic [DSIZE-1:0] temp3,
    output logic [DSIZE-1:0] temp4,
    output logic [DSIZE-1:0] temp5,
    output logic [DSIZE-1:0] temp6,
    output logic [DSIZE-1:0] temp7,
    output logic [DSIZE-1:0] temp8,
    output logic temp9,
    output logic tempa,
    output logic tempb,
    output logic [DSIZE-1:0] temp11,
    output logic [DSIZE-1:0] temp21,
    output logic [DSIZE-1:0] temp31,
    output logic [DSIZE-1:0] temp41,
    output logic [DSIZE-1:0] temp51,
    output logic [DSIZE-1:0] temp61,
    output logic [DSIZE-1:0] temp71,
    output logic [DSIZE-1:0] temp81,
    output logic temp91,
    output logic tempa1,
    output logic tempb1
);
    logic [DSIZE-1:0] reading_i[N];
    logic [DSIZE-1:0] buff_o[N];
    logic [DSIZE-1:0] info_i [N];
    logic [DSIZE-1:0] ffs [N];
    logic state;

    logic oo[N/2];
    logic oa[N/2];
    logic ob[N/2];

    genvar i;
    generate
        for (i = 0; i < N / 2; i++) begin : g_for_cas
            cas # (.N(DSIZE)) i_cas (
                .A_i(ffs[i]),
                .B_i(ffs[i+N/2]),
                .S_i(1'b0),
                .S_A_o(buff_o[i]),
                .S_B_o(buff_o[i+N/2]),
                .oo(oo[i]),
                .oa(oa[i]),
                .ob(ob[i])
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
        if (!rst_ni) begin
            current_state <= READ;
            for (int i = 0; i < N; i++) ffs[i] <= 0;
        end
        else begin
            if (state_flag) 
                current_state <= next_state;
            for (int i = 0; i < N; i++) ffs[i] <= info_i[i];
        end
    end

    // komponenta za proveru prelaska u drugo stanje
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            ptr <= 0;
        else if (state_flag)
            ptr <= 0;
        else if (in_valid_i)
            ptr <= ptr + 1;
    end

    always_comb begin
        case (current_state)
            READ: begin
                state = 0;
                out_valid_o = 0; //dodato
                reading_i[ptr] = in_data_i;
                next_state = CALC;
                state_flag = (ptr === MEM'(N-1));
                state_flag = (ptr === MEM'(MEM));
            end

            CALC: begin
                state = 1;
                next_state = WRITE;
            end

            WRITE: begin
                out_data_o = info_i[ptr];
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

    assign temp1 = ffs[0];
    assign temp2 = ffs[N/2];
    assign temp3 = info_i[0];
    assign temp4 = info_i[N/2];
    assign temp5 = reading_i[0];
    assign temp6 = reading_i[N/2];
    assign temp7 = buff_o[0];
    assign temp8 = buff_o[N/2];
    assign temp9 = oo[0];
    assign tempa = oa[0];
    assign tempb = ob[0];

    assign temp11 = ffs[1];
    assign temp21 = ffs[1+N/2];
    assign temp31 = info_i[1];
    assign temp41 = info_i[1+N/2];
    assign temp51 = reading_i[1];
    assign temp61 = reading_i[1+N/2];
    assign temp71 = buff_o[1];
    assign temp81 = buff_o[1+N/2];
    assign temp91 = oo[1];
    assign tempa1 = oa[1];
    assign tempb1 = ob[1];

endmodule

