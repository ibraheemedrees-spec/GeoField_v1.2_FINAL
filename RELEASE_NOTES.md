# Geo Field v1.3.0 – Release candidate

## Ready for field trial
- Magnet Field style home menu
- Job / Survey / Stake / Map / Calculate / Connect / Setup
- Modular GNSS core (NMEA parser, solution types, quality gates)
- Device registry with capability levels (Generic/Standard)
- Live NTRIP client (TCP, auth, mountpoint, source table, auto-reconnect)
- RTCM3 frame stats + forward to open serial port
- Receiver / NTRIP / Radio profile store (local JSON)
- Base / Rover workflow state
- GNSS Status screen + Quick Connect
- Offline license: Hardware ID + trial + activation code

## Security
- No password logging in diagnostics
- Profile names sanitized (path traversal blocked)
- NTRIP host/port/mount validation
- FIXED only from NMEA quality field (never invented)
- License keys not written to debug logs

## Known limitations
- Bluetooth/BLE scan UI needs Android permissions + Qt Bluetooth (serial path works when OS exposes port name)
- Manufacturer proprietary command sets require official SDK adapters (not claimed as Full)
- Base start does not program OEM radios by itself
- Geoid file engine not included in this build
- Windows Mobile lite not in this package

## How to test
1. Create Job
2. Connect → set port/baud → Connect
3. Setup → NTRIP host/mount/user → NTRIP ON
4. Tap status bar → GNSS Status / Quick Connect
5. Survey → Store Point (respects quality gates when using gnssManager)
6. License → Hardware ID → activate with issued code
