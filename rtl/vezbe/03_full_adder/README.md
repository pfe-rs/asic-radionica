# Potpuni Sabirač
## 📘 Uvod
**Potpuni sabirač** je kombinaciono logičko kolo koje vrši **binarno sabiranje** tri ulazna bita:
- Dva **bita operanda** (`a_i`, `b_i`)  
- Jedan **bit prenosa na ulazu** (`c_i`)  
Proizvodi:
- **Izlaz sume** (`sum_o`)  
- **Izlaz prenosa** (`c_o`)  
To čini potpuni sabirač ključnim gradivnim blokom za **aritmetičko-logičke jedinice (ALU)**, **brojače** i **višebitne binarne sabirače** (kada je nekoliko potpunih sabirača kaskadno povezano).
## ⚙️ Kako Radi
Logika potpunog sabirača može se razumeti iz njegove **tablice istinitosti**:
| **a_i** | **b_i** | **c_i** | **sum_o** | **c_o** |
|:-------:|:-------:|:-------:|:---------:|:-------:|
| 0       | 0       | 0       | 0         | 0       |
| 0       | 0       | 1       | 1         | 0       |
| 0       | 1       | 0       | 1         | 0       |
| 0       | 1       | 1       | 0         | 1       |
| 1       | 0       | 0       | 1         | 0       |
| 1       | 0       | 1       | 0         | 1       |
| 1       | 1       | 0       | 0         | 1       |
| 1       | 1       | 1       | 1         | 1       |
### Jednačine
`sum_o = a_i ⊕ b_i ⊕ c_i`  
`c_o = (a_i · b_i) + (c_i · (a_i ⊕ b_i))`
## 💻 Implementacija u SystemVerilog-u
Vaš zadatak je da napišete **implementaciju** potpunog sabirača u SystemVerilog-u koristeći dati interfejs.
```verilog
module full_adder (
input  a_i,
input  b_i,
input  c_i,
output sum_o,
output c_o
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