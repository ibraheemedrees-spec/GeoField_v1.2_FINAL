# Offline Map Engine (M1–M3)

## Classes
- `IMapProvider` — abstraction
- `MbTilesProvider` — SQLite MBTiles (TMS/XYZ)
- `MapEngine` — camera, follow GNSS, overlays, Web Mercator project

## Offline
- No network required for marker/points
- Place `Documents/GeoField/Maps/default.mbtiles` and call `openDefaultMbTiles()`

## Real GNSS only
- Marker from `GnssManager::positionMap()`
- No fabricated coordinates

## Limitations
- Full tile raster blit in QML Canvas not yet (status + grid + overlays work)
- GeoPackage / GeoTIFF providers: architecture ready, not implemented
- OSM attribution required if distributing OSM-derived MBTiles
