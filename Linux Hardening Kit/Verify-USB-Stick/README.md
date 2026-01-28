# Verify-USB-Stick
Verify files on a USB stick, to detect if stick has gone corrupt or if *someone* or *something* changed it.

## Installation

Place the .bat files on a USB stick and double click it to create hashes/verify for all files.

Use the `generate-hashes.bat` to scan the root and produce hashes.

## Recursive

Use the `generate-recursive.bat` to scan all folders instead of the root.

## Verify

Later on, you can verify the files again in powershell per file:

```powershell
Get-FileHash file.bin -Algorithm SHA256
```

## Recursive verify

If you used `generate-recursive.bat` run `check-recursive.bat` to verify
