# Geo Field UI Architecture

## Identity
Professional GNSS survey **field controller** — not a generic button dashboard.

## Shell
1. **Top bar** — title, license badge, back
2. **GNSS status bar** (persistent) — solution, SV, H/V, age, transport · tap → Status
3. **Job strip** — active job + point count
4. **Content** — page body (Flickable)

## Navigation map
| Page | Role |
|------|------|
| 0 Home | Dashboard + primary/secondary workflow |
| 1 Job | Create / open job |
| 2 Settings hub | Category list |
| 15 Settings detail | Category body |
| 7 Connect | Transport + scan + BLE profile |
| 8 Receiver setup | Identity + links |
| 9 Survey | Store points + QC |
| 10 Stakeout | Guidance |
| 5 COGO | Calculate |
| 6 Map | Live status canvas |
| 14 GNSS status | Full readout |
| 13 License | Activation |

Primary workflow: **Job → Connect → Survey → Stakeout → Map → Calculate**  
Secondary: Settings, Receiver Setup, Exchange, Reports, Apps, License

## Design rules
- Large touch targets, high contrast
- No fake FIXED / accuracy
- Capability-driven labels (RECEIVER_CONTROLLED / NOT_IMPLEMENTED)
- Offline-first jobs and profiles
