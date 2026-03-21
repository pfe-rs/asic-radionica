# Bitonično Sortiranje

## 📘 Pregled

**Bitonično sortiranje (Bitonic Sort)** je klasičan algoritam za paralelno sortiranje koji se odlično mapira na hardverske implementacije. Za razliku od softverskih algoritama koji rade sekvencijalno, bitonično sortiranje koristi **fiksnu mrežu komparatora** — što ga čini idealnim za implementaciju u FPGA ili ASIC dizajnu.

### Šta je bitonična sekvenca?

Sekvenca je **bitonična** ako se najpre monotono povećava a zatim monotono smanjuje (ili obrnuto), ili ako se može ciklično rotirati u takav oblik. Na primer:

```
1, 4, 7, 9, 6, 3, 2   ← bitonična (raste pa pada)
5, 3, 1, 2, 4, 8, 6   ← bitonična (pada pa raste)
```

### Princip rada mreže komparatora

Bitonično sortiranje radi u **log₂(N)** faza, a svaka faza ima više **koraka**. U svakom koraku, parovi elemenata se međusobno porede i po potrebi zamenjuju — sve operacije poređenja u jednom koraku su **potpuno paralelne** i nezavisne jedna od druge.

Za N = 8 elemenata, mreža ima **3 faze** (log₂ 8 = 3), a ukupno **6 koraka**:

```
Faza 1:  Korak 1
Faza 2:  Korak 2, Korak 1
Faza 3:  Korak 3, Korak 2, Korak 1
```

Vizuelno za 8 elemenata (svaka linija je žica, `><` je komparator koji sortira par):

```
Korak:    1    2    1    3    2    1
         ─┬─  ─┬─  ─┬─  ─┬─  ─┬─  ─┬─
  a[0]    ><   |   ><   ><   |   ><
  a[1]    ><   |   ><   |    ><  ><
  a[2]    |   ><   ><   |    ><  ><  
  a[3]    |   ><   ><   ><   |   ><
  a[4]    ><   |   ><   ><   |   ><
  a[5]    ><   |   ><   |    ><  ><
  a[6]    |   ><   ><   |    ><  ><
  a[7]    |   ><   ><   ><   |   ><
         ─┴─  ─┴─  ─┴─  ─┴─  ─┴─  ─┴─
```

### Zašto hardverska implementacija?

- **Determinističko vreme izvršavanja** — uvek isti broj koraka, bez zavisnosti od podataka
- **Potpuna paralelnost** — svi komparatori u jednom koraku rade simultano
- **Skalabilnost** — lako se parametrizuje za različite veličine niza
- **Pipeline pogodnost** — svaki korak se može registrovati, što omogućava visoku frekvenciju takta

## ⚙️ Kako Radi

Dizajn koji ćemo implementirati je **potpuno sekvencijalan (pipelined)** bitonični sorter.

- Ulazni niz `data_i` se **registruje na ulazu** prvog stepena cevovoda.
- Svaki korak mreže komparatora je jedan **pipeline stepen** — poređenje i zamena parova se odvijaju kombinaciono, a rezultat se registruje na kraju svakog stepena.
- Signal `valid_i` se **propagira kroz cevovod** zajedno sa podacima — na izlazu, `valid_o` označava da je sortiran niz spreman.
- Ukupno kašnjenje cevovoda je **`NUM_STAGES` taktova**, gde je `NUM_STAGES = (log₂N × (log₂N + 1)) / 2`.
- **Reset:** `rst_ni` je **asinhroni aktivan na niskom nivou**. Reset briše sve pipeline registre i `valid` signale.

### Parametri `DATA_WIDTH` i `NUM_ELEMENTS`

Parametar `NUM_ELEMENTS` mora biti **stepen broja 2** (2, 4, 8, 16, ...). Broj pipeline stepena izračunava se kao:

```
NUM_STAGES = (LOG2N × (LOG2N + 1)) / 2
```

Za N = 8 (LOG2N = 3):

```
NUM_STAGES = (3 × 4) / 2 = 6
```

Što znači da je izlazni rezultat validan **6 taktova** nakon što je `valid_i` bio visok.

## 🔧 Parametri Modula i Interfejs

### Parametri

| Naziv          | Tip  | Podrazumevano | Opis |
|----------------|:----:|:-------------:|------|
| `DATA_WIDTH`   | int  | `8`           | Širina svakog podatkovnog elementa u bitima. |
| `NUM_ELEMENTS` | int  | `8`           | Broj elemenata za sortiranje. Mora biti stepen broja 2. |

---

### Portovi

| Port        | Smer   | Širina                        | Opis |
|-------------|:-------|:-----------------------------:|------|
| `clk_i`     | ulaz   | `1`                           | Sistemski takt. |
| `rst_ni`    | ulaz   | `1`                           | **Asinhroni reset aktivan na niskom nivou.** |
| `valid_i`   | ulaz   | `1`                           | Visoka kada su ulazni podaci validni. |
| `data_i`    | ulaz   | `NUM_ELEMENTS × DATA_WIDTH`   | Ulazni niz upakovan u jednu magistralu (element 0 na LSB poziciji). |
| `data_o`    | izlaz  | `NUM_ELEMENTS × DATA_WIDTH`   | Sortiran niz (rastuće), upakovan identično kao ulaz. |
| `valid_o`   | izlaz  | `1`                           | Visoka kada su izlazni podaci validni (posle `NUM_STAGES` taktova). |

### Pakovanje podataka

Niz se pakuje u magistralu po sledećem pravilu:

```
data_i = { a[N-1], a[N-2], ..., a[1], a[0] }
         ← MSB                           LSB →
```

Odnosno, element `a[k]` se nalazi na pozicijama `[k*DATA_WIDTH +: DATA_WIDTH]`.

## 💻 Implementacija u SystemVerilog-u

Vaš zadatak je da napišete **parametrizovanu pipeline implementaciju** bitoničnog sortera u SystemVerilog-u koristeći dati interfejs.

```verilog
module bitonic_sort #(
  parameter int DATA_WIDTH   = 8,
  parameter int NUM_ELEMENTS = 8
) (
  input  logic                              clk_i,
  input  logic                              rst_ni,
  input  logic                              valid_i,
  input  logic [NUM_ELEMENTS*DATA_WIDTH-1:0] data_i,
  output logic [NUM_ELEMENTS*DATA_WIDTH-1:0] data_o,
  output logic                              valid_o
);

  // Vaš kod ovde

endmodule
```

Dati modul se nalazi u folderu **rtl**, a testbench je u folderu **dv**.

## 🛠️ Kako Pokrenuti

Koristite priloženi **Makefile** za izgradnju, pokretanje i proveru projekta.

### 1. Pokretanje Verilator lintera

Proverite dizajn modul na greške:
```bash
make lint_dut
```

Proverite testbench fajl na greške:
```bash
make lint_tb
```

### 2. Pokretanje Testbench-a

Kompajlirajte i pokrenite testbench:
```bash
make all
```

### 3. Čišćenje Foldera

Uklonite sve fajlove izgradnje i simulacije:
```bash
make clean
```

## 📝 Napomene za Implementaciju

- Koristite `generate` blokove za kreiranje pipeline stepena — rešenje ne sme biti hardkodovano za određenu vrednost `NUM_ELEMENTS`.
- Za svaki korak mreže, odredite koji parovi elemenata se porede i u kom smeru.
- Pratite `valid` signal kroz cevovod koristeći shift registar dužine `NUM_STAGES`.
- Vodite računa o **smeru poređenja** (uzlazno vs silazno) pri izgradnji bitoničnih sekvenci — alternira se po blokovima.