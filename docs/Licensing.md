# Geo Field - Licensing System

## Rules

- Trial period: **24 hours** starting from first launch
- After trial expires → application requires activation code
- Activation is **100% offline**
- License is bound to **Hardware ID**
- One-time purchase = permanent license on the same device
- Moving the software to another device invalidates the license

## Hardware ID

Generated from multiple machine identifiers:
- CPU / Motherboard info
- Storage serial
- MAC address
- Platform-specific unique ID (Android ID or Windows Machine GUID)

Result: 32-character uppercase hex string.

## License Key Format

```
GF-XXXXX-XXXXX-XXXXX-XXXXX
```

- 25 characters total (including dashes)
- Contains encrypted binding to Hardware ID
- Contains license type (Permanent)
- Contains simple signature to detect tampering

## Flow

1. First run:
   - Generate & store Hardware ID (encrypted)
   - Record first-run timestamp
   - Start 24-hour trial

2. Every launch:
   - Check if trial still valid
   - If trial expired → look for valid license file
   - Validate Hardware ID match + signature
   - Allow or block

3. Activation:
   - User enters code
   - Program validates code against current Hardware ID
   - If valid → write encrypted license file

## Seller Tool

`tools/LicenseGenerator`  
Input: Customer Hardware ID  
Output: Activation code

This tool is **never** distributed with the application.
