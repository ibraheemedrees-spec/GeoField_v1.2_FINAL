# Geo Field v1.2 – Complete Edition

**نسخة كاملة لكل الكنترولرز الحديثة**  
Android + Windows 10/11

## Supported controllers / devices

- Any Android rugged tablet / data collector
- Windows 10/11 field tablets and PCs
- Controllers that run full Windows or Android

**Not supported:** classic Windows Mobile 6.x (platform discontinued – see docs/FINAL_STATUS.md)

## All features included

- Offline licensing (24h trial + Hardware ID)
- Projects & points
- GNSS NMEA
- Coordinate projection + Localization
- Stakeout
- COGO
- Roads centerline
- Surface area/volume estimate
- CSV + DXF export
- Points map
- Total Station serial + basic measure parse
- NTRIP settings
- Arabic translation starter

## Build

```bash
mkdir build && cd build
cmake .. -DCMAKE_PREFIX_PATH=/path/to/Qt6
cmake --build .
```

Qt 6.5+ required (Core, Gui, Qml, Quick, QuickControls2, SerialPort, Positioning, Network, Sql).

## Commercial checklist

1. Change SECRET_SALT in src/licensing/LicenseKey.cpp
2. Set projection central meridian for your region
3. Keep tools/LicenseGenerator private

This is the **complete single codebase** for all modern field controllers.
