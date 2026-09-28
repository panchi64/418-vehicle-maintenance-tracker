# Biombo — Product definition

**Status: draft for owner sign-off (2026-09-27).** Supersedes `legacy/FUEL_PRICE_TRACKER.md`. Every number marked *(proposed)* is a starting default to tune on real data, not a decision. Official-source facts are in `DATA_SOURCES.md`. Visual design is exploratory and lives in `DESIGN.md`; this document sets behaviour and information design only.

## 1. Vision

Biombo is a map of everyday life in Puerto Rico. One glance answers "is anything wrong near me, and where's the cheapest gas?" — power, water, signal, roads, fuel, chargers and open businesses — from neighbours' reports and official feeds, shown side by side and never blended. On an ordinary day it is a lively, useful habit. In a storm or island-wide outage it becomes a calm, sober tool that tells people what officials say, what neighbours see, and where to get what they need. It ships as an iPhone app (iOS 26 and later; Spanish-first, with English) plus a web dashboard for authorities.

Biombo is not an emergency service and never replaces calling LUMA, AAA or 911. The report sheet and the terms say so.

## 2. Audiences and jobs

Everyone starts on the same map. First run has no account, no form and no onboarding carousel; each audience gets one job on day one.

| Audience | First job | Also | Language |
|---|---|---|---|
| Island residents (daily drivers; rural elders with large text) | "Is anything wrong near me, and where's the cheapest gas?" | Report in one tap or by voice; check a barrio before driving; fuel and generators in crisis | ES |
| Diaspora | "Does Mamá's barrio have power and water right now?" | Get told when it changes | ES or EN |
| Visitors | "Is my route passable, and where can I fill up or charge?" | Official alerts in plain English; "Abrir en…" | EN |
| Business owners | "Tell people I'm open / on generator / have fuel" | Post events; answer wrong reports | ES/EN |
| Authorities (web) | "What's happening in my municipio or layer, and what needs me?" | Post official notices; moderate; export | ES/EN |

**Units are a separate setting from language** (litres or gallons). The default follows the region: litres for a PR region, gallons for a US mainland region.

First-run paths:
- **Resident:** map → one-sentence location prompt ("Para mostrarte lo que pasa cerca") → the peek answers. Notification permission is asked only when the user first watches a place.
- **Diaspora:** with location denied or outside PR, the peek offers one verb, "Vigilar un lugar": search → name it ("Casa de Mamá") → layers → "Empezar a vigilar" → then the notification prompt, with the reason on screen.
- **Visitor:** an EN locale or the in-app language toggle switches to English. In crisis the official-alerts card comes first.
- **Owner:** place ••• → "¿Es tu negocio?" → claim → verification (§5). A claimant can't post until verified; meanwhile the place shows "Verificando…" to them only.
- **Authority:** invitation only → passkey → lands on their municipios and layers.

## 3. Principles

1. **Answer first, one answer per place.** Every sheet, section and list opens with one plain sentence or hero ("Caguas sigue sin luz desde las 3:10 p. m."). A place has one current answer per layer. Sentences come from full-sentence ES/EN templates with plural forms, never concatenated fragments.
2. **Truth before completeness.** Real-time data shows only while fresh (§4.4). Stale data is hidden by default, never presented as current, and never drawn on the map; "Ver reportes anteriores (N)" in the sheet reveals it with its age stated first. With no fresh evidence the answer is empty, not old. Stale data is never spoken by Siri or shown in widgets as current.
3. **Community and official, side by side.** Official items are set apart and labelled with their agency. Official and community data are never averaged into one number: when they disagree, the answer says who says what ("LUMA dice que volvió; 4 vecinos dicen que no").
4. **Tone matches stakes.** Lively on ordinary days; in crisis mode (§8) copy goes plain, utility layers come first, every budget tightens and promotional content disappears.
5. **Native, not AI-centric.** Siri, Controls, widgets and on-device summaries feel first-party, but there is no chatbot and no generated answer where a template exists. Everything a user can do by voice works on an iPhone without Apple Intelligence.

**Information design.** A surface is a data dump when the user must read everything to learn anything. These rules apply to every screen and detent:
- **Disclosure tiers are sheet detents:** **Peek** (the answer, Reportar, Capas) → **Summary** (answer, ≤3 rows per section, primary verbs) → **Full** (the layer's one comparison visual, confirm/dispute, ≤5 rows per section) → **Depth, "Detalles de…"** (sources, history, polygon confidence, older reports, automated summary). Never more than two levels past summary. Default-disclose what makes a feature work; hide what makes it complete.
- **Two row grammars, never mixed in one section:** place rows (place name → the answer as trailing value: "$0.99", "Funciona", "Abierto") and event rows (a sentence, "Inundada la PR-52, km 14", with no trailing value).
- **Row budget:** one primary, ≤1 secondary line of ≤2 atoms, ≤1 trailing value. The atoms are context (distance *or* barrio, never both) and one trust suffix that merges freshness and verification ("Confirmado hace 12 min"). The suffix is promoted as the news when it is Sin verificar, aging, disputed, or official overriding community. Counts ("6 vecinos") appear in detail only.
- **Row caps:** 3 per section at summary and in crisis, 5 at full, then "Ver todas (N)". Sort by the user's question (nearest, cheapest, most confirmed), never by insertion time unless the section is "Lo último".
- **Group by the user's question**, not by data type: "Hay gasolina", "Avisos oficiales", "Lo que dicen los vecinos" — never "Reportes" or "Datos". Say each fact once per screen; the only allowed repeat is the peek's value matching the full detent's hero.
- **Compare with shapes, not columns:** price ladder, restore-time bar, agreement bar. One per layer at Full, each with a one-line headline and a VoiceOver/Audio Graph sentence, never carried by colour alone.
- **Verbs under the answer:** 2–3 primary verbs ("Abrir en…", "Vigilar", "Reportar"); everything else in one ••• menu of 3–7 verb items. Confirm/dispute is one compact question row, never a section.
- **Numbers for glancing:** no trailing zeros ("$1"); the unit once per section; relative times under 24 h ("hace 12 min", "ahora"), clock times for events, dates beyond; "0.8 km" under 10 km, whole numbers above; differences in words with direction and size ("3¢ menos"), never signed numbers; estimates as human windows plus "estimado".
- **Empty and stale states say what to do:** one sentence and one verb ("Nada reportado aquí hoy. Si pasas por aquí, dinos el precio." → Reportar el precio).
- **Official is set apart by sobriety, not volume:** one card per agency, one sentence plus agency · time, with the guidance line shown only when actionable ("Hierve el agua 3 minutos"). First in crisis, after the answer on ordinary days.
- **Capas answers too:** a sentence for the current view ("Cerca: 3 apagones y gasolina desde $0.99"), then Servicios (Luz, Agua, Señal, Carreteras) and Del día a día (Gasolina, Cargadores, Negocios) — 7 rows, each with a live mini-answer ("3 apagones cerca", "Nada nuevo"). In crisis Servicios comes first and Del día a día collapses to one row.
- **Accessibility:** every answer and verb works at the accessibility text sizes (rows reflow and the trailing value moves under the primary); map pins and areas have VoiceOver labels that read their answer and label; status, layer and verification always carry a symbol and a word.

**The 3-second glance test.** Show the screen for 3 s with real-looking data, hide it, and ask its question. It passes if the answer is correct without reading any row below the answer (hallway test: 4 of 5 people, once per screen type before build).

| Screen | Glance question |
|---|---|
| Home peek | Is anything wrong near me, and where's the cheapest gas? |
| Home summary | What changed near me today? |
| Place summary / full | What's the answer here, and can I trust it? |
| Barrio / area | Does this barrio have power and water right now? |
| Outage detail | Is my area out, since when, and when might it come back? |
| Crisis home | What do officials say, and where can I get fuel? |
| Fuel and generators | Where's the nearest place that has what I need? |
| Quick Report | What will one tap report, and where? |
| Watch setup | What will I be told about, and for where? |
| Capas | Which layers are on, and which one has news? |
| Tu aporte | What's my level and what's next? |
| Dashboard queue | How many need me, and which one first? |

## 4. Shared primitives

### 4.1 Place
Anything a person can ask "what's the answer here?" about. Every report, watch and verification attaches to one.

| Kind | Geometry | Seed | Answer |
|---|---|---|---|
| Station | point | OSM `amenity=fuel`, replaced by DACO's retailer registry if published | Price per grade; hay / no hay |
| Charger | point | AFDC locations (seed only) + user/owner-added | Funciona / no funciona |
| Business | point | Owner claim or user-added | Abierto / en planta / cerrado; events |
| Road segment | line | DTOP state centerlines; municipal/rural roads need a second source | Inundada / derrumbe / cerrada / un carril / reportada abierta; otherwise "Sin reportes de problemas" (§6.6) |
| Area | polygon | 78 municipios, barrio/sector gazetteer, LUMA feeders during load shed | Luz, agua, señal |
| Saved place | user pin, user-named | The user | Combined status of the areas and roads around it |

Reports snap to the nearest place of the right kind within a radius (stations/chargers 150 m, businesses 75 m, roads 50 m; proposed); otherwise the user picks or adds one (added places start Sin verificar). Brand comes from the station directory, never from OCR.

### 4.2 Report
One person's observation about one place (or point in an area) on one layer. Fields: client id (idempotency key), layer, type, optional value (price, carrier, grade, connector), place or snapped geometry, `captured_at`, channel (tap / Siri / Control / photo), reporter (never public), optional price-sign photo (EXIF/GPS stripped on device), source (community / owner / official:<agency>), state.

- **One tap, no forms, no free text.** Quick Report offers 3 contextual verbs plus "Otra cosa…"; the reversal comes first inside a reported problem ("Volvió la luz", "Ya está abierta"). Free text exists only in owner posts and authority notices.
- **Typing waits until you stop.** A price is the only report that needs typing. When the phone is moving faster than walking speed or is in CarPlay, the price verb saves a draft instead ("Guárdalo para cuando te detengas"); "Sigue igual" on a shown price stays one tap.
- A repeat of the same type on the same place within 15 min (proposed) becomes a confirmation; for prices, same grade and within ±1¢/L. Outside that it is a new report and can trigger "Reportes no coinciden". A reversal is both a new report and a "Ya no" vote on the opposite one.
- **Sent state:** one sentence plus Deshacer for 5 s (proposed). Damage and hazard types add one hand-off row (§6.2, §6.3, §6.6), because users assume a report reaches the utility.
- Every channel produces the same Report under the same rules; voice is trusted no more or less than a tap.
- Prices are stored in ¢/L (DACO's unit) and shown in the user's unit (1 gal = 3.78541 L, converted before rounding).

### 4.3 Confirm or dispute
Detail screens carry one compact question — "¿Sigue a $0.99?" / "¿Sigue sin luz?" — with **Sigue igual / Ya no**.
- One vote per reporter per report, changeable once; not on your own report.
- **Nearby only:** within 300 m of a place or 1 km of an area report at vote time (proposed), checked with a one-shot fix. Far-away users see the control dimmed with "Solo quien está cerca puede confirmar".
- "Sigue igual" adds confirming weight and resets freshness. "Ya no" adds dispute weight.
- **Disputed:** ≥30% "Ya no" and ≥2 votes (proposed); the item stays visible with the dispute promoted. **Resolved/hidden:** "Ya no" weight exceeds "Sigue igual" with ≥3 votes (proposed).
- Official items are not voted on; strong contradiction shows both and flags the agency on the dashboard.

### 4.4 Freshness
Each report type has a **decay window**. Inside it, the report counts. Past 50% it is *aging* (suffix promoted). Past the end it leaves the map and the answer and moves behind "Ver reportes anteriores (N)". Past a longer **show-older horizon** it is gone from the app and kept only for trends and history. The clock starts at the latest of capture time or the last "Sigue igual".

Decay windows (all proposed; per-type detail in §6):

| Layer | Windows |
|---|---|
| Gas price | 48 h |
| Fuel availability | hay/no hay 2 h · fila 45 min · planta 4 h · solo efectivo 12 h |
| Luz | no hay 4 h* · volvió 2 h · point hazards 12 h |
| Agua | no hay 8 h* · volvió 4 h · presión/turbia 6 h · oasis 12 h |
| Señal | sin señal 2 h* · hay datos 1 h · punto de señal 24 h |
| Carreteras | inundada 3 h · derrumbe/cerrada 24 h · un carril, árbol 12 h · abierta otra vez 6 h |
| Cargadores | status 6 h · ocupado 30 min · conector dañado 72 h |
| Negocios | community 4 h · owner until stated end or 12 h |

\* **Outages are states, not events.** People without power or signal can't keep reconfirming, so an outage area (§7) that has reached Confirmado or Oficial stays open until reversal evidence closes it ("Volvió" weight, official restoration) or a ceiling passes: 72 h, or 7 days in crisis (proposed). For an open area, the starred window only sets when its evidence turns *aging*: it stays drawn, with the age promoted ("Último reporte hace 9 h"). Reaching the ceiling is not a restoration: the area moves behind "Ver reportes anteriores" and nothing says "volvió". Unconfirmed outage reports and all point reports decay normally.

Official items don't decay by age: they are current while the source says so and turn aging when the feed itself is late (e.g. LUMA timestamp > 60 min; a hand-entered DTOP closure or AAA notice with no update for 72 h prompts "¿Sigue cerrada?" / "Confirma con AAA"). A lost feed loses its override (§7).

"Ver reportes anteriores" is always a row at the end of a sheet section, never on the map, per section and per visit. Revealed rows state the age first and never feed the answer, median, trend line or polygon. Offline and late-arriving reports keep their original timestamps; nothing becomes fresh because it was cached.

### 4.5 Verification labels
Every item has exactly one label, always symbol plus word:

| Label | Who holds it |
|---|---|
| **Oficial · <agency>** | Ingested official feeds; authority posts and promotions; staff transcriptions (below) |
| **Dueño verificado** | A verified owner, about their own place only |
| **Confirmado por la comunidad** (N vecinos in detail) | Community reports that met the threshold |
| **Sin verificar** | Every new community report and added place |

"Disputed" is a state, not a fifth label. A community report becomes Confirmado at reputation-weighted weight ≥2.0 from independent people other than the author (≈ two neighbours); high-harm negatives ("No hay gasolina", "Cerrado", "No funciona", "Cerrada", "Derrumbe") need ≥3.0 (both proposed). A verified owner's status is the place's answer; community reports on the same fact show as "Lo que dicen los vecinos" and can dispute it but never hide it.

- **Staff transcriptions** of an agency's release carry its time and a source link ("Oficial · DTOP · comunicado de las 3:10 p. m."), so they never read as the agency posting.
- **Promotions:** an authority can promote a community report to Oficial, keeping its history. A promotion takes the same mandatory expiry as a dashboard notice (§12).

### 4.6 Offline
- Cache: last viewed region, every watched place, the current DACO reference — all under the same freshness rules, with a banner stating the newest data's age ("Sin conexión · datos de hace 40 min").
- Outbox: every report (tap, Siri, Control) is persisted with its id, capture time and location, replayed when the network returns with backoff and jitter; the server de-duplicates on id. The sent state says "Se enviará cuando haya señal".
- The server judges late reports by capture time: past the decay window they go to history only. Outbox items older than 24 h (proposed) are listed for the user to send or discard.

## 5. Trust and moderation

**Identity tiers**

| Tier | How | Can |
|---|---|---|
| Device | Anonymous keychain id + App Attest | View, watch, report, vote, progress |
| Account (optional) | Sign in with Apple | Same; progression survives reinstall and new devices |
| Verified owner | Account + owner verification | Post their own place's status, prices, events |
| Authority | Invited organisation seat | Post official items and moderate within agency × layers × municipios |

**Rate limits** (proposed): 20 reports/day and 6/hour per device, 60 votes/day, 3 place additions/day. Over-limit reports are held, and the user is told plainly.

**Attestation** needs Apple's servers, which may be unreachable after a storm. A report whose attestation hasn't completed counts at probation weight and is re-weighted once it succeeds; only a failed attestation weighs 0.

**Reputation** is a hidden per-reporter weight (0–2.0, starting at 0.5 during a short probation, then 1.0; proposed). It rises when reports are confirmed or match official data and falls when they are resolved against, upheld as disputed or removed. It is never shown, and levels never raise it.
- Reports sharing a device, account or attestation key count once.
- Coordinated clusters are detected from correlated signals — a shared network or IP, attestation anomalies, identical reports within seconds — never from install time alone. A neighbourhood installing together after a storm is expected.
- In crisis mode or inside an official hazard area, new devices count at full weight (1.0) for area layers (luz, agua, señal, carreteras).

**Proximity:** a report must be captured near its place or inside/next to its area; the server re-checks with a coarsened location. Remote reports are refused with an explanation.

**Sabotage defences** (proposed values):
- A single unverified negative never flips a place's answer; it shows as a promoted Sin verificar suffix.
- A verified owner's reports and votes on competing places of the same kind within 5 km count at weight 0.
- Repeat negatives on the same place, brand or owner on 3+ days in 14 drop to weight 0 for that target and queue for review.
- ≥5 negatives on one place in 30 min from new devices freeze its label and queue it.
- Price outliers are held out of the median until confirmed.
- Photos stay private until the report is confirmed or reviewed.

**Review and removals.** Most disputes resolve automatically through votes and reversals. The dashboard review queue takes outliers, bursts, owner appeals and in-app "Reportar error" (required by App Store guideline 1.2). Biombo staff review island-wide; authorities only within scope. Resolving needs a reason from a fixed list (No coincidía con otros reportes · Lugar equivocado · Duplicado · Contenido inapropiado · Resuelto). A removed item leaves the map and counts and appears in history as one anonymous line ("Reporte retirado · no coincidía con otros reportes"); inappropriate content isn't shown at all. The reporter sees the removal and reason in Tu aporte; owners can appeal once per item and never see report metadata. Every authority and staff action is audit-logged.

**Owner verification:** Sign in with Apple, presence at the place when claiming, and one proof of control (open decision 22). Verification lasts 12 months (proposed) and is revoked on transfer, upheld abuse or a successful challenge. A place can have several staff seats. Charger networks can claim their chargers the same way.

**Owner content:** owner free text (posts, event titles) is filtered against agency names and alert vocabulary ("AAA", "LUMA", "hierve el agua", "refugio"…) and can never create an alert-class item. Anyone can hide a business's posts ("Ocultar publicaciones de este negocio").

### Operations

Biombo staff carry three queues, and all of them peak in a storm, when staff are affected too:
- **Hand entry:** AAA plans, comunicados and boil-water notices; DTOP closures; DACO orders.
- **Geography:** gazetteer aliases and unmatched LUMA sector names.
- **Review:** outliers, bursts, "Reportar error", appeals and "Vi un aviso" items.

**Nothing waits on review.** Every queued item has a safe automatic outcome: held prices and burst reports expire with their window, frozen labels unfreeze after 12 h (proposed), unmatched sectors show as text, "Vi un aviso" stays a depth line, and appeals simply wait. Only hand entry has a latency target (open decision 12). Because boil-water notices depend on transcription, the Agua sheet always says in depth "Los avisos de AAA pueden tardar en llegar a Biombo. Confirma con AAA: 787-620-2482." The authority pilot (§12) is the plan for moving AAA and DTOP entry to the agencies themselves.

## 6. Layers

Each layer: glance question → the one answer → what's one level deeper → depth. Report types are also the Siri report types. Crisis behaviour is in §8.

**Official coverage at launch** (what users will actually see before any partnership):

| Layer | Official at launch | Depends on |
|---|---|---|
| Gas prices | DACO reference, ingested | — |
| Luz | None; community only. No ETR, no "Coincide con LUMA" | LUMA written permission (open decision 1) |
| Agua | AAA plans and comunicados, staff-entered | Staff (§5 Operations); AAA seats later |
| Señal | Community only; FCC DIRS municipio figures while DIRS is active | A declared disaster |
| Carreteras | NWS alerts and river gauges, ingested; DTOP closures staff-entered | Staff; DTOP seats later |
| Fuel availability, Cargadores, Negocios | None by design | — |

### 6.1 Gas prices
- **Glance:** "Where's the cheapest gas near me, and can I trust the price?" Answer: "Gasolina desde $0.99/L cerca"; station hero price for the default grade plus the trust suffix.
- **Full:** a price ladder — the DACO reference for this station's brand and grade, this station, ≤5 nearby — headlined "3¢ menos que la referencia de DACO"; one trend line in words ("Bajó 4¢ este mes"), no chart; other grades; service type; confirm row. **Depth:** the trend chart, the reports behind the answer, DACO value and date, older reports, "Fuente: DACO. Biombo no está afiliado con DACO."
- **Report:** price by grade (Regular / Premium / Diésel) with an optional sign photo (OCR fills the price, the user confirms); service type as a remembered station attribute; restock-date sign if that order is in force; "Estación cerrada / no existe".
- **Answer rule:** median of fresh reports once there are ≥3 (proposed), else the latest confirmed, else the latest unverified shown as Sin verificar. Fresh reports more than 5¢/L apart promote "Reportes no coinciden". Reports far outside DACO's island range (15¢/L; proposed) are held out and reviewed.
- **DACO comparison:** DACO publishes one estimated pump price per brand per day, island-wide, and doesn't set prices. So:
  - it is called **"la referencia de DACO"** ("Ref. DACO" in tight labels); never "precio oficial", "máximo", "tope", "legal", "sobreprecio", "ilegal" or "abuso";
  - comparison is same brand, grade and unit; stations off DACO's brand list compare against DACO's island range ("Dentro del rango que publica DACO");
  - direction and size only, "Igual que la referencia" within ±1¢ (proposed); never implies a violation;
  - the reference is dated when not today's and drops out of the answer past 3 days (proposed).
- **Per-station trend:** community reports only, one point per day (that day's answer), gaps never interpolated, shown once there are ≥3 report-days over ≥7 days (proposed). The DACO brand line in the depth chart comes from Biombo's own daily snapshots (DACO keeps no history) and is labelled with its start date. 30 days by default, 90 on request.
- Prices never trigger notifications (§9).

### 6.2 Power (luz)
- **Glance:** "Is my area out, since when, and when might it come back?" Answer: "Caguas sigue sin luz desde las 3:10 p. m. LUMA estima que vuelve mañana en la tarde." / "Hay luz en Bo. Miradero."
- **Map:** affected-area polygons (§7), no per-report pins at area zooms.
- **Full:** restore-time bar (elapsed solid, estimate labelled "estimado"), "Dónde" (≤3 barrios), "Lo que dicen los vecinos" plus confirm row. **Depth:** polygon confidence, source agreement, timeline, labelled automated summary, LUMA's statement and its time.
- **Report:** No hay luz aquí · Volvió la luz · Luz bajita / va y viene · Poste o cable caído · Transformador explotó.
- **Hand-off:** the sent state of every luz report carries "Esto no avisa a LUMA · Reportar a LUMA". Poste o cable caído and Transformador explotó also show "Aléjate. Si hay peligro, llama al 911."
- **Official:** LUMA sector lists (→ approximate official area), load-shed feeder polygons (exact), notable-outage ETRs, region counts (context and crisis trigger only, never drawn). All need LUMA's written permission (open decision 1). An ETR in the past becomes "LUMA no ha actualizado el estimado".
- **Without LUMA data:** the answer is community-only, the restore-time bar shows elapsed time only, confidence never says "Coincide con LUMA", and there is no Oficial row.
- **Edge cases:** below the device threshold at every aggregation level (§7) there is no polygon — the reporter sees "Parece que es solo tu casa o tu calle", with a link to LUMA. Planned and load-shed outages are named as such. Unmatched LUMA sector names show as text and queue for gazetteer review.

### 6.3 Water (agua) and boil-water notices
- **Glance:** "Does this barrio have water right now, and is it safe to drink?"
- **Answer:** "Guaynabo está en el plan de interrupciones: sin agua hasta el jueves a las 6 a. m." An active official boil-water notice is always a card directly under the answer, with its actionable line.
- **Full:** rationing calendar as a restore-time bar, "Lo que dicen los vecinos", water distribution points. **Depth:** AAA comunicado link and date, plant, zones, older reports, the transcription-delay line (§5 Operations).
- **Report:** No hay agua · Volvió el agua · Baja presión · Agua turbia · Vi un aviso de hervir · Oasis / camión cisterna aquí · Tubo roto. The sent state carries "Esto no avisa a AAA · Reportar a AAA".
- **Official:** AAA planned interruptions and comunicados, entered by staff or authorities (no feed).
- **Boil-water rules:**
  - Only an AAA comunicado or a verified authority entry creates a notice. Community "Vi un aviso" reports never do; they show as one depth line and raise a dashboard item.
  - A notice stays until lifted. After 72 h with no update (proposed) it shows its age and "Confirma con AAA".
- **Edge cases:** when a plan's window has passed but neighbours still report no water, say both. Top and bottom of a barrio can differ; clustering is spatial and never averaged. Non-PRASA community systems get community reports only.

### 6.4 Cell signal (señal)
- **Glance:** "Is there signal here, on my carrier, and where can I get it?" Answer per the user's carrier: "Claro no tiene señal en esta área desde hace 2 h."
- **Full:** by carrier (Claro, Liberty, T-Mobile, AT&T); "Puntos de señal". **Depth:** FCC figures when present, older reports.
- **Report:** Sin señal · Solo llamadas / SMS · Hay datos · Punto de señal aquí — carrier auto-filled from the user's setting.
- **Official:** FCC DIRS per-municipio "% de antenas fuera", only while DIRS is active; attached to the municipio, never drawn as a polygon. Outside disasters, community only.
- **Edge cases:** reports from dead zones arrive late via the outbox and cluster by capture time. Polygons are per carrier; area zooms show a carrier-agnostic count only when ≥2 carriers agree.

### 6.5 Fuel and generator availability
- **Glance:** "Where's the nearest place that has what I need?" Community and owner only; no official source.
- **Not a separate Capas row:** it is the "Disponibilidad" mode of Gasolina. Crisis switches Gasolina to it; otherwise it's one tap away inside the layer.
- **Answer:** "Hay gasolina en 2 estaciones cerca. La más cerca es Puma, con fila de unos 20 min." A Gasolina / Diésel switch sits under it.
- **Sections:** "Hay gasolina" (≤3 rows) · "Abiertos con planta" (hielo, comida, farmacia) · bad news collapsed into one row ("1 estación sin gasolina · Ver").
- **Report:** Hay / No hay gasolina · Hay / No hay diésel · Fila de unos N min · Solo efectivo · Límite por persona · Abierto con planta · Hay hielo · Hay gas de cocinar. Verified owners can post these for their own place.
- **Rules:** an owner "hay" contradicted by ≥3 community "no hay" (proposed) shows the dispute as the news; neither is hidden.

### 6.6 Roads (carreteras)
- **Glance:** "Can I get through, and what's in the way?" Event rows ("Inundada la PR-52, km 14"); near a watched place, "Cerca de Casa de Mamá hay 1 cierre reportado".
- **Safety:**
  - Biombo never states that a road is safe. With no problem reports the answer is "Sin reportes de problemas"; after a reopening it is "Reportada abierta · hace 2 h". Never "pasable", "segura", "se puede pasar" or "despejada".
  - Every flood item always shows "No cruces carreteras inundadas." Every hazard report's sent state shows "Aléjate. Si hay peligro, llama al 911."
  - Road reports take no photos, and hazards earn no points beyond the confirmation (§10), so nothing rewards approaching a flood or a landslide.
- **Full:** the segment, "Lo que dicen los vecinos", "¿Sigue cerrada?". **Depth:** the official release and its time, the related NWS alert and river gauge, older reports.
- **Report:** Inundada · Derrumbe · Cerrada · Un carril · Solo vehículos altos / 4x4 · Árbol o poste · Hoyo peligroso · **Abierta otra vez**, which weighs the same as a closure because official lists rarely retract closures.
- **Official:**
  - NWS alerts are hazard areas that raise the prior for flood reports inside them; they never mark a road closed.
  - River gauges are depth context only.
  - DTOP closures are hand-structured (PR-number + km + municipio) with their release time, never auto-scraped.
- **Edge cases:** official closed vs ≥5 devices reporting open within 6 h (proposed) shows both. Reports off known segments snap to the municipal/rural road source (open decision 8) or stay points.

### 6.7 EV chargers (cargadores)
- **Glance:** "Is there a working charger near me, and does it usually work?"
- **Answer:** "Funciona · confirmado hace 40 min" plus reliability in words ("Suele funcionar", "A veces falla", "Falla a menudo").
- **Primary verb: "Abrir en…"** → Apple Maps / Google Maps / Waze. There is no in-app route planner. No public deep link adds a stop to an active route, so the hand-off opens directions (open decision 13).
- **Full:** connectors, per-connector status, confirm row. **Depth:** 90-day reliability history with counts, older reports, directory source.
- **Report:** Funciona · No funciona · Carga lenta · Conector dañado · Ocupado / hay fila · Bloqueado por un carro que no carga · Pide app o tarjeta · Cargador nuevo aquí.
- **Reliability:** from Biombo user reports only — the recency-weighted share of Funciona over 90 days, shown once there are ≥5 reports from ≥3 devices (proposed); otherwise "Todavía no sabemos si suele funcionar". External datasets (including AFDC `status_code`) are never used for status or reliability; AFDC seeds locations only.
- **Edge case:** a charger inside a business shows "Cerrado ahora" before any status.

### 6.8 Businesses and events (negocios)
- **Glance:** "Is it open (and on generator), and what's happening?"
- **Answer:** "Abierto con planta hasta las 8 p. m. · Dueño verificado hoy"; events as dated rows.
- **Owner posts** (verified owners only; filtered per §5): Abierto · Cerrado hoy · Abierto con planta · Hay (producto) · Evento (title, start, end) · Horario especial.
- **Community:** Está abierto · Está cerrado · Tiene planta — can dispute owner posts, never hide them. On a business, community reports show as counts with coarse ages ("hoy en la tarde"), never exact times, so an owner can't tell which customer reported.
- **Lifetimes:** events leave the map at their end time and stay in depth for 30 days. No official source.

## 7. Outage areas (polygons)

Power, water and signal (per carrier) aggregate into **affected areas**. Roads use segments; weather hazards use NWS geometry as published.

- **Objects:** community areas (clusters of agreeing reports), official areas (LUMA sector-list areas, LUMA feeder polygons, AAA scheduled zones, authority entries), reconciled into one **affected area** with a lifecycle state, verification label, confidence and answer sentence.
- **Clustering** (all proposed):
  - Each report weighs trust × recency decay; one device counts once per unit; "volvió" reports weigh negative.
  - **Hierarchical:** evaluate hexagonal map cells at H3 res 9 (~175 m), then res 8 (~460 m) and res 7 (~1.2 km), then the barrio polygon. Neighbouring cells are summed before the threshold is applied. The area is drawn at the smallest unit that reaches weight ≥2.0 **and** ≥3 distinct devices, so sparse rural outages still show, just coarser.
  - Where housing is sparse (below a Census density threshold), the barrio is the smallest unit drawn or exported, so 3 reporters never map to 3 identifiable homes.
  - Out units merge. The shape snaps to an official or gazetteer geometry when ≥60% overlaps it.
  - Area ids persist across splits and merges so watches and history stay attached.
  - Nothing is drawn below 3 distinct devices at any level; the lone reporter sees "Esperando que otros vecinos confirmen".
- **Confidence** (depth only, in words): **Baja** "Pocos reportes todavía" (3–4 devices) · **Media** "Varios vecinos coinciden" (≥5, or ≥3 inside an official hazard) · **Alta** "Coincide con LUMA" / "Muchos vecinos coinciden" (official match, or ≥10 devices with <20% dispute). The row label follows: any official area → Oficial; Media/Alta → Confirmado; Baja → Sin verificar.
- **Reconciliation — never average, show both:**
  1. Official out, community agreeing → official area; confirmations raise confidence.
  2. Official out, neighbours report "volvió" in part → the outline stays; that part is marked restoring. Neighbours can never delete an official area.
  3. Community out, no official counterpart → community area; after 60 min at Media+ (proposed) it enters the authority queue.
  4. Official restored, neighbours still out → "restoring", with both statements, until community weight decays or flips.
  5. Community extends beyond the official outline → one area; each part carries its own label.
  6. Official feed stale → the official part shows its age and loses its override.
  7. Planned outage vs neighbours reporting service back → the neighbours win the answer; the plan stays in depth.
- **Lifecycle:** open → confirmed → restoring → closed. A confirmed area turns aging as its evidence ages but closes only on reversal evidence, official restoration or the ceiling (§4.4). New outage weight within 2 h of closing (proposed) reopens the same id ("Se volvió a ir"). Closed areas are kept for history.
- **By zoom:** island zoom shows per-municipio counts ("Caguas · 4 áreas sin luz"), no polygons. Municipio zoom shows confirmed and official areas. Barrio and street zoom also show open areas. VoiceOver reads each area's answer and label.

## 8. Crisis mode

**Turns on** (thresholds proposed) when any holds:
1. an NWS Hurricane or Tropical Storm Warning for any PR zone;
2. LUMA island customers out ≥10% for ≥30 min (only once LUMA data is permitted);
3. FCC DIRS activated for PR;
4. community power areas covering ≥15% of municipios within 2 h — the trigger that works without LUMA;
5. an authority (NMEAD) or Biombo staff declaration.

Triggers 2 and 4 can apply per LUMA region, and declarations can name municipios.

**What changes:**
- Luz, Agua, Señal and Carreteras come first and expanded. "Del día a día" collapses to one row.
- Gasolina switches to Disponibilidad (§6.5), and prices step back to station depth.
- The home glance question becomes "What do officials say, and where can I get fuel?". Its Oficial section holds NWS warnings, authority posts, boil-water notices, any active DACO price-freeze order, and a PREPS link while PREPS is active.
- Every budget tightens: at most 3 rows, a mandatory answer sentence, sections ordered Oficial → Vecinos → Lugares, and bad news collapsed into one row.
- Copy goes plain, and promotional events are hidden.
- Point-report windows are unchanged; confirmed outage areas persist up to the crisis ceiling (§4.4). Feed staleness is surfaced more prominently.
- New devices count at full weight for area layers (§5).
- Watched-place pushes batch (§9).

**Load.** In crisis the island and the diaspora refresh at once on degraded networks, so the read path is snapshots:
- answers and polygons are precomputed per municipio and map tile and served as CDN-cacheable snapshots with short TTLs (60 s; proposed);
- pushes fan out in batches;
- the outbox retries with backoff and jitter (§4.6);
- the app's low-bandwidth mode (no photos, snapshots only) turns on in crisis and on constrained networks.

**Turns off** only after every automatic trigger has been clear for a hold period: no warning, LUMA below 5% for 6 h, DIRS deactivated, and community areas below 5% of municipios for 6 h (proposed). A source Biombo doesn't have (such as LUMA before permission) is left out of this check. **A source that was live and then lost never counts as "all clear."** A declared crisis ends only by declaration. The end is announced once, in one sentence.

## 9. Watching places and notifications

- **Watch** saved places ("Casa de Mamá") and specific stations, chargers or businesses. No account and no location permission are needed. Luz, Agua (including boil-water) and Carreteras cerca are on by default. Up to 10 places per device (proposed).
- **Privacy:** watched places live on the device. The server gets only an area id or a coarse location plus the chosen layers, keyed to the push token under a separate random id that is never joined to the reporter id.
- **Only confirmed state changes notify:** transitions backed by Oficial, Dueño verificado or Confirmado evidence. Sin verificar never pushes, and **price changes never notify**.
- **Triggers:**
  - power or water out/back, and boil-water issued/lifted, at the place;
  - a road within 2 km closed or reopened;
  - an NWS warning covering the place;
  - a watched station out of fuel or supplied again (crisis only);
  - a watched charger's status;
  - a watched business's owner posts.
  - Area notifications fire on confirmed, restoring, closed and reopen — never on a new unconfirmed area, and never when an area only reaches its ceiling.
- **Damping** (proposed):
  - a change must hold 10 min before it notifies;
  - at most 1 push per 30 min per place per layer, merged ("Volvió y se fue otra vez");
  - at most 6 per place a day, then an hourly digest;
  - at most 20 per device a day;
  - in crisis, an hourly digest except time-sensitive items.
- **Quiet hours:** 10 p.m.–7 a.m. in the **device's** time zone, so family off-island isn't woken; on by default. Only time-sensitive official items break through, and the rest arrive as a morning digest. No Critical Alerts.
- **"Tu reporte ayudó"** feedback is in-app, not a push (§10).

## 10. Contributing and progression

- **One tap at a red light:** Quick Report (§4.2), Controls on the Lock Screen and Action button, and voice (§11). No forms. Typing a price waits until the user stops (§4.2).
- **Feedback:** "Tu reporte ayudó a 34 personas" in-app — an estimate of the distinct devices that saw the report as a place's answer while it was fresh, counted with a per-report de-duplicating sketch (e.g. HyperLogLog) so no per-device view log exists. Feedback only; it earns nothing.
- **Progression ("Tu aporte"):**
  - 5 levels (thresholds 0 / 10 / 40 / 120 / 300 points; proposed). Levels are named in Puerto Rican Spanish, never go down, and unlock recognition and moments of delight only.
  - **No leaderboards, no public profiles, no comparison with others.** A level is visible only to its owner.
- **Points come only from outcomes, never from sending** (proposed values):
  - report confirmed or matching official data: +3;
  - confirmed reversal: +3;
  - vote agreeing with the final resolution: +1;
  - first confirmed report of the day: +1 (no streaks);
  - report resolved against or removed: −2, and the level floor holds.
  - Hazard reports (floods, landslides, downed lines, explosions) earn only the confirmation points, never the daily bonus.
  - Capped at 15 a day. Late and weight-0 reports earn nothing.
- Levels never affect trust weight; reputation is separate and hidden.

## 11. Siri and Apple Intelligence

Siri is a way to report and ask without opening the app — not a chat surface. Answers use the same templates as the app. Stale data is never spoken as current: "No hay reportes recientes de luz en Caguas." An aging outage is spoken with its age first ("El último reporte de apagón en Caguas es de hace 9 horas").

**Intents:**
- `ReportConditionIntent` — layer and status as enums, place (defaults to a one-shot current location). It shows a confirmation card, "Se enviará: No hay luz · Calle Degetau, Caguas" → Enviar (open decision 15), then goes to the outbox. Whether an intent can get a When In Use fix without the app in the foreground is unverified (open decision 16); until it is, the intent opens the app or asks for a saved place.
- `CheckConditionIntent` — "¿Hay luz en Caguas?"
- `CheckFuelIntent` — nearest, cheapest or has-fuel, then "Abrir en…" or "Ver más".
- `WatchPlaceIntent` and `CheckWatchedPlaceIntent` — "¿Cómo está Casa de Mamá?"
- `ConfirmReportIntent` — Sigue igual / Ya no, from a plain notification action on every iOS version.
- `OpenPlaceIntent` / `OpenLayerIntent` and search, using in-app routing with no URL schemes.
- `PostBusinessStatusIntent` — verified owners only, always confirmed.
- Nothing is deleted, claimed or changed about progression by voice.

**App Shortcuts:** up to 10, ES source with EN parallels: report no power / power back / no water / a road / a price / something else; check a layer; check a watched place; fuel; watch a place. Every phrase must contain the app name, so the brief's "Oye Siri, reporta que no hay luz en mi calle" works as **"Reporta en Biombo que no hay luz"** (open decision 14). Siri tips appear on Quick Report, watched-place detail and station detail.

**Device tiers:** every voice action works on iOS 26 without Apple Intelligence. On-device models only speed things up:
- parsing free-form speech ("la PR-52 está inundada por el km 14"), validated against the road layer, with a rule-based parser plus follow-up questions as the fallback;
- the labelled "Resumen automático" in the depth tier;
- a "Qué cambió" digest of structured events for a watched place;
- Visual Intelligence opening a price sign in the report screen, which never writes on its own.

Official comunicados are structured at ingest and reviewed by a person, not summarized on the phone.

**Donations** come only from in-app actions and never carry a place. Only watched places are indexed in Spotlight.

**Other system surfaces:**
- Controls: Reportar, "No hay luz aquí", "Volvió la luz" (open decision 16).
- A watched-place widget and a gas widget, both saying "Sin reportes recientes" rather than keeping an old value.
- An outage Live Activity — the only Live Activity — shown only while a watched place is inside an active outage area. It shows elapsed time, plus LUMA's ETR when one exists; a community estimate is never shown as the restore time. It ends when the area clears or after 8 h.
- Widgets and Live Activities still need an SDK check (`docs/APP_INTENTS.md` covers Controls only).

## 12. Authority dashboard

- **Who:** NMEAD and municipal emergency offices (OMME), municipios, DTOP/ACT, LUMA, AAA, DACO, and possibly Salud PR.
- **Access:** invitation only. Staff invite a named agency contact after confirming them through the agency's published phone number or email, and that contact becomes the agency admin who invites their own staff. Each seat is scoped by agency × layers × municipios, signs in with a passkey (open decision 23), and every write is audit-logged.

**Beyond the app, it shows:**
- polygons over time (24 h / 7 d scrubber);
- report density per barrio or road segment, with agreement bars;
- island → municipio → barrio drill-down, each level opening with an answer sentence;
- official vs community disagreement side by side (its most useful signal);
- the moderation queue ("Confirmar como aviso oficial" as the primary action; a resolve reason is required);
- official notices with a mandatory expiry: closure (snapped to DTOP road segments), shelter, distribution point, boil-water, price freeze;
- CSV and GeoJSON export of the filtered view;
- later, an EAGLE-I "usual vs now" baseline.

**Rules:**
- An agency posts and expires its own notices. It resolves or merges community reports with a logged reason, but never edits or deletes them.
- High-harm notices (boil-water, shelter, closure) need a source link or a second approver.
- Staff transcriptions are recorded as "transcrito por Biombo" (§4.5).
- A dashboard notice replaces scraping for that agency.

**Never exposed:**
- reporter identity in any form (device, attestation key, Apple ID, level, history);
- where a reporter was, or one device's trail — reports appear only as the place they're about;
- watched places or watcher counts;
- any density cell or export below the minimum unit (open decision 24);
- photo metadata.

**Minimum version:**
1. One pilot, NMEAD plus one or two OMME, with passkey seats.
2. A scoped map of current polygons, notices, community clusters and report density by barrio, filtered by layer and municipio.
3. The moderation queue.
4. Closure, shelter and distribution-point notices with expiry.
5. CSV and GeoJSON export.

Trends over time (the scrubber) and everything else follow the pilot. The dashboard shares the backend API.

## 13. Privacy and accounts

| Action | Sign-in? |
|---|---|
| View map, places, official alerts, older reports | No |
| Watch places and get pushes | No |
| Report and vote | No (device + App Attest) |
| Keep progression across devices | Optional Sign in with Apple |
| Post as a verified owner | Sign in with Apple + verification |
| Authority dashboard | Invited organisation seat |

**Location**
- Location is When In Use only, with a one-shot fix per report or vote. There is no Always and no background tracking.
- Viewing and watching work with location denied.

**Stored reports**
- Place and road reports keep the place or segment.
- Area reports are rounded to about 100 m (proposed).
- The raw coordinate is discarded after the proximity check.
- Area reports below the device threshold show only at barrio level, never as a point (§7).

**Anonymity**
- No names, handles or avatars appear anywhere. People are counts in words ("6 vecinos").
- Owners never see exact report times or report metadata (§6.8, §5).
- Photos have EXIF and GPS stripped on the device.
- Voice is processed by Siri. The app receives only the intent parameters.
- "Tu reporte ayudó" keeps no view log (§10); watch subscriptions are never joined to reporters (§9).

**User-generated content:** App Store age rating 13+ (proposed). Owner text is filtered, any business's posts can be hidden, and "Reportar error" is on every item (§5).

**Retention** (proposed; open decision 28)
- The public view ends at the show-older horizon.
- De-identified reports are kept for trends: prices indefinitely, other layers 2 years.
- The link from a report to a device or account is dropped after 90 days, and the reputation score is kept.
- Audit logs are kept 2 years.
- "Borrar mis datos" is in the app for every tier, device-only included: it drops every link at once and resets the device id.
- No advertising and no data sale.

Signing in later merges the device's history. Signing out leaves reports in place, de-linked on the normal schedule.

## 14. Checkpoint integration

This is a quiet link through `packages/VehicleSharing`, used as it is.
- After a gas-price report, if the bridge lists a vehicle, the sent state gets one row: "Anotar millaje en Checkpoint".
- How the reading is entered is open decision 20. The row pre-selects the last vehicle and queues the reading; Checkpoint validates and commits it.
- Biombo never writes Checkpoint data directly, and has no odometer screens.
- Without Checkpoint or vehicles, the row doesn't exist and there is no promo.
- There is no deep link until the URL-scheme question is settled (open decision 29).

## 15. Build order

1. **Platform primitives:**
   - places and directory seeding
   - the report pipeline with offline outbox and idempotency
   - confirm/dispute, freshness gating and "Ver reportes anteriores"
   - verification labels, reputation, rate limits and App Attest (with deferred attestation)
   - the official-feed ingester framework
   - the map and sheet shell with the disclosure tiers
   - ES/EN templates, and Tu aporte scaffolding
2. **Gas:** DACO ingest and daily snapshots, station answers and median, the DACO comparison, per-station trends, and OCR evidence.
3. **Utilities, polygons and dashboard:**
   - luz, agua (with boil-water), señal, and fuel and generator availability
   - hierarchical clustering, reconciliation, the lifecycle and outage ceilings
   - watching and notifications, and crisis mode with the snapshot read path and low-bandwidth mode
   - staff hand-entry tools and the dashboard MVP pilot
4. **Roads:** NWS alerts, DTOP geometry and closures entered by hand or through the dashboard, and reopen handling.
5. **Chargers:** AFDC seed, user and owner additions, reliability, and "Abrir en…".
6. **Businesses and events:** owner claims and verification, owner posts, and events.
7. **Siri and voice across layers:** intents, App Shortcuts, Controls, widgets, the Live Activity, and on-device parsing and summaries. Each layer's report enums are defined from phase 1, so voice reaches every shipped layer here.

## 16. Open decisions

Each has a recommended default.

**Data partnerships, sources and operations**
1. **LUMA and AAA data permission.** LUMA's terms forbid automated access without written permission. *Default:* request it now through the dashboard pilot. Luz is community-only until it is granted.
2. **Who structures DTOP closures and AAA plans or boil-water notices before those agencies have seats.** *Default:* Biombo staff transcribe them, labelled with the release time and a source link (§4.5); boil-water, shelter and closure entries need the link or a second approver.
3. **FEMA IPAWS registration**, the only automated route to NMEAD and municipal alerts. *Default:* register.
4. **FCC DIRS ingest.** *Default:* parse the TXT reports, with staff review.
5. **Salud PR boil-water list.** *Default:* ask Salud. Until then, rely on AAA comunicados and authority entries only.
6. **Gazetteer.** The base geometry for LUMA and AAA sector names, and who maintains the alias table. *Default:* Census barrios plus LUMA feeder polygons. Biombo staff maintain the aliases.
7. **Station directory.** Seed from OSM under the ODbL share-alike licence, or wait for DACO's registry. *Default:* seed from OSM after ODbL review, and switch to DACO's registry when it is published.
8. **Municipal and rural road geometry.** *Default:* adopt OSM roads.
9. **Velocicharge and other local networks.** *Default:* onboard them as verified owners, and ask for a location feed.
10. **DACO wording.** The brief says "DACO official price". *Default:* approve "referencia de DACO", and ask DACO how it derives the number.
11. **NWS alert history beyond 7 days.** *Default:* archive the alerts ourselves.
12. **Operations staffing and hand-entry latency** (§5). *Default:* two staff on rotation, with an off-island backup during crisis; boil-water and closures entered within 1 h of publication from 7 a.m. to 10 p.m. and within 4 h overnight. Make no latency promise in the app; the "Confirma con AAA" line covers the gap.

**Product and UX**

13. **"Abrir en…" vs "Añadir parada".** No public deep link adds a stop to an active route. *Default:* keep "Abrir en…", which opens directions only.
14. **Siri phrasing.** A phrase needs the app name to work. *Default:* use "Reporta en Biombo que…" and hallway-test it with Puerto Rican speakers.
15. **Voice report: confirm or send.** Show a confirmation card, or send at once with Deshacer. *Default:* show a confirmation card.
16. **Control tap: send or open, and location from intents and Controls.** It is unverified whether a Control or a Siri intent can get a When In Use location fix while the app isn't in the foreground. *Default:* verify it in the SDK first (as for widgets). If it works, a Control sends at once with Deshacer; if not, it opens Quick Report prefilled, and the Siri intent asks for a saved place or opens the app.
17. **Maps schema domain.** Apple's rule is "only real matches", and Biombo is not a navigation app. *Default:* don't adopt it; use App Shortcuts plus `.system.*`.
18. **Nearby-only voting.** It excludes the diaspora. *Default:* keep it. Revisit an "estuve aquí" window of 2 h.
19. **Crisis triggers.** The thresholds, and whether an authority can declare crisis per municipio. *Default:* automatic triggers plus declarations, with per-region and per-municipio declarations allowed.
20. **Checkpoint odometer entry.** One numeric field inline in the sent-state row, or open Checkpoint's mileage sheet (which needs a deep link, open decision 29). *Default:* one inline numeric field pre-filled with the last reading, queued through the bridge; no other odometer UI.

**Identity and trust**

21. **Identity tier.** *Default:* device plus App Attest, with Sign in with Apple optional. Sign in with Apple is required for owners.
22. **Owner proof.** *Default:* presence at the place plus a code sent to the place's public phone number. A staff-reviewed business document is the fallback, and the DACO registry can be used for stations once it is published.
23. **Authority login.** *Default:* invitation-only passkeys.

**Dashboard and privacy**

24. **Minimum unit before a density cell, polygon or export shows.** *Default:* 3 distinct devices, and the barrio as the smallest unit where housing is sparse (§7).
25. **PDF situation snapshot in the dashboard MVP.** *Default:* later.
26. **Evidence photos.** *Default:* price signs only (no road or hazard photos), private until confirmed or reviewed; faces and plates are rare on signs, so no blurring at launch.
27. **Dashboard frontend stack.** *Default:* SolidJS, matching the Checkpoint site and the sketchpad.
28. **Retention periods and a public no-ads / no-data-sale commitment.** *Default:* the periods in §13, and commit publicly.
29. **The `biombo://` URL scheme** conflicts with the no-URL-schemes rule. *Default:* universal links.

**All numbers**

30. **Every *(proposed)* number** — confirmation weights, dispute thresholds, decay windows, outage ceilings, push caps, quiet hours, crisis thresholds, polygon rules and the age rating. *Default:* accept them as launch values and tune them from real report data.

## 17. Requirements coverage

Sign-off scaffolding; delete once the owner signs off.

| Requirement (brief + owner decisions) | Section |
|---|---|
| Map of everyday life in PR; iPhone app + authority web dashboard | 1, 12 |
| Gas: DACO vs community-reported price comparison | 6.1 |
| Gas: per-station price trends | 6.1 |
| Power, water (incl. boil-water), signal from official sources + users | 6.2–6.4; what is official at launch: §6 table |
| Outages aggregate into affected-region geo-polygons | 7 |
| Fuel and generator availability during outages | 6.5, 8 |
| Road passability: floods, landslides, closures | 6.6 |
| EV chargers: user-reported status; reliability from user reports only, never an external dataset | 6.7 |
| EV hand-off to Apple Maps / Google Maps / Waze; no route planner; "Abrir en…" label | 6.7, OD 13 |
| Businesses: open, on generator, events, verified owner | 6.8, 5 |
| Audiences: residents (incl. large-text elders), diaspora, visitors (EN, gallons), owners, authorities | 2, 3 (accessibility) |
| One clear answer per place; progressive disclosure; detents = tiers | 3 |
| Freshness gating: stale hidden by default, "Ver reportes anteriores" reveal with age | 3, 4.4 |
| Verification labels: Oficial, Confirmado por la comunidad, Dueño verificado, Sin verificar | 4.5 |
| Confirm/dispute on reports | 4.3 |
| Official alerts distinct from community reports; never blended | 3, 7 |
| One-tap reporting at a red light, no forms | 4.2, 10 |
| Voice-first reporting via Siri | 11, OD 14–16 |
| "Your report helped" feedback | 10 |
| Progression / levels, no leaderboards | 10 |
| Siri / Apple Intelligence native, not AI-centric, no chatbot | 3, 11 |
| Tone matches stakes; crisis mode | 3, 8 |
| Spanish-first with English parallel; no concatenated sentences | 1, 3 |
| Watching a place (diaspora) and notifications | 9 |
| Authority dashboard: polygons, density/trends, municipio + layer filters, export | 12 (trends over time after the pilot) |
| Accessibility (Dynamic Type, VoiceOver for map content, never colour alone) | 3, 7, `DESIGN.md` |
| Trust, abuse defences, moderation, operations | 5 |
| Privacy and accounts | 13 |
| Offline reporting | 4.6 |
| Checkpoint integration | 14 |
| Visual direction (Apple-native, warm civic) | `DESIGN.md` (not formalized here) |
