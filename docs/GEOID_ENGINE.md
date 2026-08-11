# Geoid Engine (U5)

## Architecture
```
Ellipsoidal height h (from GNSS)
        ↓
   GeoidEngine.query(lat, lon) → N
        ↓
   H = h − N   (orthometric)
```

Independent of GnssManager / Serial / NTRIP / OEM.

## Formula
**H = h − N**  
- `h` = ellipsoidal height (metres)  
- `N` = geoid height above ellipsoid (metres)  
- `H` = orthometric height (metres)  

If N cannot be computed → orthometric returns NaN; UI must show “Geoid model not loaded”.

## Models
| Kind | Status |
|------|--------|
| None | Null model |
| EGM96 | Stub — **NOT_IMPLEMENTED** until official grid file + parser |
| EGM2008 | Stub — **NOT_IMPLEMENTED** until official grid file + parser |
| Custom | **GridGeoidModel** ASCII `GFGRID` format with bilinear interpolation |

## Custom file format (`*.gfgrid`)
```
GFGRID <west> <south> <east> <north> <dLon> <dLat> [name]
<row north values west→east>
...
<row south>
```
Example 2×2:
```
GFGRID 30 29 31 30 1 1 TestGrid
10 12
14 16
```

## Official EGM datasets
Not bundled. Obtain official EGM96/EGM2008 grids from recognised geodetic agencies; add a dedicated loader in a future phase. Do not download random internet grids into the repo.

## Errors
NotLoaded · NotImplemented · InvalidCoordinates · OutsideCoverage · CorruptModel · FileNotFound

## Tests
`tests/test_geoid.cpp` — invalid coords, load/unload, bilinear, H=h−N, EGM stub.
