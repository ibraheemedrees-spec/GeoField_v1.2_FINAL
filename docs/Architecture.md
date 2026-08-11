# Geo Field - Architecture

## High-Level Architecture

```
┌─────────────────────────────────────────────┐
│              Presentation (QML)             │
│  Map | Stakeout | Survey | Settings | ...   │
└────────────────────┬────────────────────────┘
                     │
┌────────────────────▼────────────────────────┐
│            Application Layer                │
│  ProjectManager | SurveyEngine | Stakeout   │
│  DeviceManager  | LicenseManager            │
└────────────────────┬────────────────────────┘
                     │
┌────────────────────▼────────────────────────┐
│              Domain Layer                   │
│  Point | Line | Code | CoordinateSystem     │
│  Surface | Road | COGO calculations         │
└────────────────────┬────────────────────────┘
                     │
┌────────────────────▼────────────────────────┐
│           Infrastructure Layer              │
│  SQLite | File I/O | Crypto | Serial/BT     │
└────────────────────┬────────────────────────┘
                     │
┌────────────────────▼────────────────────────┐
│         Hardware Abstraction                │
│     GNSS Drivers    |   Total Station       │
└─────────────────────────────────────────────┘
```

## Key Modules

### 1. Licensing
- HardwareId generation
- License key validation
- Trial period management
- Offline only

### 2. Core
- Project management
- Point / Line / Code storage
- Coordinate systems & transformations
- Basic survey engine

### 3. Devices
- Abstract IDevice interface
- GnssDevice (NMEA first)
- TotalStationDevice

### 4. UI
- QML-based
- Large touch-friendly controls
- Map view
- Dark / Light themes suitable for outdoor use

## Design Principles

- Offline-first
- Fast startup
- Low resource usage
- Hardware abstraction for easy device expansion
- Strong separation of concerns
- Protection against casual reverse engineering
