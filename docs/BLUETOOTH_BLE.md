# Bluetooth / BLE (U6)

## Architecture
```
BluetoothScanner (discovery)
BluetoothConnection (Classic SPP)
BleConnection (configurable UUIDs)
    ↓
IConnection
    ↓
GenericGnssReceiver / GnssManager
    ↓
NmeaParser  |  writeRaw ← NTRIP RTCM
```

## Classic
- QBluetoothSocket + Serial Port Profile
- `gnssManager.connectionType = "Bluetooth"`
- `portName` = device address

## BLE
- QLowEnergyController
- Requires Service / RX / TX UUIDs for data path (no hardcoded OEM UUIDs)
- Discovery lists devices; UUID selection is profile/config responsibility

## Android permissions (Manifest)
BLUETOOTH, BLUETOOTH_ADMIN, BLUETOOTH_CONNECT, BLUETOOTH_SCAN, LOCATION (legacy scan)

## NTRIP → RTCM → BT
Same `GnssManager::writeRaw` → `IConnection::write` path as Serial.

## Limitations
- NOT PHYSICALLY TESTED in CI environment
- BLE without UUIDs will not stream data
- Pairing UX is system-level
- No OEM protocols

## Serial regression
SerialConnection unchanged; default connectionType remains Serial.

## U6.1 Hardening

### BLE profile (ProfileStore kind `ble`)
Fields: name, deviceAddress, deviceName, serviceUuid, rxUuid, txUuid, notifyMode, writeMode, autoReconnect, timeoutSec

### Compatibility states
DISCOVERED → CONNECTED → DATA_DETECTED → GNSS_VERIFIED → RTK_VERIFIED → FIELD_TESTED

### Diagnostics
`transportDiagnostics.statusSummary` — bytes, NMEA rate, PHYSICAL TEST REQUIRED

### Physical testing
See docs/HARDWARE_VALIDATION.md — **NOT PHYSICALLY TESTED** in CI.

## U6.2 validation hardening
GNSS_VERIFIED needs multiple valid GGA sentences, not one `$G` fragment.
RTK_VERIFIED needs FLOAT/FIXED from receiver quality, not RTCM TX counters.
FIELD_TESTED is manual only.
