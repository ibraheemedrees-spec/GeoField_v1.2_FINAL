# Geo Field — OEM SDK / Protocol Research Matrix (U4)

**Phase:** U4 — RESEARCH AND DOCUMENTATION ONLY  
**Date:** 2026-08-11  
**App stack:** Qt 6.7 / C++17 / QML / Android  
**Rule:** No SDK binaries, no OEM commands, no runtime changes in this phase.

Status vocabulary used below:  
`NOT_FOUND` · `RESEARCH_REQUIRED` · `OFFICIAL_DOCUMENTATION` · `OFFICIAL_SDK` · `OFFICIAL_PROTOCOL` · `SDK_RESTRICTED` · `SDK_REQUIRES_PARTNERSHIP` · `IMPLEMENTATION_POSSIBLE` · `NOT_VERIFIED`

Compatibility levels (claims only after physical test for Level 5):  
**L1 Generic** NMEA · **L2 RTK** NMEA+RTCM+NTRIP · **L3 Device control** OEM protocol/SDK · **L4 Advanced** radio/IMU/tilt · **L5 Full verified** implemented + hardware-tested

---

## 1. Executive Summary

| Finding | Detail |
|---------|--------|
| Universal OEM SDK | **Does not exist** |
| Best official Android SDK path | **Trimble** TPSDK / TMM API (partner + developer registration) |
| Best *open standard* third-party path | **Emlid** — documented NMEA + RTCM + Bluetooth SPP; no mandatory closed SDK for basic RTK |
| Partner-gated ecosystems | Trimble, Leica (GPN), Topcon/Sokkia (commercial field software focus) |
| Chinese OEM brands (CHCNAV, Hi-Target, South, ComNav, Stonex) | Strong **GENERIC COMPATIBILITY** via NMEA/RTCM/NTRIP; public Android *survey apps* exist; **public full control SDKs often NOT_FOUND** — contact manufacturer |
| Geo Field today | Already covers **L1–L2** via Generic layer without any OEM dependency |

**Recommendation:** Keep Generic L1–L2 as production default. First *optional* OEM adapter candidate after legal clearance: **Emlid** (documented BT/NMEA) or **Trimble TMM API** (if partner access granted). Never claim L5 from documentation alone.

---

## 2. Manufacturer Matrix (summary)

| Manufacturer | Official SDK status | Android | Generic NMEA/RTCM | Base/Rover via std | OEM config public | Priority |
|--------------|---------------------|---------|-------------------|--------------------|-------------------|----------|
| **Emlid** | OFFICIAL_DOCUMENTATION (integration guides; NMEA/RTCM public) | Yes (BT SPP) | **Yes — strong** | Via Emlid Flow + NTRIP/RTCM | Limited (app/web) | **HIGH** |
| **Trimble** | OFFICIAL_SDK (TPSDK, TMM API) | Yes (Java/C#) | Possible on many models | Yes via SDK/TMM | Yes (SDK) | **HIGH** |
| **Leica** | SDK_REQUIRES_PARTNERSHIP (GPN); Zeno Connect + WebSocket | Zeno Connect Android | Possible | Via Zeno/RTK | Partner | **HIGH** |
| **Topcon / Sokkia** | RESEARCH_REQUIRED / commercial MAGNET ecosystem | Field apps exist | Likely on many models | Typical RTK hardware | Partner/OEM | **MEDIUM** |
| **CHCNAV** | RESEARCH_REQUIRED (apps: LandStar/MapCloud; no public full SDK found) | Controllers/apps | **Likely yes** | Hardware RTK | Contact OEM | **MEDIUM** |
| **Stonex** | NOT_FOUND public full SDK; Cube-a / Cube-connector | Yes | **Likely yes** (BT mock location pattern) | Hardware RTK | Contact OEM | **MEDIUM** |
| **ComNav** | OFFICIAL_DOCUMENTATION (OEM board command manuals — NMEA/RTCM) | Module-oriented | **Yes** | Board-level | Commands in manuals (verify license) | **MEDIUM** |
| **Hi-Target** | RESEARCH_REQUIRED | Apps exist | Likely yes | Hardware RTK | Contact OEM | **MEDIUM** |
| **South** | RESEARCH_REQUIRED | Apps exist | Likely yes | Hardware RTK | Contact OEM | **LOW–MEDIUM** |

---

## 3. Model / family notes (representative — NOT exhaustive)

| Brand | Example families | Notes |
|-------|------------------|-------|
| Trimble | R12 / R12i / R10 / R580 / Catalyst DA2 | TPSDK / TMM; Bluetooth common for Catalyst class |
| Leica | GS18 / GS16 / Zeno FLX100 / GG04 | Zeno Connect for GIS antennas; survey receivers often partner |
| Topcon/Sokkia | HiPer VR / GRX3 / Hiper | MAGNET Field is product software; public receiver SDK sparse |
| Emlid | Reach RS2+ / RS3 / RX / RS4 | **Documented** NMEA streaming, RTCM3, NTRIP, BT |
| CHCNAV | i83 / i89 / i90 / i73 / iBase | LandStar/MapCloud; BT/Wi-Fi/NTRIP on hardware |
| Stonex | S900 / S980 / S590 | Cube-connector for Android BT → mock location / stream |
| ComNav | T30 / T300 / K8 boards | OEM reference manuals with NMEA/RTCM logs |
| Hi-Target / South | V90 / Galaxy class | Market RTK; public SDK often not published |

If model-specific SDK binding is unclear: **UNKNOWN / REQUIRES VERIFICATION**.

---

## 4. Official SDK / portal sources (verified links as of research)

### Trimble
- Developer / Catalyst: https://developer.trimblegeospatial.com/  
- TPSDK intro: https://developer.trimble.com/docs/precision/  
- Technology Partner Program: https://geospatial.trimble.com/en/technology-partner-program  
- **Status:** `OFFICIAL_SDK` · Android Java + C# · Windows · **SDK_REQUIRES_PARTNERSHIP / registration (Trimble ID)**  
- Integration paths: TMM WebSocket/REST (simpler position) · TPSDK full control  
- Qt path: JNI to Java SDK **or** consume TMM localhost WebSocket from Qt Network (technically realistic)

### Leica Geosystems
- Partner Network (GPN): https://leica-geosystems.com/about-us/partners/development-partner  
- Zeno Connect (Android/iOS/Windows) — NMEA / location injection / WebSocket API (docs via myWorld GPN)  
- **Status:** `SDK_REQUIRES_PARTNERSHIP` · Zeno path `OFFICIAL_DOCUMENTATION` for GIS antennas  
- Survey-grade GS receivers: contact GPN — do not assume public free SDK

### Emlid
- Docs: https://docs.emlid.com/  
- NMEA / RTCM3 specs per model; Android BT SPP NMEA; corrections protocols documented  
- **Status:** `OFFICIAL_DOCUMENTATION` · **GENERIC COMPATIBILITY POSSIBLE** (primary path for Geo Field)  
- No requirement for proprietary closed SDK for L1–L2 position stream

### Topcon / Sokkia
- MAGNET product ecosystem; MDC REST for data conversion (not receiver control)  
- **Status:** `RESEARCH_REQUIRED` for public GNSS control SDK · Field software is commercial product  
- Generic NMEA on many units: **NOT_VERIFIED** per model — test required

### CHCNAV
- Product site / support: https://geospatial.chcnav.com/ · support.chcnav.com  
- LandStar / MapCloud Android apps; hardware supports NTRIP/RTCM  
- **Status:** `RESEARCH_REQUIRED` / public full control SDK `NOT_FOUND` in open web research  
- **GENERIC COMPATIBILITY POSSIBLE** if unit outputs NMEA (device test required)

### Stonex
- Cube-a / Cube-connector (Android BT bridge)  
- **Status:** Public *full* OEM SDK `NOT_FOUND` · connector pattern implies standard BT stream  
- **GENERIC COMPATIBILITY POSSIBLE** after device verification

### ComNav
- OEM board reference manuals document NMEA/RTCM logs and commands  
- **Status:** `OFFICIAL_DOCUMENTATION` (board-level) · redistribution/licensing of full manuals: **UNKNOWN — VERIFY WITH MANUFACTURER**  
- Useful for module integrators; survey shell still benefits from Generic NMEA

### Hi-Target / South
- **Status:** `RESEARCH_REQUIRED` · market Android survey apps exist · public SDK often not published  
- Assume Generic until official contact confirms

---

## 5–6. Standard vs OEM capability classification

| Capability | Class | Geo Field today |
|------------|-------|-----------------|
| NMEA position/status | **STANDARD** | Implemented |
| RTCM transport / forward | **STANDARD** | Implemented (stats + forward) |
| NTRIP client | **STANDARD** | Implemented |
| Serial / TCP transport | **STANDARD** | Serial + NTRIP TCP |
| Bluetooth transport | **STANDARD transport** | NOT_IMPLEMENTED (U6) |
| BLE | **STANDARD transport** | NOT_IMPLEMENTED (U6) |
| Internal radio config | **OEM** | Not implemented |
| Tilt / IMU calibration | **OEM** | Not implemented |
| Constellation/frequency OEM menus | **OEM** | Not implemented |
| Firmware update | **OEM** | Not implemented |
| Manufacturer binary commands | **OEM** | Forbidden without official source |

---

## 7–9. Android / Qt feasibility (documentation only)

| Path | Feasibility for Geo Field |
|------|---------------------------|
| Pure Qt Serial + NMEA | **Already in production path** |
| Qt Network TCP NTRIP | **Already in production path** |
| Qt Bluetooth (Classic/BLE) | Planned U6 — standard Qt modules |
| Trimble TMM WebSocket on localhost | Qt can consume JSON/WS without embedding TPSDK |
| Trimble/Leica Java SDK | Requires Android JNI layer + packaging; partnership |
| Native .so C/C++ OEM libs | Possible if manufacturer ships NDK libs + license allows |
| Unofficial reverse-engineered libs | **Rejected for production** |

Survey/Stakeout/COGO/Job **must never** import OEM classes — only `IGnssReceiver` adapters.

---

## 10. Licensing / redistribution notes

| Source | Notes |
|--------|-------|
| Trimble TPSDK / TMM | Developer/partner registration; commercial terms; **do not commit SDK binaries to public repo without written redistribution rights** |
| Leica GPN | Partner agreement typical |
| Emlid public docs | Integration via standards; respect product EULA for firmware/app |
| ComNav OEM manuals | May be restricted; verify before embedding command tables in product |
| Unknown SDKs | **UNKNOWN — VERIFY WITH MANUFACTURER** |

---

## 11. Recommended adapter strategy

```text
Geo Field UI / Survey / Stake / COGO
        ↓
   IGnssReceiver
        ↓
 ┌──────┴──────┐
 GenericGnssReceiver     Optional ManufacturerAdapter
 (always available)      (only after official access + legal OK)
        ↓                         ↓
 SerialConnection          Official SDK / Protocol
 NtripClient               (Trimble/Leica/Emlid-specific…)
```

1. Ship Generic L2 for all brands that speak NMEA/RTCM.  
2. Add manufacturer adapter only when: official SDK **or** official protocol + redistribution rights + device test plan.  
3. Capability flags gate UI (already U2).

---

## 12. Generic fallback strategy

**Lack of OEM SDK ≠ incompatible.**

If the receiver can:
- Stream NMEA over Serial/BT/TCP, and/or  
- Accept RTCM (NTRIP or radio bridge),

then Geo Field **GENERIC COMPATIBILITY POSSIBLE** at L1–L2 without any OEM code.

OEM adapters only unlock L3–L4 features (radio programming, tilt, deep config).

---

## 13. Unknowns (require manufacturer contact)

- Exact redistribution terms for TPSDK / GPN packages  
- Whether Topcon publishes a public GNSS control SDK for third-party Android controllers  
- CHCNAV / Hi-Target / South / Stonex partner SDK programs  
- Per-model NMEA message sets and quality fields (must be device-tested)  
- Total Station remote protocols per brand (separate from GNSS)

---

## 14. Risks

| Risk | Mitigation |
|------|------------|
| Claiming “supports Brand X fully” from marketing pages | Use status enums; only L5 after hardware test |
| Shipping SDK without license | Never add binaries until legal sign-off |
| Reverse-engineered protocols | Forbidden in production |
| OEM SDK breaks Qt packaging | Isolate in Android JNI module; optional build flag |
| User expects radio programming on Generic | UI already shows «غير مدعوم» for unsupported caps |

---

## 15. Priority ranking for future OEM work

### HIGH
1. **Emlid** — strongest open documentation for BT/NMEA/RTCM; lowest legal friction for L2; optional advanced later  
2. **Trimble** — official Android SDK; market weight; needs partnership  
3. **Leica** — GPN + Zeno WebSocket path; partnership  

### MEDIUM
4. **ComNav** — board manuals useful for modules  
5. **CHCNAV / Stonex** — volume in regional markets; generic first, OEM if partner SDK appears  
6. **Topcon/Sokkia** — important installed base; SDK access unclear  

### LOW (until contact)
7. **Hi-Target / South** — generic NMEA path first  

---

## Highest-priority manufacturer for *first optional adapter*
**Emlid** (documented standard streams) — still **not implemented in U4**.  
Alternative if partnership available: **Trimble TMM API** (position via localhost WS without full TPSDK).

## Recommended first step after U4 (future phase only)
1. Device lab tests: Emlid Reach + Generic serial/BT NMEA + NTRIP → confirm L2.  
2. Contact Trimble/Leica only if commercial need for L3–L4.  
3. Do **not** implement OEM adapter until written source + license + test device exist.

---

*End of U4. No code or runtime behavior was changed except creation of this document.*
