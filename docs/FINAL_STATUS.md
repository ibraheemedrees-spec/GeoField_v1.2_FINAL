# Geo Field – Final Status (v1.2)

## Project Scope Completed

This repository contains a **complete, compilable foundation** for a professional field surveying application targeting Android + Windows.

### Implemented and usable

1. **Licensing**
   - 24-hour trial
   - Offline activation bound to Hardware ID
   - License Generator tool for the seller

2. **Data**
   - Projects, points, codes
   - Save/load JSON project files
   - CSV + DXF export

3. **GNSS**
   - Serial NMEA (GGA, GST)
   - Live quality indicators (fix, sats, HRMS)

4. **Coordinates**
   - Transverse Mercator / UTM-style projection
   - Localization (2D Helmert site calibration)
   - Auto-apply localization on store

5. **Survey tools**
   - Stakeout guidance (ΔN, ΔE, ΔZ, distance, azimuth)
   - COGO (distance, azimuth, offset, intersection, area)
   - Roads centerline (stationing, offset, nearest station)
   - Surface area / simple volume estimate
   - Points map (Canvas)

6. **Devices**
   - GNSS connection UI
   - Total Station serial connection + basic HA/VA/SD line parser
   - NTRIP settings storage

7. **UI**
   - Multi-page field-oriented dark interface
   - Arabic translation starter file

### Explicitly NOT finished (requires hardware + longer development)

- Full brand-specific Total Station command protocols (Sokkia / Topcon / Leica complete)
- Live NTRIP client that streams corrections into the receiver
- Online map tiles / GIS background
- Full TIN generation + contours
- Windows Mobile port (platform largely obsolete)
- Complete multi-language packaging
- Production-grade obfuscation / anti-crack hardening

These items are normal phase-2 work after field testing the foundation.

## How to treat this release

- Use it as the **base product** for office testing and further feature work.
- Connect real GNSS first; validate projection + localization + stakeout.
- Extend Total Station drivers per instrument brand as needed.
- Change SECRET_SALT and signing before any commercial distribution.

## Version

**Geo Field v1.2 – Foundation Complete**
