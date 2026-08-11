# Geo Field – GNSS Architecture (Phase 1–6)

## Principle
Universal Core + Standard Protocols (NMEA/RTCM/NTRIP) + Manufacturer Adapters + Capability Detection.

**No fake FIXED, no fake satellites, no invented manufacturer commands.**

## Structure added
```
src/gnss/
  core/           GnssPosition, SolutionType, SatelliteInfo
  capabilities/   ReceiverCapabilities
  receiver/       DeviceRegistry
  protocols/nmea/ NmeaParser (GGA,GSA,GST,GSV,RMC,VTG,GNS)
  GnssManager     Facade for UI + connection + quality gates
```

## Supported now
| Area | Status |
|------|--------|
| NMEA parse | GGA GSA GST GSV RMC VTG GNS |
| Connection | Serial (Bluetooth/USB use same serial path when OS exposes port) |
| Device registry | Catalog of manufacturers/models with capability levels |
| Capability levels | Generic / Standard (Emlid NMEA) – Advanced requires SDK |
| Quality control | min sats, max PDOP, max H accuracy, max correction age |
| Antenna height | Applied in correctedElevation() |

## Not implemented yet (honest)
- Full RTCM message decoder (manager stub next phase)
- Live NTRIP client TCP state machine
- BLE scan UI with Android permissions
- Manufacturer proprietary command adapters (Trimble/Topcon/Leica/CHC…)
- Tilt compensation
- Geoid file engine
- Radio native frequency programming per OEM

## Manufacturer rule
| Level | Meaning |
|-------|---------|
| Generic | NMEA in only |
| Standard | NMEA + documented open paths (e.g. NTRIP on device) |
| Advanced | Official SDK / documented protocol |
| Full | Full OEM integration verified |

Listing a model in DeviceRegistry does **not** mean full control—only profile selection + NMEA path unless an adapter is implemented.

## Phase 7–10 completed

### NTRIP Client (`src/gnss/ntrip/NtripClient`)
- TCP connect to caster
- Basic auth
- Mountpoint stream
- Source table (STR; lines)
- GGA send interval
- Auto-reconnect
- Bytes / rate / correction age
- **Does not** log passwords

### RTCM Stats (`src/gnss/protocols/rtcm/RtcmStats`)
- Detects RTCM3 frames (`0xD3`)
- Frame count, message type id from header
- Data rate, correction age
- **Not** a full ephemeris/MSM decoder

### Diagnostics (`src/gnss/diagnostics/DiagnosticManager`)
- Ring log (200 lines)
- NMEA rate, RTCM B/s, reconnect count

### Profile Store (`src/gnss/profiles/ProfileStore`)
- Save/load JSON under Documents/GeoField/Profiles/{receiver,ntrip,radio}

### Still deferred
- Forward RTCM bytes into serial receiver port (needs active GNSS serial write path)
- Full MSM/ephemeris parse
- BLE device scanner UI + Android permissions
- Manufacturer proprietary adapters

## Phase 11 progress

### RTCM → Receiver
- `GnssManager::writeRaw()` writes bytes to open serial port
- NTRIP `rtcmDataReceived` connected to `writeRaw` in main.cpp
- GGA built from live position and sent to NTRIP client

### Profiles
- `toProfileMap` / `loadProfileMap` on GnssManager
- Connect screen: Save / Load via ProfileStore

### Base / Rover
- BaseManager: Known Point / method / start-stop (workflow state, not OEM radio programming)
- RoverManager: mode + correction source + start-stop

### Honest limits
- Base start does not transmit proprietary radio corrections by itself
- Rover start does not change receiver firmware mode without adapter
- RTCM forward only works when serial receiver port is open
