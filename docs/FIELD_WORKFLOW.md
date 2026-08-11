# Field Setup Workflow

## Flow
Connect → Receiver → GNSS → Corrections → Work Mode → Antenna → CRS → Geoid → Job → Survey Setup → Ready → Survey

Conditional:
- Simple (mode 1): skips Corrections
- Base (mode 2): skips Survey setup soft path

## Validation
- Connect: requires gnss connected for Next
- Antenna: height > 0
- Job: name + created project

## Persistence
`ProfileStore` key `_wizard_state`

## Backend
Reuses GnssManager, NTRIP, Geoid, BluetoothScanner, ProjectManager — no GNSS core changes.
