# Nätverkssäkerhetsanalys & Incidentrapport

**Författare:** Philip Kwarteng  
**Kurs:** ITSX26 - IT- och cybersäkerhet  
**Datum:** 2026-09-16  

---

## 1. Sammanfattning (Executive Summary)
Kortfattad beskrivning av den undersökta händelsen/trafiken, vilka system som påverkades och vad analysen resulterade i.

---

## 2. Metodik & Verktyg
- **Verktyg:** Wireshark, Tshark, Terminal (Mac/Linux).
- **Inhämtning:** Analys av nätverkstrafik har utförts lokalt utan att rå pcap-data publiceras.

---

## 3. Teknisk Analys & Händelseförlopp (VG-nivå)
*Beskriv händelseförloppet kronologiskt och förklara de tekniska mekanismerna bakom trafikmönstret/angreppet.*

### Kronologisk Tidslinje
1. **Initiell kontakt:** Klienten initierar anslutning via okrypteras protokoll.
2. **Datatransmission:** Känsliga uppgifter överförs i klartext.
3. **Avvikelse/Sårbarhet:** Identifiering av oauktoriserade anrop eller svaga konfigurationer.

### Sanerad Evidens & Utdrag
| Tidsstämpel | Källa (Src IP) | Destination (Dst IP) | Protokoll | Sanerad Detalj / Händelse |
|---|---|---|---|---|
| 10:15:02 | `192.168.1.X` | `10.0.0.X` | HTTP | `POST /login` - User: `user1`, Pass: `[REDACTED_PASSWORD]` |
| 10:15:05 | `192.168.1.X` | `10.0.0.X` | TCP | Session etablerad - Auth Token: `[REDACTED_TOKEN]` |

---

## 4. CIA-Analys & Hotmodellering

### Konfidentialitet (Confidentiality)
- **Påverkan:** Hög. Eftersom trafiken skickades i klartext (HTTP/Telnet) kunde en angripare via en Man-in-the-Middle (MitM) avlyssna känslig data.
- **Risk:** Stulna inloggningsuppgifter och sessions-tokens.

### Integritet (Integrity)
- **Påverkan:** Medel/Hög. Avsaknad av kryptografisk verifiering (som TLS/HTTPS) gör det möjligt för en angripare att manipulera paketinnehållet under överföring.

### Tillgänglighet (Availability)
- **Påverkan:** Låg/Medel. Inga tecken på överbelastningsangrepp (DoS), men eventuell spärrning av konton till följd av misslyckade inloggningar kan påverka tillgängligheten.

---

## 5. Rekommendationer & Säkerhetsåtgärder

### Kort sikt (Omedelbara åtgärder)
1. Byt lösenord och återkalla läckta sessions-tokens.
2. Spärra obehöriga IP-adresser i brandväggen.

### Lång sikt (Strategiska förbättringar)
1. **Krav på kryptering:** Tvinga användning av HTTPS (TLS 1.3) och fas ut otrygga protokoll.
2. **Införa MFA:** Krav på multifaktorautentisering på alla externa tjänster.
3. **Nätverkssegmentering:** Separera administrativ trafik från vanliga användarnätverk.