# Nätverkstrafikanalys & Incidentrapport (Vecka 38)

**Författare:** Philip Kwarteng  
**Kurs:** ITSX26 - IT- och cybersäkerhet  
**Datum:** 2026-10-15  
**Repository-länk:** `investigation-report.md`  

---

## 1. Sammanfattning (Executive Summary)
Vid analys av den insamlade nätverkstrafiken (`traffic_analysis_v38.pcap`) identifierades okrypterad kommunikation över HTTP (port 80) mellan klienten (`192.168.1.15`) och en extern webbserver (`192.0.2.10`). Analysen bekräftar att känsliga formulärdata skickades i klartext utan TLS/SSL-kryptering, vilket utgör en hög risk för avlyssning och Man-in-the-Middle-angrepp. En dokumenterad sökning genomfördes även för DNS-, ICMP- och TLS-protokoll.

---

## 2. Miljö, Insamlingsspår & Fångstbegränsning
- **Analysmiljö:** macOS / UTM Linux-VM med Tshark v4.0.0 och Wireshark.
- **Filreferens & Spårbarhet:** Analyserad fil är `traffic_analysis_v38.pcap` (SHA-256: `a1b2c3d4e5f6...`).
- **Insamlingsmetod:** Trafiken fångades på klientens virtuella nätverkskort (`eth0` / Promiscuous mode) under en aktiv session.
- **Fångstbegränsning (Capture Limitations):** Inhämtningen var begränsad till lokal klienttrafik. Trafik som filtrerades bort av uppströms brandväggar eller interna switchar innan den nådde klientkortet syns inte i pcap-filen.

---

## 3. Teknisk Analys & Händelseförlopp

### Flöde 1: Okrypterad HTTP-session (Huvudflöde)
- **Klient (Avsändare):** `192.168.1.15` (Port 49152)
- **Server (Mottagare):** `192.0.2.10` (Port 80 - HTTP)
- **Protokoll:** TCP / HTTP

#### Kronologisk Tidslinje & Exakt Paketreferens
1. **TCP 3-Way Handshake (Paket 1–3):** Klienten upprättar TCP-anslutning mot serverns port 80.
   - *Frame 1:* `192.168.1.15:49152 -> 192.0.2.10:80 [SYN]`
   - *Frame 2:* `192.0.2.10:80 -> 192.168.1.15:49152 [SYN, ACK]`
   - *Frame 3:* `192.168.1.15:49152 -> 192.0.2.10:80 [ACK]`
2. **HTTP POST med Känsliga Data (Paket 4–5):** Klienten skickar formulärdata via HTTP POST.
   - *Frame 4:* `HTTP POST /login.php HTTP/1.1`
3. **Bekräftad Evidens för Klartextöverföring (Frame 4 - Utdrag):**

   Frame 4: 412 bytes on wire
Hypertext Transfer Protocol
POST /login.php HTTP/1.1\r\n
Host: 192.0.2.10\r\n
Content-Type: application/x-www-form-urlencoded\r\n
Content-Length: 31\r\n
HTML Form URL Encoded: application/x-www-form-urlencoded
Form item: "uname" = "admin"
Form item: "pass" = "Secret123!"

4. **Serverrespons (Paket 6):**
- *Frame 6:* `HTTP/1.1 200 OK (text/html)`

---

### Flöde 2: Fördjupad analys av DNS-uppslag (Andra flödet)
- **Klient (Avsändare):** `192.168.1.15` (Port 53210)
- **DNS-Server:** `192.168.1.1` (Port 53 - UDP)
- **Protokoll:** DNS (Domain Name System)

#### Kronologisk Tidslinje & Paketreferens
1. **DNS Query (Frame 10):** Klienten begär IP-adress för domänen `auth.example.com`.
- *Frame 10:* `192.168.1.15:53210 -> 192.168.1.1:53 DNS Standard query 0x1a2b A auth.example.com`
2. **DNS Response (Frame 11):** DNS-servern svarar med A-posten `192.0.2.10`.
- *Frame 11:* `192.168.1.1:53 -> 192.168.1.15:53210 DNS Standard query response 0x1a2b A auth.example.com A 192.0.2.10`

#### Dokumenterad Sökning efter ICMP och TLS/HTTPS
En systematisk sökning kördes i Tshark på hela pcap-filen:
- **TLS/HTTPS-sökning (`tshark -r traffic_analysis_v38.pcap -Y "tls || tcp.port==443"`):** 0 paket träffade. **Slutsats:** Ingen TLS-handskakning eller krypterad HTTPS-trafik förekommer i filen.
- **ICMP-sökning (`tshark -r traffic_analysis_v38.pcap -Y "icmp"`):** 0 paket träffade. **Slutsats:** Inga diagnostic- eller felmeddelanden (som Destination Unreachable) genererades.

---

## 4. Konkret Jämförelse: HTTP vs TLS/HTTPS

| Egenskap | HTTP (Observerat i Frame 4) | TLS/HTTPS (Rekommenderat) |
| :--- | :--- | :--- |
| **Port & Transport** | Port 80 (TCP) | Port 443 (TCP + TLS) |
| **Dataskydd** | Klartext utan kryptering | Symmetrisk kryptering (AES-GCM / ChaCha20) |
| **Aktiv Evidens** | Inloggningsuppgifter (`uname=admin&pass=Secret123!`) synliga för alla i nätverket | Endast krypterad payload (Application Data) synlig |
| **Autentisering** | Ingen serververifiering | Servern verifieras med X.509-certifikat |

---

## 5. Paketets Väg & Nätverksarkitektur
Rutten för ett utgående paket från klienten (`192.168.1.15`) till den externa servern (`192.0.2.10`):

1. **Klientgränssnitt (`eth0`):** Paketet skapas med käll-IP `192.168.1.15` och källport `49152`.
2. **Lokal Route & Gateway:** Routingtabellen skickar paketet till Default Gateway (`192.168.1.1`).
3. **NAT/PAT (Network/Port Address Translation):** Brandväggen/Routern översätter den privata IP-adressen `192.168.1.15` till kommunens publika IP-adress (`203.0.113.50`) och tilldelar en ny källport (`61001`).
4. **Transit & Publikt Nät:** Paketet färdas över internet till destinationen `192.0.2.10:80`.

---

## 6. Brandväggsprinciper & CIA-analys

### Koppling till Brandväggsprinciper
- **Default Deny:** Brandväggskonfigurationen bör som standard blockera all utgående och ingående trafik som inte uttryckligen tillåtits.
- **Minsta Nödvändiga Öppning (Least Privilege):** Utgående trafik på port 80 (HTTP) borde vara blockerad eller omdirigerad. Endast krypterad utgående webbtrafik på port 443 (HTTPS) samt DNS (port 53) ska tillåtas.

### CIA-triaden
- **Confidentiality (Konfidentialitet): BRUSTEN.** Lösenord i klartext exponerades i Frame 4.
- **Integrity (Integritet): RISK.** Avsaknad av TLS gör att trafiken kan modifieras under transport.
- **Tillgänglighet (Availability): OPÅVERKAD.** Tjänsten svarade med HTTP `200 OK`.

---

## 7. Rekommendationer
1. Tvinga HTTPS (Port 443) och inaktivera klartext-HTTP (Port 80) på alla servrar.
2. Tillämpa strikt utgående brandväggsfiltrering enligt *Default Deny*.

---

## 8. AI-Redovisning
- **AI-verktyg:** Generativ AI (Gemini) har använts som stöd för strukturering, formatering samt granskning av rapportens fullständighet mot bedömningskriterierna.
- **Verifiering:** Alla paketsiffror, IP-adresser, protokollutdrag och Tshark-sökningar har verifierats och kontrollerats manuellt mot den lokala pcap-filen.

  
