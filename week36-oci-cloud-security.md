# Week 36 OCI Cloud Security Lab

## 1. Min OCI-miljö / Min lokala Linux-miljö / Min lokala WSL-miljö
- **Tenancy (N/A):** N/A (Lokal Mac-miljö)
- **Compartment (Endast OCI):** N/A
- **Region (Endast OCI):** N/A
- **Availability Domain (Endast OCI):** N/A
- **VM-namn/hostnamn/WSL-maskinnamn:** macOS Local Dev Environment
- **Operativsystem:** macOS (UNIX/Darwin)
- **Shape (Hårdvara, gäller alla):** Apple Silicon / Intel Mac
- **Inloggningsmetod:** Lokal macOS Terminal / Zsh shell

---

## 2. Linux-kommandon

| Kommando | Vad visar det? | CIA-koppling |
|---|---|---|
| `whoami` | Visar namnet på den inloggade användaren. | **Konfidentialitet / Integritet** – Säkerställer identitet och behörighetsnivå. |
| `hostname` | Visar datorns/serverns nätverksnamn. | **Tillgänglighet** – Identifierar rätt system vid administration. |
| `pwd` | Visar nuvarande mappsökväg. | **Integritet** – Förhindrar att filer ändras i fel katalog. |
| `uname -a` | Visar system- och kärninformation. | **Tillgänglighet / Integritet** – Identifierar om systemet behöver patchas. |
| `uptime` | Visar hur länge systemet varit igång. | **Tillgänglighet** – Indikerar systemstabilitet. |

---

## 3. Hardening

| Kontroll | Risk | Vad gjorde jag? | Hur verifierade jag? | CIA |
|---|---|---|---|---|
| **1. Identitet** | Köra som root ökar risken för systemskador. | Körde `whoami` och `id`. | Bekräftade att jag är inloggad som vanlig användare. | **Integritet** |
| **2. Filrättigheter** | Öppna rättigheter kan leda till dataläckage. | Skapade `test.txt` och körde `chmod 600 test.txt`. | Körde `ls -l test.txt` (visade `-rw-------`). | **Konfidentialitet** |
| **3. Uppdateringar** | Kända sårbarheter kan utnyttjas. | Kontrollerade systemuppdateringar i macOS. | Verifierade att inga kritiska uppdateringar saknas. | **Tillgänglighet** |
| **4. Processer** | Skadliga processer kan stjäla resurser. | Körde `ps aux \| head`. | Kontrollerade att endast legitima systemprocesser körs. | **Tillgänglighet** |

---

## 4. Recovery-plan

### Vad kan gå fel?
Systemkrasch eller förlorade filrättigheter/nycklar.

### Hur upptäcker jag problemet?
Kommandon misslyckas eller terminalen ger behörighetsfel.

### Vad kontrollerar jag först?
Nätverksanslutning, filrättigheter och SSH-konfiguration.

### Hur återställer jag åtkomst?
Använder lokal macOS-återställning eller klonar projektet på nytt från GitHub.

### När behöver jag hjälp?
Om hårdvara kraschar eller om behörigheter på kontonivå spärras.

---

## 5. Backup

### Vad har jag sparat?
Källkod och rapporter sparade lokalt i mitt Git-repo.

### Vad finns i GitHub?
Hela projektet och denna rapport i `docs/`.

### Vad kan återskapas?
All kod och dokumentation kan laddas ner via `git clone`.

### Vad går inte att återskapa?
Osparade lokala ändringar som inte pushats till GitHub.

---

## 6. Cleanup

### VM-instans
N/A (Lokal Mac-miljö).

### Diskar
Rensade tillfälliga testfiler (`rm test.txt`).

### Backuper
Inga oanvända snapshots kvar i molnet.

### Publika IP-adresser
N/A.

### GitHub-evidens
Rapporten är sparad och versionshanterad på GitHub.

---

## 7. CIA-reflektion

### Konfidentialitet
Strikta filrättigheter (`chmod 600`) skyddar känsliga filer från obehöriga.

### Integritet
Genom att inte köra som root av misstag skyddas systemfiler från ändringar.

### Tillgänglighet
Genom versionshantering i Git kan miljön snabbt återställas vid fel.

---

## 8. Reflektion

### Vad fungerade bra?
Att använda Mac-terminalen direkt var smidigt då UNIX-kommandon finns inbyggda.

### Vad var svårt?
Att koppla ihop teoretiska säkerhetsbegrepp (CIA) med praktiska kommandon.

### Vad lärde jag mig?
Grundläggande hardening filrättigheter och hur man dokumenterar säkerhet i Markdown.