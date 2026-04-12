# tkprintcompat — Tests

## test-basic.tcl

5 Grundtests: package laden, dict getdef, lpop, tk print, CUPS.

```bash
wish test/test-basic.tcl
```

## test-unit.tcl

~35 Unit-Tests ohne Drucker:
- newtcl8790 Shims
- _scalingPct Formel
- Margin-Berechnung
- Font-Descriptor
- Namespace-Struktur
- Skalierungsformel

```bash
wish test/test-unit.tcl
```

## test-print.tcl

Drucktests mit PDF-Drucker (visuell pruefen):

```bash
# Interaktiv (Druckdialog):
wish test/test-print.tcl

# Stiller Druck auf bestimmten Drucker:
wish test/test-print.tcl -printer "PDF24"
wish test/test-print.tcl -printer "Microsoft Print to PDF"
```
