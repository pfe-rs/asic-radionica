# FIFO bafer

## 📘 Pregled
**FIFO (First-In, First-Out)** može se posmatrati kao mala kutija za skladištenje (*bafer*) koja čuva podatke **istim redosledom kojim su stigli**. Možete ga zamisliti kao red u menzi: **prva** osoba koja stane u red, **prva** biva uslužena. FIFO radi isto to sa podacima.

**Zašto ga koristimo**
- Za **premošćavanje različitih brzina**: brzi proizvođač može ubacivati vrednosti u FIFO dok ih sporiji potrošač preuzima kasnije.
- Za **ublažavanje naleta podataka**: kada podaci dolaze u naletima, FIFO čuva dodatne stavke kako ništa ne bi bilo izgubljeno.

**Kratki primer**
- Upisujete `A`, zatim `B`, zatim `C` u FIFO (tokom nekoliko taktova).
- Kada budete čitali, dobićete **A**, zatim **B**, zatim **C** — uvek u redosledu prispeća.

Ukratko: FIFO je samo **red koji čuva redosled** u hardveru, koji sprečava gubitak podataka i održava sisteme u toku čak i kada delovi rade različitim brzinama.

## ⚙️ Kako Radi
FIFO koji ćemo dizajnirati je **jednočasovni** red koji čuva redosled, sa dubinom `DEPTH = 2^ASIZE`.

- Na rastućoj ivici takta, ako je `wr_en_i && !wr_full_o`, reč `wr_data_i` se skladišti na lokaciji memorije pokazivača za pisanje i pokazivač za pisanje se pomera napred.
- `rd_data_o` uvek prikazuje reč na trenutnoj poziciji pokazivača za čitanje. Na rastućoj ivici takta, ako je `rd_en_i && !rd_empty_o`, pokazivač za čitanje se pomera napred tako da **sledeća** najstarija reč postaje vidljiva.
- **Zastavice:**
  - `wr_full_o = 1` → nema slobodnog mesta; nemojte aktivirati `wr_en_i`. Čak i ako aktivirate `wr_en_i`, očekivano ponašanje je da `wr_data_i` neće biti uskladišten u FIFO.
  - `rd_empty_o = 1` → nema podataka za čitanje; nemojte aktivirati `rd_en_i`. Čak i ako aktivirate, očekivano ponašanje je da pokazivač za čitanje neće biti ažuriran.
- **Istovremeno čitanje i pisanje:** Dozvoljeno (kada FIFO nije pun/prazan). Jedna stavka ulazi dok jedna izlazi; popunjenost ostaje ista.
- **Reset:** `rst_ni` je **asinhroni aktivan na niskom nivou**. Reset postavlja FIFO u **prazno** stanje (pokazivači/brojač se brišu); sadržaj memorije je nebitan dok se ne upiše validni podatak.

## 🔧 Parametri Modula i Interfejs

### Parametri
| Naziv  | Tip  | Podrazumevano | Opis |
|--------|:----:|:-------------:|------|
| `DSIZE`| int  | `8`           | **Širina podataka** (bitovi) po FIFO unosu. |
| `ASIZE`| int  | `8`           | **Širina adrese** (bitovi); dubina FIFO-a je `2^ASIZE`. |

---

### Portovi
| Port         | Smer   | Širina  | Opis |
|--------------|:-------|:-------:|------|
| `clk_i`      | ulaz   | `1`     | Takt. Sva ažuriranja stanja se dešavaju na rastućoj ivici. |
| `rst_ni`     | ulaz   | `1`     | **Asinhroni reset aktivan na niskom nivou**. Briše FIFO u prazno stanje. |
| `wr_en_i`    | ulaz   | `1`     | Omogućavanje pisanja. Aktivirati za upis `wr_data_i` kada nije pun. |
| `rd_en_i`    | ulaz   | `1`     | Omogućavanje čitanja. Aktivirati za čitanje u `rd_data_o` kada nije prazan. |
| `wr_data_i`  | ulaz   | `DSIZE` | Podatkovna reč za upis u FIFO. |
| `rd_data_o`  | izlaz  | `DSIZE` | Podatkovna reč pročitana iz FIFO-a. |
| `wr_full_o`  | izlaz  | `1`     | **Zastavica punoće** — visoka kada se više ne prihvataju upisi. |
| `rd_empty_o` | izlaz  | `1`     | **Zastavica praznine** — visoka kada nema dostupnih podataka za čitanje. |

## 💻 Implementacija u SystemVerilog-u
Vaš zadatak je da napišete **parametrizovanu implementaciju** **FIFO (First-In, First-Out) bafera** u SystemVerilog-u koristeći dati interfejs.

```verilog
module fifo #(
  parameter DSIZE = 8,
  parameter ASIZE = 8
  ) (
  input  logic             clk_i,     // takt
  input  logic             rst_ni,    // asinhroni reset aktivan na niskom nivou
  input  logic             wr_en_i,   // omogućavanje pisanja
  input  logic             rd_en_i,   // omogućavanje čitanja
  input  logic [DSIZE-1:0] wr_data_i, // podaci za upis
  output logic [DSIZE-1:0] rd_data_o, // podaci za čitanje
  output logic             wr_full_o, // zastavica punog FIFO-a
  output logic             rd_empty_o // zastavica praznog FIFO-a
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