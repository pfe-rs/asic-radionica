# UART Prijemnik

## 📘 Pregled
**UART (Universal Asynchronous Receiver/Transmitter)** je jedan od najrasprostranjenijih protokola za serijsku komunikaciju. Za razliku od sinhronih protokola, UART **ne koristi zajednički takt** između predajnika i prijemnika — umesto toga, oba uređaja su unapred dogovorena o brzini prenosa podataka (**baud rate**), a prijemnik sam detektuje granice bitova.

**Kako izgleda UART okvir**

Linija miruje na logičkoj **1** (idle stanje). Svaki okvir se sastoji od:
1. **Start bit** — jedan bit na logičkoj `0` koji signalizuje početak prenosa.
2. **Podatkovni bitovi** — tipično 8 bitova, slani od LSB ka MSB.
3. **Stop bit** — jedan bit na logičkoj `1` koji potvrđuje kraj okvira.

**Zašto koristimo over-sampling?**
- Prijemnik ne zna tačno kada je start bit stigao u odnosu na sopstveni takt.
- Merenjem linije **16× češće** nego što traje jedan bit, prijemnik može da se uskladi sa sredinom svakog bita i tako minimizuje grešku uzorkovanja.

**Kratki primer (8N1 format, bez pariteta)**

```
idle  start   D0  D1  D2  D3  D4  D5  D6  D7  stop  idle
 1     0       b   b   b   b   b   b   b   b    1     1
```

## ⚙️ Kako Radi

Dizajn koji ćemo implementirati koristi **16× over-sampling** baud clock-a.

- Ulazni signal `rx_i` se **dvostruko registruje** (double flip-flop synchronizer) kako bi se izbegli metastabilnost problemi pri prelasku sa asinhrnog ulaza na sinhrani dizajn.
- Prijemnik detektuje **padajuću ivicu** start bita (`1→0`) kako bi pokrenuo brojač taktova.
- Čeka se **8 perioda baud clock-a** (pola bita) da bi se pozicionirao u sredinu start bita i potvrdio da je stvarno start bit (a ne šum).
- Potom se uzorkuje po jedan bit na svakih **16 perioda baud clock-a** (sredina svakog bita), ukupno 8 podatkovnih bitova.
- Na kraju se uzorkuje **stop bit** — ukoliko nije `1`, postavlja se zastavica greške `rx_frame_err_o`.
- Kada je prijem završen i stop bit validan, postavlja se `rx_done_o` na jedan takt i `rx_data_o` sadrži primljeni bajt.
- **Reset:** `rst_ni` je **asinhroni aktivan na niskom nivou**. Reset briše sve interne registre i vraća prijemnik u idle stanje.

### Parametar `CLK_FREQ` i `BAUD_RATE`

Broj taktova sistema koji odgovara jednom **baud clock** periodu računa se kao:

```
CLKS_PER_BIT = CLK_FREQ / BAUD_RATE
```

Na primer, za sistemski takt od 50 MHz i baud rate od 115200:

```
CLKS_PER_BIT = 50_000_000 / 115_200 ≈ 434
```

## 🔧 Parametri Modula i Interfejs

### Parametri
| Naziv        | Tip  | Podrazumevano | Opis |
|--------------|:----:|:-------------:|------|
| `CLK_FREQ`   | int  | `50_000_000`  | Frekvencija sistemskog takta u Hz. |
| `BAUD_RATE`  | int  | `115_200`     | Željena brzina prenosa (baud/s). |

---

### Portovi
| Port              | Smer   | Širina | Opis |
|-------------------|:-------|:------:|------|
| `clk_i`           | ulaz   | `1`    | Sistemski takt. |
| `rst_ni`          | ulaz   | `1`    | **Asinhroni reset aktivan na niskom nivou.** |
| `rx_i`            | ulaz   | `1`    | Serijska RX linija (idle = `1`). |
| `rx_data_o`       | izlaz  | `8`    | Primljenih 8 podatkovnih bitova (LSB prvi). |
| `rx_done_o`       | izlaz  | `1`    | Visoka **jedan takt** kada je bajt uspešno primljen. |
| `rx_frame_err_o`  | izlaz  | `1`    | Visoka **jedan takt** kada stop bit nije detektovan kao `1`. |

## 💻 Implementacija u SystemVerilog-u
Vaš zadatak je da napišete **parametrizovanu implementaciju** **UART prijemnika** u SystemVerilog-u koristeći dati interfejs.

```verilog
module uart_rx #(
  parameter int CLK_FREQ  = 50_000_000,
  parameter int BAUD_RATE = 115_200
) (
  input  logic       clk_i,          // sistemski takt
  input  logic       rst_ni,         // asinhroni reset aktivan na niskom nivou
  input  logic       rx_i,           // serijska RX linija
  output logic [7:0] rx_data_o,      // primljeni bajt
  output logic       rx_done_o,      // puls: bajt primljen
  output logic       rx_frame_err_o  // puls: greška stop bita
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