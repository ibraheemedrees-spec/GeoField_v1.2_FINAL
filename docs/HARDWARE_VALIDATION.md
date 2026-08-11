# Hardware Validation Procedure

**Never mark FIELD_TESTED without completing this checklist on physical equipment.**

## Compatibility states (app)
| State | Meaning |
|-------|---------|
| DISCOVERED | Found in scan |
| CONNECTED | Transport OK |
| DATA_DETECTED | Bytes RX |
| GNSS_VERIFIED | NMEA recognized |
| RTK_VERIFIED | Correction path verified |
| FIELD_TESTED | Full field checklist pass |

`PHYSICAL TEST REQUIRED` remains until FIELD_TESTED.

## Checklist
1. Power on receiver  
2. Pair if Classic BT  
3. Scan in Geo Field  
4. Connect  
5. (BLE) Verify services / select RX-TX  
6. Confirm RX/TX  
7. Confirm NMEA (`GNSS DATA DETECTED`)  
8. Satellites  
9. Position  
10. NTRIP connect  
11. RTCM TX counters increase  
12. FLOAT (if applicable)  
13. FIXED (only if receiver reports it)  
14. Correction age  
15. Disconnect  
16. Reconnect  
17. Store survey point  
18. Stakeout guidance  
19. Record: manufacturer, model, firmware, transport, date, result, notes  

## Record template
```
Manufacturer:
Model:
Firmware:
Transport: Serial | Bluetooth | BLE
NMEA: Y/N
RTCM: Y/N
NTRIP: Y/N
Base/Rover:
Result: PASS / FAIL
Date:
Notes:
```

## U6.2 State definitions (software)

| State | Evidence required |
|-------|-------------------|
| CONNECTED | Transport socket open |
| DATA_DETECTED | Any RX bytes |
| GNSS_VERIFIED | ≥3 valid GGA (checksum + lat/lon + time + fix quality) |
| RTK_VERIFIED | GNSS_VERIFIED **and** receiver reports FLOAT or FIXED |
| FIELD_TESTED | **Manual** `markFieldTested(record)` only |

RTCM bytes transmitted **alone** never set RTK_VERIFIED.

Solution status values: NO_RECEIVER, NO_FIX, AUTONOMOUS, DGPS, FLOAT, FIXED, UNKNOWN — from receiver data only.
