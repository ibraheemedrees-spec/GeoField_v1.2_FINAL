# Geo Field UI — Revision 2

## Shell
- Top bar (brand + license)
- Content
- **Bottom navigation:** Job · Map · Survey · Stake · More

## Home
- Compact **GNSS status card** (no diagnostic dump)
- Context action: Connect / Survey / Stakeout
- Job card
- Small workflow row

## Diagnostics
Only under **More → Diagnostics** (or GNSS Status → Diagnostics).

## Settings hierarchy
More → Settings → Receiver | Survey | Stakeout | CRS | Geoid | Units | Map | Data | Diagnostics | Advanced

## Backend
Unchanged: GnssManager, IConnection, BT/BLE, NTRIP, Geoid, validation.
