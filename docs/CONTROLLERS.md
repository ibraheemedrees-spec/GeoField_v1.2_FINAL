# Controllers Support

## Fully targeted

| Platform | Examples | Status |
|----------|----------|--------|
| Android 7+ | SHC5000-class Android, generic rugged tablets, phones | Full |
| Windows 10/11 | Field tablets, FC-series with Win10, laptops | Full |

## Not available

| Platform | Reason |
|----------|--------|
| Windows Mobile 6.x | No Qt6 support, SDK dead, vendors stopped new field software on WM |
| Windows CE | Same as above |

## Recommendation for mixed fleets

- Modern controllers → Geo Field Complete (this package)
- Remaining WM devices → keep existing MAGNET/old software for instrument control only
- Or replace WM units gradually with Android tablets (cost-effective)

One codebase, all modern controllers.
