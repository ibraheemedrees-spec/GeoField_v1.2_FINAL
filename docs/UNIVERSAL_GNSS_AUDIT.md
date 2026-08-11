# Geo Field — Universal GNSS Architecture Audit

**Date:** 2026-08-11  
**Project version:** 1.3.1  
**Framework:** Qt 6.7 / C++17 / QML — **NOT Flutter**

---

## CURRENT ARCHITECTURE

```
Geo Field (Qt App)
├── UI: resources/qml/main.qml (single file, Magnet-style menu)
├── core/          ProjectManager, CoordinateSystem, Localization, Exporter
├── devices/       IDevice, GnssDevice (Serial+NMEA), TotalStationDevice,
│                  NtripSettings (legacy config), RadioSettings, ControllerProfile
├── gnss/          ← newer modular layer
│   ├── core/           GnssPosition, SolutionType, SatelliteInfo
│   ├── capabilities/   ReceiverCapabilities (struct)
│   ├── receiver/       DeviceRegistry
│   ├── protocols/nmea/ NmeaParser (GGA/GSA/GST/GSV/RMC/VTG/GNS)
│   ├── protocols/rtcm/ RtcmStats (frame detect 0xD3, no full decode)
│   ├── ntrip/          NtripClient (TCP, auth, source table, reconnect)
│   ├── base/rover/     workflow state managers
│   ├── profiles/       ProfileStore (JSON)
│   ├── diagnostics/    DiagnosticManager
│   └── GnssManager     facade: Serial connect + parse + QC + writeRaw
├── survey/        StakeoutEngine, CogoEngine, SurfaceEngine, RoadsEngine
└── licensing/     HardwareId, LicenseKey, LicenseManager
```

### Connection reality
| Type | Status |
|------|--------|
| Serial (QSerialPort) | **Implemented** (GnssDevice + GnssManager) |
| TCP (NTRIP only) | **Implemented** (NtripClient) |
| Bluetooth Classic | Named in profiles only — **no QBluetooth code** |
| BLE | **Not implemented** |
| USB Host | Only as serial port name if OS exposes it |
| UDP | **Not implemented** |

### Protocol reality
| Protocol | Status |
|----------|--------|
| NMEA | Real parser, no fabricated fixes |
| RTCM 3 | Transport stats + forward to serial; **not** full MSM decoder |
| NTRIP | Real TCP client |
| OEM commands | **None** — Generic only |

### Android native
- `android/AndroidManifest.xml` only
- No Kotlin/Java Bluetooth/USB plugins
- No Platform Channels (N/A — pure Qt)

### Dual path debt
- `GnssDevice` (legacy) + `GnssManager` (new) both exist
- UI prefers GnssManager after phase A/B

---

## TARGET ARCHITECTURE

```
                    GEO FIELD (Qt)
                         │
                 GNSS CORE ENGINE
                         │
                HARDWARE ABSTRACTION
                         │
             ┌───────────┴───────────┐
             │                       │
       STANDARD LAYER          OEM ADAPTER LAYER
             │                       │
      NMEA / RTCM / NTRIP      Optional adapters
             │                       │
     ConnectionManager         Trimble/Leica/...
     (Serial, BT, BLE,         only with real SDK
      USB, TCP, UDP)           or documented protocol
```

### Target interfaces (to implement)
1. `IGnssReceiver` — connect/disconnect/position/capabilities/sendCorrection
2. `IConnection` — Serial / Tcp / (future BT BLE USB)
3. `GenericGnssAdapter` : IGnssReceiver — NMEA path only
4. `ManufacturerAdapter` stubs with status enum (NOT_AVAILABLE … PRODUCTION_VERIFIED)
5. `MockGnssReceiver` — **#ifdef QT_DEBUG only**, never in Release
6. `GeoidEngine` — load model or explicit “not loaded”
7. Compatibility matrix driven by DeviceRegistry + capabilities

**Core modules that must never import OEM SDKs:**  
Project, Survey, Stakeout, COGO, Map, Reports, Coordinate, NMEA, RTCM, NTRIP, Generic adapter.

---

## GAP ANALYSIS

| Required | Existing | Gap |
|----------|----------|-----|
| GnssReceiver interface | Partial (GnssManager + IDevice) | Formalize single interface |
| GnssCapabilities | ReceiverCapabilities.h | Expand + drive UI hide/show |
| ConnectionManager | Serial only in managers | Abstract IConnection; add BT/BLE later |
| BLE Scanner | Missing | Qt Bluetooth + Android permissions |
| USB Host | Missing native | Serial alias when port appears |
| NMEA Engine | **Done** | Add ZDA if needed |
| RTCM Engine | Stats only | Keep honest; optional deeper parse later |
| NTRIP | **Done** | TLS optional later |
| GenericGnssAdapter | Logic inside GnssManager | Extract as adapter class |
| Base/Rover | Workflow state | Not OEM radio programming |
| Antenna | Height in manager | OK for standard layer |
| Geoid | Notice only | GeoidEngine + file load |
| OEM adapters | Registry catalog only | Research matrix; no fake commands |
| Mock receiver | Absent | Debug-only when needed |
| Total Station | Stub Serial | Protocol when documented |
| DEVICE_SDK_MATRIX.md | Missing | Create research doc |

---

## IMPLEMENTATION PLAN (priority)

### Phase U1 — Interface cleanup (no behavior change)
- Define `IGnssReceiver` + `IConnection`
- Wrap existing GnssManager as `GenericGnssAdapter`
- Deprecate UI use of GnssDevice (already mostly done)

### Phase U2 — Capabilities → UI
- Bind Configure/Connect visibility to `capabilitiesMap`
- Show “Not supported by this receiver” where false

### Phase U3 — Connection abstraction
- `SerialConnection` from current QSerialPort path
- `TcpConnection` reuse for NTRIP body stream
- Stubs: `BluetoothConnection`, `BleConnection` with clear NOT_IMPLEMENTED

### Phase U4 — Documentation matrix
- `OEM_SDK_MATRIX.md` with RESEARCH_REQUIRED for each brand
- No SDK binary download without official terms

### Phase U5 — GeoidEngine skeleton
- Interface + “file missing” path; no silent wrong orthometric height

### Phase U6 — BLE (when ready)
- Qt6 Bluetooth + Android BLUETOOTH_SCAN/CONNECT permissions
- Real scan only; no fake devices

### Phase U7 — OEM adapters
- Only when official Android SDK or verified protocol exists
- Status: IMPLEMENTATION_STARTED → DEVICE_TESTED

### Explicitly deferred
- Full RTCM ephemeris/MSM decoder (not required for forward-to-receiver)
- Fake FIXED / demo production mode (**forbidden**)
- Unofficial third-party SDK jars

---

## HARDWARE TESTING CHECKLIST (template)

For each physical receiver:
1. Discovery  2. Connection  3. Identification  4. NMEA  
5. Position  6. Satellites  7. Fix  8. RTCM in  
9. NTRIP  10. Base  11. Rover  12. Antenna  
13. Radio  14. Reconnect  15. Disconnect  16. Errors  
17. Survey point  18. Stakeout  19. Export  

Mark TESTED only after physical device verification.

---

## CONCLUSION

Geo Field already has a **working Standard Layer foundation** (NMEA + NTRIP + Serial + QC + Survey/Stake/COGO).

It is **not** SDK-dependent today (correct).

Next engineering work is **abstraction cleanup + capabilities-driven UI + honest connection stubs**, not a rewrite and not inventing OEM protocols.

---

## U1 + U2 Implementation (2026-08-11)

### Files created
- `src/gnss/receiver/IGnssReceiver.h` — abstract interface
- `src/gnss/receiver/GenericGnssReceiver.h/.cpp` — wraps GnssManager

### Files modified
- `src/gnss/capabilities/ReceiverCapabilities.h` — IMU/OEM/RawData flags
- `CMakeLists.txt` — GenericGnssReceiver.cpp
- `src/main.cpp` — `gnssReceiver` context property
- `resources/qml/main.qml` — `cap()` helper + capability-driven visibility

### Architecture
```
QML (gnssReceiver / gnssManager)
  → IGnssReceiver
    → GenericGnssReceiver
      → GnssManager (unchanged)
        → Serial + NmeaParser
NTRIP remains NtripClient (app-level)
```

### Current supported capabilities (Generic)
| Capability | Value |
|------------|-------|
| supportsSerial | true |
| supportsNMEA | true |
| supportsRTCM | true (forward) |
| supportsNTRIP | true (app TCP) |
| supportsTCP | true |
| supportsRover | true |
| supportsAntennaConfig | true |
| supportsRawData | true |
| supportsBluetooth | **false** |
| supportsBLE | **false** |
| supportsUSB | **false** |
| supportsRadio / InternalRadio | **false** |
| supportsIMU / Tilt | **false** |
| supportsOEMConfiguration | **false** |
| supportsBase (OEM tx) | **false** |

### Unsupported (UI shows «غير مدعوم لهذا الجهاز»)
- Bluetooth / BLE / USB Host
- Radio OEM programming
- IMU / Tilt
- OEM advanced configuration

### Tests (static / structural)
- QML brace balance checked
- No second NMEA/NTRIP/Serial implementation
- No fake FIXED path added
- Existing GnssManager API preserved for QML

### Build
Run GitHub Actions / local Qt 6.7 CMake after push.

### Next phase (do not start until approved)
**U3** — Connection abstraction stubs (SerialConnection extract + BT/BLE NOT_IMPLEMENTED)

---

## U3 Implementation — Connection Abstraction (2026-08-11)

### Files created
- `src/gnss/connection/IConnection.h`
- `src/gnss/connection/SerialConnection.h/.cpp`
- `src/gnss/connection/NotImplementedConnection.h` (BT/BLE/USB stubs)

### Files modified
- `src/gnss/GnssManager.h` — owns `SerialConnection*` instead of `QSerialPort*`
- `src/gnss/GnssManager.cpp` — connect/disconnect/write/data path via IConnection
- `CMakeLists.txt`

### Ownership
**Before:** GnssManager created and owned `QSerialPort`.  
**After:** GnssManager creates and owns `SerialConnection`, which owns `QSerialPort`.

### Data path (unchanged semantics)
```
QSerialPort readyRead
  → SerialConnection::onReadyRead
  → dataReceived(QByteArray)
  → GnssManager::onConnectionData
  → NmeaParser::feed
```

### RTCM forward
```
NtripClient::rtcmDataReceived
  → GnssManager::writeRaw
  → SerialConnection::write
  → QSerialPort::write
```

### Signals
| Old | New |
|-----|-----|
| QSerialPort::readyRead | SerialConnection::dataReceived |
| QSerialPort::errorOccurred | SerialConnection::errorOccurred + state Error |
| GnssManager connectionChanged | Still emitted; state mirrored from SerialConnection |

### BT/BLE/USB
NOT_IMPLEMENTED — no Qt Bluetooth dependency added.

### Legacy
`devices/GnssDevice` still has its own QSerialPort (fallback UI path). Primary path is GnssManager → SerialConnection.

### Next (not started)
U4 OEM_SDK_MATRIX documentation research

## U4
See **docs/OEM_SDK_MATRIX.md** (research only; no SDK integration).

## U5 GeoidEngine
See docs/GEOID_ENGINE.md. Classes: IGeoidModel, NullGeoidModel, EgmsStubModel, GridGeoidModel, GeoidEngine.

## U6 Bluetooth/BLE
See docs/BLUETOOTH_BLE.md. Transports: SerialConnection, BluetoothConnection, BleConnection.

## U6.1
BleProfile + TransportDiagnostics + HARDWARE_VALIDATION.md. No OEM.

## U6.2
Strict GNSS_VERIFIED / RTK_VERIFIED / manual FIELD_TESTED. tests/test_validation_states.cpp
