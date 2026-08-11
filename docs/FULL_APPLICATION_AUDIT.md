# Geo Field — Full Application Audit

**Date:** 2026-08-11  
**Stack:** Qt 6.7 / C++17 / QML / Android  
**Scope:** Codebase inspection (no assumption that “it builds” means “it works”)

---

## P0 — Blocking / Crash / Data loss

| ID | Issue | Location | Status |
|----|--------|----------|--------|
| P0-1 | Main UI fails to load on Android (“UI Load Failed” / limited mode) | `src/main.cpp` load path + QML packaging | **FIXING** — embedded QML + `loadData` + `QQmlComponent`; success if `g_createdRoot` or `rootObjects` |
| P0-2 | `QQmlApplicationEngine::errors()` does not exist (compile break) | `main.cpp` | **FIXED** — use `QQmlComponent::errors()` + `warnings` signal |
| P0-3 | `QString::toUpperCase` invalid (compile break) | `main.cpp` | **FIXED** — `toUpper()` |
| P0-4 | Job points not persisted immediately | `ProjectManager::addPoint` | **FIXED** — autosave after add/delete |
| P0-5 | Active job lost on restart | `ProjectManager` ctor | **FIXED** — `loadActiveJob()` via QSettings pointer |
| P0-6 | Android Back exits app / loses navigation | Minimal QML | **OPEN** — needs Keys.onBack + stack (partial in fuller UI) |
| P0-7 | `IMapProvider` / `IConnection` / `IGnssReceiver` QObject without .cpp | moc linker | **FIXED** — out-of-line ctors in .cpp |

---

## P1 — Major functionality broken / incomplete

| ID | Issue | Notes |
|----|--------|-------|
| P1-1 | Bluetooth “unavailable” false negative | Runtime permissions implemented; needs physical device validation |
| P1-2 | BLE profiles not fully wired to Connect UI | Backend exists (`BleProfile`, `ProfileStore`); minimal UI lacks profile picker |
| P1-3 | NTRIP UI incomplete in minimal UI | `NtripClient` backend present; no full mountpoint UI in current embedded QML |
| P1-4 | Map is placeholder | `MapEngine` + MBTiles reader exist; tile blit to Canvas incomplete |
| P1-5 | OEM adapters not implemented | By design (U4 research only); Generic NMEA only |
| P1-6 | Total Station limited | `TotalStationDevice` stub; not field-validated |
| P1-7 | Geoid models require external grid files | Engine exists; no bundled EGM data (correct — licensing) |
| P1-8 | Survey `position` QML uses map keys | `ellipsoidalHeight` preferred; altitude may be missing |

---

## P2 — Important malfunctions

| ID | Issue |
|----|--------|
| P2-1 | Double packaging QML (`qt_add_qml_module` + `qt_add_resources`) may confuse paths |
| P2-2 | No USB Host implementation — must show NOT_IMPLEMENTED |
| P2-3 | Stakeout UI minimal — backend `StakeoutEngine` not fully exposed in UI |
| P2-4 | COGO incomplete in minimal UI |
| P2-5 | License trial/activate UI present; offline crypto strength not audited |
| P2-6 | No automated UI tests on device |
| P2-7 | Diagnostic states not shown on home strip |

---

## P3 — Minor / cleanup

| ID | Issue |
|----|--------|
| P3-1 | Backup QML files in tree (`main_full_backup.qml`) |
| P3-2 | Version mismatch manifest 1.3.0 vs CMake 1.3.1 |
| P3-3 | Inline `component {}` avoided in minimal UI (Qt version sensitivity) |
| P3-4 | Docs partially outdated vs code |

---

## Architecture summary (working layers)

```
QML UI (embedded + resources/qml/main.qml)
  → context properties (GnssManager, ProjectManager, …)
  → IGnssReceiver / GenericGnssReceiver
  → GnssManager
  → IConnection (Serial / Bluetooth / BLE)
  → NmeaParser / NtripClient / RtcmStats
  → ProjectManager (.gfp JSON + QSettings active job)
  → GeoidEngine / MapEngine (partial)
```

**No fake FIXED:** solution type comes from NMEA/parser only.

---

## Persistence

| Data | Storage |
|------|---------|
| Jobs / points | `Documents/GeoField/Projects/*.gfp` JSON |
| Active job name | QSettings `GeoField/Field/activeJob` |
| BLE profiles | ProfileStore (project conventions) |
| License | LicenseManager (hardware-bound) |

---

## Android

| Item | State |
|------|--------|
| Manifest BT permissions | Present (legacy + 12+) |
| INTERNET | Present (NTRIP) |
| UI packaging | **Critical path — embedded QML** |
| Back button | Partial |
| Lifecycle save | `aboutToQuit` → `saveProject` |

---

## Recommended fix order (executed / next)

1. **P0-1** Stabilize UI load (`loadData` + component create + `g_createdRoot`) — this commit  
2. **P0-6** Android Back on all pages  
3. **P1** Restore full Connect/NTRIP UI on top of stable shell  
4. Physical GNSS validation (U6.2 states)  
5. Map tile rendering (M4)

---

## Explicit non-goals of this audit pass

- No OEM SDK integration  
- No fake satellite imagery  
- No claim of universal receiver support without hardware tests  
