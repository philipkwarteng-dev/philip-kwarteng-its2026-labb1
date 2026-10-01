# Rapport: Secure Network Check (Vecka 37)

**Författare:** Philip Kwarteng  
**Kurs:** ITSX26 - IT- och cybersäkerhet  
**Miljö:** Linux (Ubuntu) i UTM på macOS  
**Datum:** 2026-10-01  
**Repository-länkar:**  
- Rapport: `docs/week3_secure_network_check.md`  
- Skript: `scripts/secure_network_check.sh`  

---

## Del A: Miljöbeskrivning & Miljöskillnader

### Miljöspecifikation
- **Plattform:** UTM Virtual Machine på macOS (Apple Silicon).
- **Operativsystem:** Ubuntu Linux 22.04 LTS (aarch64).
- **Nätverksarkitektur:** Maskinen körs i en isolerad virtuell miljö och erhåller sin nätverksanslutning via UTM Shared Networking (NAT) genom Macens fysiska nätverkskort.

### Nätverksinterface & Adresstyper
| Interface | Typ | IP-adress (Sanerad) | Beskrivning |
|---|---|---|---|
| `lo` | Loopback | `127.0.0.1 | Internt virtuellt interface för kommunikation inom operativsystemet. |
| `enp1s0` | Virtuellt NIC (NAT) | `192.168.64.X` | Privat IP tilldelat av UTM:s interna DHCP-server. |

### Adresskategorisering & Teori
1. **Lokal adress (`127.0.0.1):** Används enbart för intern kommunikation mellan processer på samma maskin. Den exponeras inte ut mot något nätverk.
2. **Privat adress (`192.168.64.X):** Ruttbar inom det lokala virtuella nätverket (mellan Macen och VM:en), men kan inte nås direkt från det publika internet (enligt RFC 1918).
3. **Publik adress (Saknas på VM:en):** Värddatorns (Macens) utåtriktade IP-adress på internet. VM:en delar denna adress utåt via Network Address Translation (NAT).

### Begränsningar och Skillnader mot OCI-demonstrationer
- **Frånvaro av Publik IP:** I OCI erhåller en VM en statisk/dynamisk publik IP och skyddas av en Cloud Security List. I UTM saknar VM:en publik IP och är helt skärmad från inkommande anslutningar från internet.
- **SSH-exponering:** I OCI är port 22 ofta öppen mot internet. I UTM är SSH endast tillgängligt från värddatorn (Mac) om det har konfigurerats manuellt, vilket ger en mindre och säkrare angreppsyta.

---

## Del B: Manuella Observationer (6 Kontroller)

### 1. Interface och IP-adresser
- **Kommando:** `ip address`
- **Resultat:**
  ```text
  1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN
      inet 127.0.0.1/8 scope host lo
  2: enp1s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP
      inet 192.168.64.X/24 brd 192.168.64.255 scope global enp1s0

      ---

## Del E: CIA-analys

- **Konfidentialitet (Sekretess):** IP-adresser och andra nätverksuppgifter kan vara känsliga om fel person ser dem. Därför har jag ändrat mina privata IP-adresser i rapporten (t.ex. till `192.168.64.X`) så att ingen ser mina riktiga uppgifter på GitHub.
- **Integritet (Riktighet):** Skriptet sparar loggar med tid och datum, och använder tydliga koder när det är klart (`exit 0` om allt gick bra, `exit 1` om något felade). Det gör att man vet att resultaten stämmer och inte har ändrats.
- **Tillgänglighet:** Skriptet kollar att nätverket och tjänsterna fungerar i tre enkla steg:
  1. Att nätverkskortet har en IP-adress (`ip address`).
  2. Att internet och DNS svarar (`ip route` och `getent`).
  3. Att webbservern faktiskt svarar när man kopplar upp sig (`curl`).
- **Säkerhet vs Funktion (Trade-off):** Om man gör brandväggen för hård och stänger av all UDP-trafik slutar DNS (port 53) att fungera. Då blir datorn säkrare, men du kan inte längre gå in på hemsidor med namn som `google.com`.

---

## Del F: Reflektion & AI-redovisning

- **Vilken kontroll var bäst och varför?**  
  `ss -tuln` var bäst. Den visar direkt vilka portar som är öppna på datorn så man snabbt ser vad som kan nås utifrån.
- **Vilken skillnad i miljön påverkade ditt arbete?**  
  Att jag körde UTM på min Mac istället för i molnet. UTM ligger gömt bakom Macens eget nätverk, så min virtuella dator fick ingen egen publik IP-adress mot internet.
- **Vilket fel var svårast att förstå?**  
  När `curl` inte fick svar (timeout). Det var svårt att veta om det var brandväggen som stoppade anslutningen eller om testservern inte var igång alls.
- **Vad kan förbättras till version 2?**  
  Jag skulle vilja att skriptet automatiskt kollar brandväggen (`ufw status`) och skickar ett mail om någon kontroll misslyckas.
- **Hur kan skriptet användas på ett säkert sätt i verkligheten?**  
  Det kan köras automatiskt med jämna mellanrum för att kolla att servrarna mår bra. Eftersom det bara gör enkla tester mot den egna datorn är det helt ofarligt att köra.
- **AI-redovisning:**  
  Jag använde AI (Gemini) för att få hjälp med hur skriptet skulle byggas upp och för att förstå felhantering i Bash. Jag har själv testat kondon i min Ubuntu-miljö i UTM och kollat att allt fungerar.