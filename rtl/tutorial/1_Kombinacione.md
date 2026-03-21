
# Uvod u jezike za opis hardvera

Jezici za opis hardvera (HDL - Hardware Description Language) su specijalizovani jezici namenjeni za projektovanje i simulaciju **hardvera**. Oni omogućavaju inženjerima da na visokom nivou abstrakcije opišu logičko ponašanje hardvera.Prednosti:
- Praćenje razvoja hardvera na sličan način kao i softver
- Modularnost koda 

Važno: HDL nije klasičan programski jezik, način na koji oni rade **nije** isti kao softver!

## Značajni HDL jezici

### Verilog
Verilog je jedan od najčešće korišćenih HDL jezika. Poznat je po sintaksi sličnoj C-u i fleksibilnosti pri opisivanju digitalnih kola na različitim nivoima abstrakcije. U savremenom svetu standalonge 
Verilog se praktično i ne koristi

### VHDL
VHDL (VHSIC Hardware Description Language) je industrijski standard sa strogom tipizacijom. Često se koristi u kritičnim aplikacijama zahvaljujući svojoj preciznosti i mogućnostima za formalne provere. 

### SystemVerilog
SystemVerilog je proširenje Veriloga koje dodaje napredne mogućnosti za verifikaciju, objektno-orijentisano programiranje i funkcionalnu verifikaciju hardvera. Postaje standard u modernom dizajnu čipova. 

Ovde se fokusiramo na  **SystemVerilog** 

### Simulacije 

Za demonstrativne simulacije koristićemo web alat dostupan na linku 
https://digitaljs.tilk.eu/

# Uvod 

## Kombinacione mreže

### Uvodni primer: Kratak spoj (žica?)

Sledeći primer prikazuje najprostiji mogući SystemVerilog modul koji direktno povezuje ulaz na izlaz:

```verilog
// Kratak spoj
module short(
    input a,
    output b
);

    assign b = a;
    
endmodule
```

**Objašnjenje:**

- `module short` - Deklaracija modula sa nazivom "short"
- `input a` - Ulazni signal "a"
- `output b` - Izlazni signal "b"
- `assign b = a;` - Kontinuelna dodela vrednosti (kombinaciona logika) koja povezuje izlaz "b" direktno sa ulazom "a"
- `endmodule` - Završetak definicije modula


### Dodatni komentari o sintaksi Veriloga

Objašnjenja sintakse iz ovog primera:

- **Zagrade**: U Verilogu, zagrade se koriste za grupisanje izraza i definisanje blokova koda. Na primer, u definiciji modula, zagrade se koriste za označavanje ulaza i izlaza.
  
- **Tačka i zarez (`;`)**: Svaka izjava u Verilogu završava tačkom i zarezom. Ovo je slično C jeziku i označava kraj jedne instrukcije.

- **Komentari**: Verilog podržava jednonaredne komentare koristeći `//` i višenedne komentare koristeći `/* ... */`.

- **Deklaracije**: Verilog koristi ključne reči kao što su `input`, `output`, i `wire` za deklaraciju signala. Ove ključne reči definišu tipove signala i njihovu funkciju unutar modula.

- **Kombinacione dodele**: U Verilogu, `assign` se koristi za kontinuelne dodele, što znači da se vrednost automatski ažurira kada se promeni ulaz.

### Primjer: Jednobitni inverter

Sledeći primer prikazuje jednostavni inverter koji negira ulazni signal:

```verilog
// Jednostavni inverter
module inverter(
    input logic in,
    output logic out
);

    assign out = ~in;
    
endmodule
```

**Objašnjenje:**

- `module inverter` - Deklaracija modula sa nazivom "inverter"
- `input logic in` - Ulazni signal "in" definisan kao `logic` tip
- `output logic [3:0] out` - Izlazni signal "out" koji je 4-bitni vektor tipa `logic`
- `assign out = ~in;` - Kombinaciona dodela vrednosti koja negira ulazni signal korišćenjem operatora `~` (bitwise NOT)
- `endmodule` - Završetak definicije modula

**Napomena:** `logic` je SystemVerilog tip podataka koji je fleksibilniji od osnovnog `wire` tipa i omogućava lakšu verifikaciju koda.


## Šta to radi `if` u hardveru?


### Uvodni primer: Jednobitni multiplekser

Sledeći primer prikazuje jednostavni jednobitni multiplekser koji bira između dva ulaza na osnovu kontrolnog signala:

```verilog
// Jednobitni multiplekser
module mux(
    input a,
    input b,
    input sel,
    output y
);

    always_comb begin
        if (sel) begin
            y = b;
        end else begin
            y = a;
        end
    end
    
endmodule
```

**Objašnjenje:**

- `module mux` - Deklaracija modula sa nazivom "mux"
- `input a` - Ulazni signal "a"
- `input b` - Ulazni signal "b"
- `input sel` - Kontrolni signal "sel" koji određuje koji ulaz se bira
- `output y` - Izlazni signal "y"
- `assign y = sel ? b : a;` - Kombinaciona dodela vrednosti koja koristi ternarni operator za izbor između ulaza `a` i `b` na osnovu vrednosti `sel`
- `endmodule` - Završetak definicije modula



### Prošireni primer: Jednobitni multiplekser sa integer vrednostima

Signali ne moraju biti definisani kao 
bitovi, u SV postoje i složeniji tipovi
podataka. Najfundamentalniji tip jeste 
**vektor**, odnosno niz bitova. Koji se 
može tretirati i kao celi broj. 

```verilog
// Jednobitni multiplekser sa integer vrednostima
module mux_integer(
    input [3:0] a,  // 4-bitni ulazni signal "a"
    input [3:0] b,  // 4-bitni ulazni signal "b"
    input sel,      // Kontrolni signal "sel"
    output [3:0] y  // 4-bitni izlazni signal "y"
);

    always_comb begin
        if (sel) begin
            y = b;
        end else begin
            y = a;
        end
    end
    
endmodule
```

**Objašnjenje:**

- `input [3:0] a` - Ulazni signal "a" koji može imati 4-bitne integer vrednosti
- `input [3:0] b` - Ulazni signal "b" koji može imati 4-bitne integer vrednosti
- `output [3:0] y` - Izlazni signal "y" koji takođe može imati 4-bitne integer vrednosti


### Uopšteni primer: Jednobitni multiplekser sa parametrizovanim brojem bitova

U ovom primeru, koristićemo parametar `N` kako bismo omogućili izbor broja bitova za ulazne signale. Ovaj pristup omogućava veću fleksibilnost i ponovnu upotrebu modula.

```verilog
// Uopšteni jednobitni multiplekser sa parametrizovanim brojem bitova 
module mux_param #(parameter N = 4) (
    input [N-1:0] a,  // N-bitni ulazni signal "a"
    input [N-1:0] b,  // N-bitni ulazni signal "b"
    input sel,        // Kontrolni signal "sel"
    output [N-1:0] y  // N-bitni izlazni signal "y"
);

    assign y = sel ? b : a;  // Izbor između ulaza "a" i "b" na osnovu "sel"
    
endmodule
```

**Objašnjenje:**

- `parameter N = 4` - Definiše parametar `N` koji određuje broj bitova. Podrazumevana vrednost je 4, ali se može promeniti prilikom instanciranja modula.
- `input [N-1:0] a` - Ulazni signal "a" koji može imati `N`-bitne integer vrednosti.
- `input [N-1:0] b` - Ulazni signal "b" koji može imati `N`-bitne integer vrednosti.
- `output [N-1:0] y` - Izlazni signal "y" koji takođe može imati `N`-bitne integer vrednosti.



### Primer: Računanje veće vrednosti

**Stari dobri (softverski) Python kod:**

```python
def max_value(a, b):
    """Vraća veću vrednost od a i b"""
    return a if a > b else b

# Test
result = max_value(5, 3)
print(result)  # Ispisuje: 5
```

* *And now for something completely different...*

ySledeći primer prikazuje modul koji poredi dva ulazna signala i vraća veću vrednost:

```verilog
// Poređenje i izbor veće vrednosti
module max_value #(parameter N = 4) (
    input [N-1:0] a,
    input [N-1:0] b,
    output [N-1:0] max_out
);

    assign max_out = (a > b) ? a : b;  // Ako je a veće od b, izlaz je a, inače b
    
endmodule
```

**Objašnjenje:**

- `(a > b) ? a : b` - Ternarni operator koji poredi ulaze `a` i `b`
- Ako je `a` veće od `b`, izlaz je `a`
- U suprotnom, izlaz je `b`
- Ovo je kombinaciona logika koja se izvršava bez kašnjenja


### Primer: Kombinacione aritmetičke operacije

Sledeći primer prikazuje modul koji izvršava različite aritmetičke i logičke operacije nad dva ulazna signala:

```verilog
// Kombinacione aritmetičke operacije
module arithmetic_ops #(parameter N = 4) (
    input [N-1:0] a,
    input [N-1:0] b,
    output [N-1:0] sum,      // Rezultat sabiranja
    output [N-1:0] diff,     // Rezultat oduzimanja
    output [2*N-1:0] lshift, // Rezultat levog pomeranja
    output [N-1:0] rshift    // Rezultat desnog pomeranja
);

    assign sum = a + b;              // Sabiranje
    assign diff = a - b;             // Oduzimanje
    assign lshift = a << 1;          // Levo pomeranje za b pozicija
    assign rshift = a >> 1;          // Desno pomeranje za b pozicija
    
endmodule
```

**Objašnjenje:**

- `a + b` - Operacija sabiranja dva ulazna signala
- `a - b` - Operacija oduzimanja
- `a << b` - Operacija levog pomeranja ulaza `a` za `b` pozicija (ekvivalentno množenju sa 2^b)
- `a >> b` - Operacija desnog pomeranja ulaza `a` za `b` pozicija (ekvivalentno deljenju sa 2^b)
- `lshift` ima dubinu `2*N-1:0` jer levo pomeranje može zahtevati više bitova za skladištenje rezultata
- Sve operacije su kombinacione, što znači da se rezultati ažuriraju bez kašnjenja kada se promene ulazi


### Primer: Sabiranje označenih brojeva

Sledeći primer prikazuje modul koji sabira dva 4-bitna ulazna signala, uz dodatak oznake za svaki od njih:

```verilog
// Sabiranje označenih brojeva
module labeled_adder(
    input [3:0] a,  // 4-bitni ulazni signal "a"
    input [3:0] b,  // 4-bitni ulazni signal "b"
    output [4:0] sum // 5-bitni izlazni signal "sum" za skladištenje rezultata
);

    assign sum = a + b; // Sabiranje ulaznih signala "a" i "b"
    
endmodule
```

**Objašnjenje:**

- `input [3:0] a` - Ulazni signal "a" koji može imati 4-bitne vrednosti.
- `input [3:0] b` - Ulazni signal "b" koji može imati 4-bitne vrednosti.
- `output [4:0] sum` - Izlazni signal "sum" koji može imati 5-bitne vrednosti kako bi se obezbedilo da se ne izgubi informacija prilikom sabiranja.
- `assign sum = a + b;` - Kombinaciona dodela vrednosti koja sabira ulaze "a" i "b".

**Napomena:** U ovom primeru, koristićemo komplement dvoje za predstavljanje označenih brojeva. Komplement dvoje omogućava jednostavno sabiranje i oduzimanje negativnih brojeva.

### Primer: Sabiranje označenih brojeva u komplementu dvoje

Sledeći primer prikazuje modul koji sabira dva 4-bitna ulazna signala, **označena cela broja** 
za svaki od njih, koristeći komplement dvoje:

```verilog
// Sabiranje označenih brojeva u komplementu dvoje
module labeled_adder_twos_complement(
    input signed [3:0] a,  // 4-bitni ulazni signal "a" u komplementu dvoje
    input signed [3:0] b,  // 4-bitni ulazni signal "b" u komplementu dvoje
    output signed [4:0] sum // 5-bitni izlazni signal "sum" za skladištenje rezultata
);

    assign sum = a + b; // Sabiranje ulaznih signala "a" i "b"
    
endmodule
```

Takođe, signali se mogu 
definisati i kao npr. 

```verilog
input integer a,    // 32-bit signed
input shortint a,   // 16-bit signed
input longint a,    // 64-bit signed
input byte a,       // 8-bit signed
input bit [3:0] a,  // unsigned, 2-state (bez X,Z)
```

## Generisanje lanca sabirača - konstrukt `for`

**Ponašanje suštinski drugačije od proceduralnih 
jezika!**

Ovaj modul demonstrira upotrebu **`genvar`** i **`generate`** konstrukta u SystemVerilog-u za automatsko generisanje više identičnih logičkih blokova.

### Opis:
Modul broji broj postavljenih bitova (1-ova) u 8-bitnom ulaznom signalu. Koristi generativnu logiku da kreira lanac sabirača koji kumulativno sabira bitove ulaza.

### Ključni koncepti:

#### `always_comb` blok
- Definiše deo koda koji opisuje kombinacioni blok. 
- `for (int i = 0; i < 8; i++)` - petlja se ponavlja 8 puta
- Za svaku iteraciju kreira se **novi hardverski blok** (nije kao softverska petlja)

### Rezultat:
Lanac od 8 logičkih blokova koji kumulativno sabira ulazne bitove, čime se dobija broj aktivnih bitova na izlazu `total` [7:0].

```verilog
module sum_bits (
  input  logic [7:0] in,
  output logic [7:0] total
  );

  logic [7:0] s[9];  // unpacked array of N+1 elements

  always_comb begin
    s[0] = 0;
    for (int i = 0; i < 8; i++) begin
      s[i+1] = s[i] + in[i]; 
    end
  end

  assign total = s[8];

endmodule
```


### Uopštenje za _N_-bitne brojeve, uvođenje parametra

```verilog
module sum_bits 
#(parameter N = 8)
(
  input  logic [N-1:0] in,
  output logic [N-1:0] total
);

  logic [N-1:0] s[N+1];  // unpacked array of N+1 elements

  always_comb begin
    s[0] = 0;
    for (int i = 0; i < N; i++) begin
      s[i+1] = s[i] + in[i]; 
    end
  end

  assign total = s[N];

endmodule
```

### Može li (hardverski) efikasnije da se reši? 

Na primer, smatrajući da je N stepen dvojke, da li može bolje?

```verilog
module sum_bits #(
    parameter int N = 16
) (
    input  logic [N-1:0]           in,
    output logic [$clog2(N+1)-1:0] total
);

    localparam int W = $clog2(N+1);

    logic [W-1:0] nodes [1 : 2*N-1];

    genvar i;

    generate
        for (i = 0; i < N; i++) begin : g_leaves
            assign nodes[N + i] = {{W-1{1'b0}}, in[i]};
        end

        for (i = 1; i < N; i++) begin : g_tree
            assign nodes[i] = nodes[2*i] + nodes[2*i+1];
        end
    endgenerate

    assign total = nodes[1];

endmodule
```

a ako N nije stepen dvojke?

```verilog
module sum_bits #(
    parameter int N = 16
) (
    input  logic [N-1:0]            in,
    output logic [$clog2(N+1)-1:0]  total
);

    localparam int W = $clog2(N+1);

    // Pad input up to the next power of 2 so the tree divides evenly
    localparam int N2 = 2**$clog2(N);
    localparam int NP = (N2 < N) ? N2*2 : N2;  // next power of 2 >= N

    logic [W-1:0] nodes [0 : 2*NP-1];  // binary tree stored in flat array
                                       // node 1 = root, leaves at [NP..2*NP-1]

    genvar i;

    // Load leaves: padded positions get 0
    generate
        for (i = 0; i < NP; i++) begin : g_leaves
            if (i < N)
                assign nodes[NP + i] = in[i];
            else
                assign nodes[NP + i] = 0;
        end
    endgenerate

    // Internal nodes: each is sum of its two children
    generate
        for (i = 1; i < NP; i++) begin : g_tree
            assign nodes[i] = nodes[2*i] + nodes[2*i+1];
        end
    endgenerate

    assign total = nodes[1];  // root holds the final sum

endmodule
```

