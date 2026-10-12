# Nätverkstrafikanalys & Incidentrapport (Vecka 38)

**Författare:** Philip Kwarteng  
**Kurs:** ITSX26 - IT- och cybersäkerhet  
**Datum:** 2026-10-12  
**Repository-länk:** `investigation-report.md`  

---

## 1. Sammanfattning (Executive Summary)
Vid analys av den insamlade nätverkstrafiken identifierades okrypterad kommunikation över HTTP (port 80) mellan klienten (`192.168.1.15`) och en extern webbserver (`192.0.2.10`). Analysen bekräftar att känslig data skickades i klartext utan TLS/SSL-kryptering, vilket utgör en risk för avlyssning.

---

## 2. Metodik & Verktyg
- **Verktyg:** Tshark / Terminal macOS
- **Inhämtning & Säkerhet:** Analysen har genomförts lokalt på en sparad PCAP-fil. Inga råa `.pcap`-filer publiceras på GitHub i enlighet med säkerhetsreglerna. Känsliga IP-adresser har sanerats.

---

## 3. Teknisk Analys & Händelseförlopp

### Nätverksparametrar
- **Klient (Avsändare):** `192.168.1.15` (Port 49152)
- **Server (Mottagare):** `192.0.2.10` (Port 80 - HTTP)
- **Protokoll:** TCP / HTTP

### Kronologisk Tidslinje & Paketreferenser
1. **Etablering av anslutning (Paket 1–3):** Klienten initierar en TCP 3-way handshake (`SYN`, `SYN-ACK`, `ACK`) mot servern på port 80 för att upprätta en anslutning.
2. **HTTP GET-begäran (Paket 4):** Klienten skickar en okrypterad HTTP GET-förfrågan till resursen `/login.php`.
3. **Dataöverföring i klartext (Paket 5–7):** Trafiken innehåller okrypterade formulärdata. Ingen HTTPS (TLS/SSL) användes under sessionen.
4. **Serverrespons (Paket 8):** Servern svarar med statuskod `HTTP/1.1 200 OK` samt levererar den begärda sidan.

### Sanerad Evidens (Utdrag från nätverksdata)

Frame 1: 66 bytes on wire, TCP Src Port: 49152, Dst Port: 80 [SYN]
Frame 2: 66 bytes on wire, TCP Src Port: 80, Dst Port: 49152 [SYN, ACK]
Frame 3: 54 bytes on wire, TCP Src Port: 49152, Dst Port: 80 [ACK]
Frame 4: 340 bytes on wire, HTTP GET /login.php HTTP/1.1
Frame 8: 512 bytes on wire, HTTP/1.1 200 OK (text/html)

---

## 4. Riskanalys & CIA-triaden

- **Konfidentialitet (Confidentiality):** **BRUSTEN.** Eftersom HTTP användes istället för HTTPS skickas all data i klartext över nätverket. En angripare på samma nätverk kan läsa innehållet.
- **Integritet (Integrity):** **RISK.** Utan TLS-kryptering finns inget skydd mot att trafiken ändras under transporten.
- **Tillgänglighet (Availability):** **PÅVERKAD EJ.** Tjänsten svarade korrekt med statuskod `200 OK` och var tillgänglig under hela mätningen.

---

## 5. Rekommendationer & Åtgärder

1. **Implementera HTTPS (TLS/SSL):** Tvinga all webbtrafik att använda HTTPS (port 443) och konfigurera ompekning (redirect) på servern.
2. **Inaktivera okrypterade protokoll:** Stäng av ren HTTP och andra klartextprotokoll i nätverket.
3. **Nätverkshärdning:** Inför segmentering för att förhindra att obehöriga enheter kan avlyssna nätverkstrafik lokalt.
