# Biombo — Official data sources

Researched 2026-09-27. One entry per official source Biombo plans to use; how each merges with community reports is in `PRODUCT.md` §6–7. **UNVERIFIED** marks anything not confirmed against a primary source. Sources researched and rejected are not listed. What users actually see as official at launch, given the permissions below, is the coverage table in `PRODUCT.md` §6.

Rules for every source:
- Official items are labelled "Oficial · <agency>" with the source timestamp. They are never averaged with community data.
- Where terms are unclear or restrictive, facts are entered by hand or through the authority dashboard, not scraped.
- Poll politely, cache the raw payloads, and keep our own history where the source keeps none.

## Gas

### DACO — per-brand pump price
- **URL:** https://www.daco.pr.gov/recursos ("Datos de Combustible")
- **Data:** one estimated pump price per brand (about 15 brands) for Regular, Premium and Diésel, each with an "Actualizado" date. The page doesn't label the unit; ¢/L is inferred from the values (114.7 ⇒ $1.147/L). There are no station-level or municipio-level prices.
- **Access:** server-rendered Webflow HTML, readable with a plain GET. There is no API. Parse the brand text, not the generated class names.
- **Cadence:** about daily on business days. Weekend behaviour is **UNVERIFIED**.
- **Terms:** no terms page found (**UNVERIFIED**), and `robots.txt` is empty. Ley 122-2019 makes open reuse of executive-branch data public policy; a House bill to repeal it (PC 1303) is pending, so check its status before launch rather than leaning on it. Attribute "Fuente: DACO" and state non-affiliation.
- **Caveats:**
  - The price is an estimate, not an observation, and DACO doesn't set prices. The page that says so wasn't found on /recursos (cite it once located), and how DACO derives the number is **UNVERIFIED**.
  - DACO keeps no history, so we snapshot the value daily.
  - DACO's brand names differ from the wholesaler names, so we keep an alias table.
- **Community fills:** actual per-station prices, per-station trends, service type, and stations off the brand list.

### DACO — island retail range
- **URL:** https://www.daco.pr.gov/ ("Precios Promedio de Gasolina al Detal")
- **Data:** a MIN–MAX range per grade in ¢/L.
- **Access:** HTML with stable element ids: `REG-MIN`, `REG-MAX`, `PREM-MIN`, `PREM-MAX`, `DIS-MIN` and `MIN-MAX`. The last one is DACO's id for the diesel maximum.
- **Cadence:** about daily. There is no history, so we snapshot it.
- **Use:** the comparison for stations off DACO's brand list, and the sanity band for price reports.

### DACO — price orders (scanned PDFs)
- **URL:** listed on /recursos.
- **Data:** emergency price-freeze and margin orders.
- **Access:** manual. There is no feed.
- **Caveats:** whether any margin cap is in force today is **UNVERIFIED**.
- **Use:** once staff verify an order is active, it shows as one official notice card that quotes the order number.
- **Registry:** Orden 2025-005 creates a retailer registry that "será pública". Whether it is published is **UNVERIFIED**. If it is, it replaces the OSM station seed.

## Power

**LUMA's terms ban automated access without express written permission.** No LUMA source is polled in production until we have that permission (PRODUCT.md open decision 1).

### LUMA — regions without service
- **URL:** `GET https://api.miluma.lumapr.com/miluma-outage-api/outage/regionsWithoutService`
- **Data:** for each of 7 regions, customers out, planned-outage counts and load-shed counts, plus island totals and a timestamp.
- **Access:** unauthenticated JSON.
- **Cadence:** near real time. The refresh rate is **UNVERIFIED**.
- **Terms:** the LUMA terms of service, which need permission.
- **Caveats:**
  - Region-level only.
  - No history.
  - It has frozen during island-wide events (**UNVERIFIED** for 2026).
- **Use:** context numbers and a crisis trigger, once permitted. It is never drawn.

### LUMA — outage map (towns → sectors)
- **URL:** `POST https://api.miluma.lumapr.com/miluma-outage-api/outage/municipality/towns`, with a body of uppercase town names.
- **Data:** the names of sectors currently out, by LUMA "town". There are no counts, ETR, cause or geometry.
- **Access:** unauthenticated JSON. Cadence is near real time (**UNVERIFIED**).
- **Caveats:**
  - About 93 LUMA towns need a crosswalk to the 78 municipios.
  - Sector names are free text and need a gazetteer to become shapes.
  - Per-account endpoints in the same API are off-limits.
- **Use:** the approximate official outage area.

### LUMA — Manual Load Shedding (ArcGIS)
- **URL:** `https://services3.arcgis.com/0n3sEGhALDkUSwc5/arcgis/rest/services/Manual_Load_Shedding/FeatureServer/0`
- **Data:** 792 feeder polygons with clients, municipio, sectors, stage, status and predicted time.
- **Access:** ArcGIS REST, with `f=geojson` available and no key.
- **Cadence:** only during load-shed events.
- **Base-data layer:** 78 municipio polygons, last edited in 2021.
- **Terms:** a public item with no licence text. It is handled under the same LUMA permission request.
- **Caveats:**
  - The layer belongs to a personal ArcGIS account, not an organisational one, and its schema can change without notice.
  - It covers load shed only, not faults.
- **Use:** exact official polygons during relevos, and a crosswalk from sector names to shapes.

### LUMA — notable outages (ETR)
- **URL:** https://lumapr.com/notable-outages/ (the Spanish slug is **UNVERIFIED**)
- **Data:** outages over 500 customers: municipio, sector, customers, cause and ETR.
- **Cadence:** the ETR is updated hourly.
- **Access:** a JS-loaded table. The backing endpoint is **UNVERIFIED**.
- **Use:** the only official restore estimate.

### EAGLE-I (ORNL / DOE)
- **URL:** openenergyhub.ornl.gov (`eaglei_outages_*`), plus DOI datasets on doi.ccs.ornl.gov.
- **Data:** customers out per municipio at 15-minute intervals. PR is covered from 2021.
- **Access:** bulk CSV, released annually.
- **Terms:** DOE open data. Verify the licence on each DOI.
- **Use:** history only. It gives the "usual vs now" baseline in depth and on the dashboard, and is never current.

## Water

### AAA — planned interruptions
- **URL:** https://www.acueductos.pr.gov/en-us/planes-de-interrupciones-programadas-2026
- **Data:** rationing calendars by filter plant and municipio zone. The sector lists are inside images and PDFs.
- **Access:** HTML, images and PDFs. There is no machine-readable feed, so entry is manual or assisted by staff or the dashboard.
- **Cadence:** per event.
- **Terms:** AAA states that its content is its intellectual property. Extract facts only (dates, sectors, municipios); never copy documents.
- **Caveats:** plans slip, so neighbours confirm whether a rationing day actually happened.

### AAA — comunicados (including boil-water advice)
- **URL:** https://www.acueductos.pr.gov/en-us/comunicaciones/comunicados-de-prensa
- **Data:** pipe breaks, plant stoppages, affected sectors, and boil-water advice, all in prose.
- **Access:** paginated Webflow HTML. Ingest is assisted: a person reviews the structured notice.
- **Cadence:** irregular, several a week in busy periods.
- **Terms:** as above.
- **Caveats:**
  - This is the only official boil-water source found.
  - No structured notice list exists at AAA or Salud PR (**UNVERIFIED**). We will ask Salud.
  - About 240 non-PRASA systems are not covered (count **UNVERIFIED**).
- **AAA phone:** 787-620-2482. Stale notices and the transcription-delay line point to it.

## Cell signal

### FCC DIRS Communications Status Reports
- **URL:** `docs.fcc.gov/public/attachments/DOC-*.txt`, announced in "FCC Activates DIRS … Puerto Rico" public notices.
- **Data:** per municipio: cell sites served and out, % out, and cause. Also island cable and wireline figures.
- **Access:** PDF and parseable TXT. There is no API.
- **Cadence:** daily, **only while DIRS is activated**.
- **Terms:** US government work, public domain.
- **Caveats:** not per carrier and not per place, and each report is "a snapshot in time".
- **Use:** crisis-only municipio figures and a crisis trigger. Outside disasters there is no official signal data, so community reports cover everything.

## Roads and emergencies

### NWS San Juan alerts
- **URL:** `https://api.weather.gov/alerts/active?area=PR`. Zone shapes come from `/zones/forecast/PRZ0xx`.
- **Data:** watches, warnings and advisories, with storm polygons or the 13 forecast zones, onset and expiry.
- **Access:** GeoJSON, CAP or ATOM. No key; a User-Agent is required.
- **Cadence:** near real time. Honour the cache headers.
- **Terms:** open data, "free to use for any purpose".
- **Caveats:**
  - A warning marks an area at risk, not a road flooded.
  - The API keeps only 7 days of history, so we archive alerts ourselves.
  - Spanish text in the payload is **UNVERIFIED**.
- **Use:**
  - hazard areas
  - the crisis trigger (hurricane or tropical storm warning)
  - time-sensitive notifications

### NWPS river gauges
- **URL:** `https://api.water.noaa.gov/nwps/v1/gauges` with a bounding box around PR.
- **Data:** 117 PR gauges with stage, forecast and flood category. About 30% of them have no thresholds.
- **Access:** JSON, no key. Observations about every 15 minutes.
- **Terms:** NOAA public data. The support level is **UNVERIFIED**.
- **Use:** depth context on nearby road items only. Gauges sit on rivers, not roads.

### DTOP / ACT closure releases
- **URL:** dtop.pr.gov/noticias and /comunicaciones.
- **Data:** closed and reopened roads by PR number, km range and municipio, in prose. Releases often have no precise time.
- **Access:** HTML releases and social posts. No 511 system or feed was found (**UNVERIFIED** that none exists).
- **Cadence:** ad hoc, heaviest after heavy rain.
- **Terms:** none stated. Don't reproduce text verbatim.
- **Use:** staff or the dashboard structure each release into segments labelled "Oficial · DTOP" with the release time and a source link; staff entries are recorded as transcribed by Biombo. Nothing is ever auto-scraped into "current".
- **Caveats:** reopenings are under-reported, so an official closure with no update for 72 h prompts nearby users to reconfirm.
- **Community fills:** municipal and rural roads, partial passability, and reopenings.

### DTOP state road geometry
- **URL:** `https://sige.pr.gov/server/rest/services/DTOP/dtop_carreteras/MapServer`
- **Data:** state road centerlines, dated February 2021.
- **Access:** ArcGIS REST, 1,000 records per request, EPSG:32161.
- **Caveats:**
  - Kilometre attributes are **UNVERIFIED**.
  - Municipal and rural roads are missing, so a second source is needed (PRODUCT.md open decision 8).
- **Use:** geometry only, for snapping reports and closures to named roads.

### FEMA IPAWS All-Hazards Feed
- **URL:** FEMA IPAWS "All-Hazards Information Feed" (the technology-developers page).
- **Data:** CAP 1.2 alerts from every authorized originator, including NMEAD and municipio Wireless Emergency Alerts.
- **Access:** free after registering on the IPAWS User Portal. Any further requirements are **UNVERIFIED**.
- **Terms:** no advertising use and no excessive polling.
- **Caveats:** how often PR originators use IPAWS is **UNVERIFIED**.
- **Status:** pending registration (PRODUCT.md open decision 3). It is the only automated route to non-weather official alerts.

### NMEAD, OMME, municipios
- **Data:** declarations, shelters, closures and derrumbes.
- **Access:** there is no feed. The NMEAD site's TLS certificate had expired at research time, and municipal information is posted only on social media.
- **Plan:** these agencies post directly through the authority dashboard. NMEAD plus one or two OMME are the pilot. Social platforms are never scraped.

## EV chargers

### NLR (formerly NREL) AFDC stations API
- **URL:** `https://developer.nlr.gov/api/alt-fuel-stations/v1.json?state=PR&fuel_type=ELEC&status=all&access=all&limit=all`
- **Data:** station locations, connectors, port counts, network and access hours.
- **Access:** JSON, CSV or GeoJSON with a free key, up to 1,000 requests per hour.
- **Cadence:** networks with automated feeds are re-confirmed daily.
- **Terms:** "may be used for any purpose". The data must not imply DOE or NLR endorsement.
- **Caveats:**
  - Only 25 PR stations are listed, 2 of them DC fast.
  - Velocicharge and Tesla are absent.
- **Use:** a **location seed only**. `status_code` is never shown and never feeds reliability; reliability comes from Biombo user reports alone.
- **Community fills:**
  - most chargers, added by users or owners and de-duplicated against AFDC ids
  - working status
  - waits
  - all reliability data

## Base data (not official status)

| Source | Use | Note |
|---|---|---|
| OpenStreetMap `amenity=fuel` | Initial station directory | ODbL share-alike review needed. PR completeness **UNVERIFIED**. |
| OpenStreetMap roads | Municipal and rural road geometry (proposed) | Pending PRODUCT.md open decision 8. |
| Barrio/sector gazetteer | Turns LUMA and AAA sector names into shapes | To be built from Census barrios and LUMA feeders (PRODUCT.md open decision 6). |

## Link-out only (not ingested)

- **PREPS** (preps.pr.gov): a link in crisis mode while it is active.
