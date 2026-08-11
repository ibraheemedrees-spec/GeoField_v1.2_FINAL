# Settings Architecture

## Categories
CONNECTION · GNSS · CORRECTIONS · ROVER · BASE · RADIO · ANTENNA · COORDS · GEOID · SURVEY · STAKEOUT · UNITS · PROFILES · DIAG

## Functional status

| Area | Status |
|------|--------|
| Serial / BT / BLE connect | **IMPLEMENTED** (U3/U6) |
| NTRIP connect + RTCM forward | **IMPLEMENTED** |
| Antenna height | **IMPLEMENTED** (GnssManager) |
| Rover QC gates | **IMPLEMENTED** |
| Geoid engine | **IMPLEMENTED** (custom grid; EGM stub) |
| Device/BLE profiles | **IMPLEMENTED** (ProfileStore) |
| Diagnostics states | **IMPLEMENTED** (U6.2) |
| Constellation/frequency OEM | **RECEIVER_CONTROLLED / NOT_IMPLEMENTED** |
| Proprietary radio TX | **NOT_SUPPORTED** (Generic) |
| Full CRS / site cal UI | **Partial / NOT_IMPLEMENTED** |
| Multi-unit system | **NOT_IMPLEMENTED** |

## Capability rule
UI must not expose fake controls. Prefer hide or explicit:
- غير مدعوم لهذا الجهاز
- NOT_IMPLEMENTED
- RECEIVER_CONTROLLED
