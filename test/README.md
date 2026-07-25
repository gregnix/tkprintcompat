# tkprintcompat -- tests

## test-basic.tcl

5 basic tests: load the package, dict getdef, lpop, tk print, CUPS.

```bash
wish test/test-basic.tcl
```

## test-unit.tcl

~48 unit tests without a printer:
- newtcl8790 shims
- _scalingPct formula
- margin calculation
- font descriptor
- namespace structure
- scaling formula

```bash
wish test/test-unit.tcl
```

### Platform skips

Some tests carry `win32` or `tk86` constraints and are skipped on other
platforms -- this is expected, not a gap. On Linux under Tcl 9 you will see
13 skips (9x `win32`, 2x `tk86`, 2x `tk86_win`); the same tests run on their
own platform (Windows, or Tcl 8.6 respectively).

## test-print.tcl

Print tests with a PDF printer (inspect visually):

```bash
# Interactive (print dialog):
wish test/test-print.tcl

# Silent print to a specific printer:
wish test/test-print.tcl -printer "PDF24"
wish test/test-print.tcl -printer "Microsoft Print to PDF"
```
