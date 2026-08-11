# Phases A–C complete (and continuation)

## A — Unify GNSS path
- UI prefers `gnssManager` for connection, status, antenna, position
- `gnssDevice` remains as fallback only
- NTRIP UI uses `ntripClient` (live TCP)

## B — Survey quality gates
- `livePos()` / `liveElev()` helpers
- Store Point blocked when `gnssManager.isConnected && !canStorePoint()`
- Quality FAIL message on Survey screen
- Status strip shows real NTRIP when connected

## C — COGO
- Inverse, Intersection sample, Area sample, Offset call `cogoEngine`
- Result panel on Calculate page

## Honest remaining gaps
- Full Total Station protocol: architecture only
- Manufacturer adapters: Generic NMEA only
- Geoid files: not shipped
- BLE scan: not implemented
- Advanced CAD/Roads: engines minimal
