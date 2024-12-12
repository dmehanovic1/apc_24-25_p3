# Uvod 
Zadatak projekta je modelirati i implementirati GMII predajni interfejs koji putem ulaznog 64-bitnog Avalon-ST interfejsa prima odlazni Ethernet okvir (počinje odredišnom adresom a završava FCS poljem), te na izlazni GMII interfejs generiše preambulu, SFD te oktete odlaznog Ethernet okvira.

GMII (eng. *Gigabit media-independent interface*) je sučelje za prenos podataka između MAC i PHY kontrolera. Podaci se prenose u oktetima od LSB do MSB, pri čemu se za generisanje takta koristi frekvencija 125 MHz. [ref_predavanje] Logika se obavlja na uzlaznu ivicu taktnog signala.
# Opis ulaznih i izlaznih signala
Označimo komponentu koju modeliramo i imamo za cilj implementirati sa MY_GMII_TX. 

Ulazni signali u modul su dati u tablici ispod.

|Signal|Opis|
|--|:-----:|
|avalon_data [63:0]	|Signal koji sadrži podatke koji se prenose.|
|avalon_error|	Indikator greške u prenosu podataka u trenutnom ciklusu.|
avalon_valid|	Indikator validnih podataka|
avalon_empty|	Indikator broja simbola koji su ostali prazni prilikom prenosa.|
avalon_endofpacket|	Indikator kraja paketa.|
avalon_startofpacket|	Indikator početka paketa.|
gmii_reset|	Signal za reset|
gmii_clk|	Clock signal frekvencije 125 MHz|

Izlazni signali modula su dati u tablici ispod:
|Signal|Opis|
|------------|:-----:|
gmii_txd [7:0]|	Transmitirani podaci|
gmii_txen|	Indikacija aktivne transmisije|
gmii_txer|	Indikacija greške u prenosu podatka|
gmii_ready|	Indikacija da je prijemnik spreman za prijem podataka od strane izvora. |

Za opis signala korišteni su opisi Avalon-ST sučelja, te GMII sučelja, koji se mogu pronaći u [1] i [2].

# Logika rada modula
Postavljanjem *gmii_reset* signala na logičku jedinicu, vrši se incijalizacija interne logičke strukture modula bazirane na konačnim automatima, te incijalizacija početnih vrijednosti ulaznih signala. 

Po prijemu *avalon_startofpacket*, te *avalon_valid* signala, modul dobija indikaciju početka novog Ethernet okvira. Tada modul generira preambulu (7B sačinjenih od vrijednosti 0x55) te SFD (eng. *Start Frame Delimiter*) (1B vrijednosti 0xD5), te vrši njihovu transmisiju putem *gmii_txd* signala. Bitno je primijetiti da je potrebno 8 takt intervala za prenos preambule i SFD-a, obzirom da modul šalje 1B podataka po takt intervalu. 

Generiranjem preambule i SFD-a, te njihovom transmisijom, počinje proces serijalizacije ulazne 64-bitne riječi sa Avalon-ST sučelja koja sadrži Ethernet okvir, čime se sukcesivno prenosi bajt po bajt ulaznog signala, dok se ne prenese cijeli sadržaj Ethernet okvira. 

# Literatura
[1] E.Kaljić, "Predavanje 7" iz predmeta Arhitekture paketskih čvorišta, ak. 2024/2025.

[2] Avalon Interface Specification, Intel Quartus Prime Design Suite 20.1, v2022.01.24
