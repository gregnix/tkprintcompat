# tkprintcompat 0.2

`tk print` compatibility library for Tcl/Tk 8.6 and Tcl/Tk 9.0.3+.

Provides the `tk print` command (introduced in Tk 9.0) for Tcl 8.6 as well.

Based on the Tcl Wiki article
[tk print from 8.7 for 8.6](https://wiki.tcl-lang.org/page/tk+print+from+8.7+for+8.6).

---

## Platform Overview

| | Tcl 8.6 | Tcl 9.0.3+ |
|--|---------|------------|
| Windows | ✓ `printer` + `gdi` | ✓ built-in + fixes |
| Linux (X11) | ✓ CUPS | ✓ built-in |
| macOS | ✓ CUPS/PDF | ✓ built-in |

**Minimum version:** Tk 9.0.3 (BAWT 3.2.0). Tk 9.0.2 is not supported.

---

## Quick Start

```tcl
package require Tk
package require tkprintcompat

tk print .mycanvas   ; # print a Canvas widget
tk print .mytext     ; # print a Text widget
```

---

## What's New in 0.2?

- Bold/Italic in Canvas printing (Windows, tested) ✓
- Unicode/umlauts/€/© (Windows; X11 limited by PostScript/iso8859-1) ✓
- Correct proportions (aspect ratio preserved) ✓
- Text rotation (`-angle`) under Tk 9.0.3 on Windows ✓
- HiDPI scaling correction ✓
- 50+ automated tests (tcltest, branch-accurate) ✓

Details: [CHANGES.md](CHANGES.md)

---

## Installation

```bash
# Linux:
cp tkprintcompat-0.2.tm ~/lib/tcl8.6/site-tcl/
cp tkprintcompat-0.2.tm ~/lib/tcl9.0/site-tcl/

# Or:
make install
```

**Windows Tcl 8.6** additionally requires:
`gdi 0.9.9.15+`, `printer 0.9.6.16+`, `struct::list 1.9+` — included in [BAWT 3.2](http://www.bawt.tcl3d.org/).

**Windows Tcl 9.0.3** requires no additional packages.

---

## Tests

```bash
# Unit tests (no printer required):
wish test/test-unit.tcl       # ~50 tests, branch-accurate

# Basic tests:
tclsh test/test-basic.tcl     # 6 tests

# Print tests (PDF printer, wish!):
wish test/test-print.tcl -printer "PDF24"   # 5 tests (Windows)
```

Each test runs only on the platform/version it applies to
(`win32`, `x11`, `tk86`, `tk9` and combinations).

---

## Build

```bash
make              # build tkprintcompat-0.2.tm (via build.tcl)
make install      # install
make test         # run unit tests
make clean

# Direct (pure Tcl, no dependencies):
tclsh build.tcl
# Fallback:
python3 build.py
```

`src/print.tcl` is based on Tk 9.0.3 (BAWT 3.2.0).
When updating Tk: replace `src/print.tcl` and run `make`.

---

## Dependencies — Windows Tcl 8.6

```tcl
package require gdi        ; # 0.9.9.15+
package require printer    ; # 0.9.6.16+
package require struct::list
```

Included in [BAWT 3.2](http://www.bawt.tcl3d.org/).

---

## Documentation

**[docs/USERGUIDE.md](docs/USERGUIDE.md)**

---

## References

| Resource | URL |
|----------|-----|
| TIP 604 (tk print specification) | https://core.tcl-lang.org/tips/doc/trunk/tip/604.md |
| print.tcl source (Tk tip) | https://core.tcl-lang.org/tk/file?name=library/print.tcl&ci=tip |
| Tcl Core mailing list | https://groups.google.com/g/tcl-core/c/GWSw39JsRHs/m/mp15b5rDBQAJ |
| tk print manpage (Tcl 9.0) | https://www.tcl-lang.org/man/tcl9.0/TkCmd/print.html |
| Tcl Wiki origin | https://wiki.tcl-lang.org/page/tk+print+from+8%2E7+for+8%2E6 |
| gdi/printer packages | http://wiki.tcl-lang.org/page/TkPrint |
| BAWT | http://www.bawt.tcl3d.org/ |

## License

BSD-style — same as Tcl/Tk itself.
