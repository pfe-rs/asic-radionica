## Specifične digitalne stvari

## Pipeline

Da li postoji neki potencijalni problem sa sledećim hardverom?

Implementirati modul `pixel_scaler` koji vrši skaliranje osvetljenosti piksela u dva koraka: prvo oduzima nivo crne (`black_level`) od ulazne vrednosti piksela (`pixel`), pri čemu rezultat ne sme biti negativan, a zatim množi dobijenu vrednost faktorom pojačanja (`gain`) i stešnjava (*clamp*) rezultat na maksimalnu vrednost koja se može predstaviti sa `W` bita — sve parametrizovano širinom reči `W` — pri čemu je zadatak implementirati ovo jednom u obliku trostepenog pajplajna gde svaki stepen obavlja jednu operaciju i registruje rezultat, i jednom bez pajplajna gde se cela kombinaciona logika izvršava u jednom taktu pre izlaznog registra, kako bi se ilustrovala razlika u kritičnoj putanji, broju registara i kašnjenju između ova dva pristupa.

### Rešenje?
```verilog
module pixel_scaler #(
    parameter int W = 8
) (
    input  logic           clk,
    input  logic           rst_n,
    input  logic [W-1:0]   pixel,
    input  logic [W-1:0]   black_level,
    input  logic [W-1:0]   gain,
    output logic [W-1:0]   scaled
);

    localparam int MAX = (1 << W) - 1;

    logic [W-1:0]   shifted;
    logic [2*W-1:0] product;

    always_comb begin
        shifted = (pixel > black_level) ? pixel - black_level : '0;
        product = shifted * gain;
        end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            scaled <= '0;
        else
            scaled <= (product > MAX) ? MAX[W-1:0] : product[W-1:0];
    end

endmodule
```

## Bolje rešenje?

```verilog
module pixel_scaler #(
    parameter int W = 8
) (
    input  logic           clk,
    input  logic           rst_n,
    input  logic [W-1:0]   pixel,
    input  logic [W-1:0]   black_level,
    input  logic [W-1:0]   gain,          // fixed-point gain factor
    output logic [W-1:0]   scaled
);

    localparam int MAX = (1 << W) - 1;

    // Stage 1: subtract black level (clamp to 0 if underflow)
    logic [W-1:0] s1_shifted;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            s1_shifted <= '0;
        else
            s1_shifted <= (pixel > black_level) ? pixel - black_level : '0;
    end

    // Stage 2: multiply by gain
    logic [2*W-1:0] s2_product;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            s2_product <= '0;
        else
            s2_product <= s1_shifted * gain;
    end

    // Stage 3: clamp to output range
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            scaled <= '0;
        else
            scaled <= (s2_product > MAX) ? MAX[W-1:0] : s2_product[W-1:0];
    end

endmodule
```


## Ready i Valid, sinhronizacija stages 

Ready-Valid protokol je mehanizam za prenos podataka između dva modula u kojima predajnik podiže signal `valid` kada ima podatak spreman za slanje i drži ga stabilnim sve dok ne dođe do prenosa, dok prijemnik podiže signal `ready` kada može da prihvati podatak, a stvarni prenos se dešava isključivo u onom taktnom ciklusu kada su oba signala istovremeno visoka — što znači da ako je `valid` visok a `ready` nizak, predajnik mora da čeka bez povlačenja podatka, a ako je `ready` visok a `valid` nizak, prijemnik samo čeka, pri čemu signal `ready` sme da zavisi od `valid`, ali `valid` nikada ne sme da čeka na `ready` kako bi se izbeglo kružno čekanje — u prikazanoj implementaciji ovo je realizovano kao jednoelementni elastični bafer koji prihvata novi podatak od uzvodnog modula kada je bafer prazan (`up_ready = !buf_valid`) i prosleđuje ga nizvodnom modulu kada je on spreman da ga preuzme.

```verilog
module ready_valid #(
    parameter int W = 8
) (
    input  logic           clk,
    input  logic           rst_n,

    // upstream (sender)
    input  logic           up_valid,
    output logic           up_ready,
    input  logic [W-1:0]   up_data,

    // downstream (receiver)
    output logic           dn_valid,
    input  logic           dn_ready,
    output logic [W-1:0]   dn_data
);

    logic [W-1:0] buf_data;
    logic         buf_valid;

    // upstream ready: we can accept if buffer is empty
    assign up_ready = !buf_valid;

    // downstream drives what is in the buffer
    assign dn_valid = buf_valid;
    assign dn_data  = buf_data;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buf_valid <= 1'b0;
            buf_data  <= '0;
        end else begin
            if (buf_valid && dn_ready) begin
                // downstream consumed the data
                buf_valid <= 1'b0;
            end
            if (up_valid && up_ready) begin
                // upstream delivered new data
                buf_valid <= 1'b1;
                buf_data  <= up_data;
            end
        end
    end

endmodule
```