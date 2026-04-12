# tkprintcompat — User Guide

Version 0.2 | 2026-03-28

---

## Overview

`tkprintcompat` provides the `tk print` command (introduced in Tk 9.0) for
Tcl/Tk 8.6, and fixes known bugs in the Windows implementation for Tk 9.0.3.

### Background

`tk print` was introduced in Tk 9.0 via
[TIP 604](https://core.tcl-lang.org/tips/doc/trunk/tip/604.md).
It provides a cross-platform print dialog for Tk canvas and text widgets.

This library:
- Makes `tk print` available under Tcl/Tk 8.6
- Fixes bugs in the Windows GDI path (font scaling, proportions, Unicode)
- Works transparently — existing code using `tk print` needs no changes

> **Note:** `tkprintcompat` builds on the `tk print` implementation
> from Tk 9.0 (`library/print.tcl`, Tcl Core Team) and backports it to Tcl/Tk 8.6.

### Reference

| Resource | URL |
|----------|-----|
| TIP 604 (tk print specification) | https://core.tcl-lang.org/tips/doc/trunk/tip/604.md |
| print.tcl source | https://core.tcl-lang.org/tk/file?name=library/print.tcl&ci=tip |
| Tcl Core mailing list discussion | https://groups.google.com/g/tcl-core/c/GWSw39JsRHs/m/mp15b5rDBQAJ |
| tk print manpage (Tcl 9.0) | https://www.tcl-lang.org/man/tcl9.0/TkCmd/print.html |
| Tcl Wiki: tk print from 8.7 for 8.6 | https://wiki.tcl-lang.org/page/tk+print+from+8%2E7+for+8%2E6 |

---

## Platform Support

| Platform | Tcl 8.6 | Tcl 9.0.3+ |
|----------|---------|------------|
| Windows | ✓ via `printer` + `gdi` packages | ✓ built-in + fixes |
| Linux (X11) | ✓ via CUPS | ✓ built-in |
| macOS | ✓ via CUPS/PDF | ✓ built-in |

**Minimum version:** Tk 9.0.3 (BAWT 3.2.0). Tk 9.0.2 is not supported.

**Note on X11:** Canvas printing uses Tk's built-in PostScript export
(`$canvas postscript`). Unicode characters outside Latin-1 (e.g. emoji)
may not render correctly. This is a known limitation of the PostScript path.
For full Unicode support on X11, pdf4tcl integration is planned (see todo.md).

---

## Installation

Copy `tkprintcompat-0.2.tm` into a directory on your Tcl module path,
or use `make`:

```bash
make install      # -> ~/lib/tcl8.6/site-tcl/
make install90    # -> ~/lib/tcl9.0/site-tcl/
```

To find a suitable directory:

```tcl
tcl::tm::path list
```

---

## Usage

```tcl
package require Tk
package require tkprintcompat

# Print a canvas widget
canvas .c -width 400 -height 300
.c create text 50 50 -text "Hello World" -font {Arial 14 bold}
.c create oval 100 100 300 250 -fill lightblue -outline navy
tk print .c

# Print a text widget
text .t -wrap word
.t insert end "Some text to print\n"
tk print .t
```

The `tk print` command opens the platform-native print dialog.

---

## Configuring Page Margins

Margins are stored in the `::tk::print::margin` namespace variables (in mm):

```tcl
package require tkprintcompat

# Default values (same as Tk 9.0.3 _init_print):
#   top=15mm, left=25mm, right=15mm, bottom=15mm

# Customize before printing:
set ::tk::print::margin(left)   30
set ::tk::print::margin(top)    20
set ::tk::print::margin(right)  20
set ::tk::print::margin(bottom) 20

tk print .mycanvas
```

---

## Windows Requirements (Tcl 8.6 only)

The `gdi` and `printer` packages by Michael I. Schwartz are required.
They are included in [BAWT 3.2](http://www.bawt.tcl3d.org/).

| Package | Minimum Version |
|---------|----------------|
| `gdi` | 0.9.9.15 |
| `printer` | 0.9.6.16 |
| `struct::list` | 1.9 |

---

## What tkprintcompat fixes

The following bugs in the original `tk print` (Windows) are corrected:

| Bug | Tcl 8.6 | Tcl 9.0.3 | Fix |
|-----|---------|-----------|-----|
| Font descriptor with negative size — text invisible | ✓ | ✓ | Use positive point size |
| Bold/Italic not rendered | ✓ | — | `GdiParseFontWords` called correctly (Tcl 8.6 only) |
| Canvas aspect ratio wrong | ✓ | ✓ | Isotropic scaling with both axes |
| Canvas positioned at top of page | ✓ | ✓ | Offset calculated from margin variables |
| HiDPI scaling wrong | ✓ | ✓ | Nemethi scaling method |
| Unicode/Umlauts lost | ✓ | — | `-unicode` flag for `DrawTextW` (Tcl 8.6 only) |
| Canvas item handler namespace error | ✓ | — | Fully-qualified proc check (Tcl 8.6 only) |
| Paper dimensions swapped | ✓ | — | Corrected index: 0=length, 1=width (Tcl 8.6 only) |
| Canvas positioned at top on X11 | ✓ | ✓ | `postscript -pageanchor nw` override |

---

## Running the Demos

```bash
# All canvas item types (line, rect, oval, arc, polygon, text, rotation):
wish demo/demo-canvas-items.tcl

# Silent print without dialog (Windows):
wish demo/demo-silent.tcl

# Configurable margins:
wish demo/demo-margins.tcl

# Canvas + text widget side by side:
wish demo/demo-complete.tcl

# Debug info and print test:
wish demo/debugdemo.tcl
```


---

## Known Limitations

| Limitation | Platform | Details |
|------------|----------|---------|
| No line wrap for long text | Windows | `-width` removed from `gdi text` |
| No `-angle` rotation | Windows Tcl 8.6 | `gdi 0.9.9.15` does not support it |
| Unicode outside Latin-1 | Linux X11 | PostScript path uses iso8859-1 |
| No native print dialog | Linux X11 | Tk dialog instead of OS dialog |
| Tk 9.0.2 not supported | Windows | Different internal data structure |

---

## Building from Source

```bash
# Pure Tcl build (no dependencies):
tclsh build.tcl

# Or using make:
make

# Fallback if tcllib available:
python3 build.py
```

Source files:

| File | Purpose |
|------|---------|
| `src/print.tcl` | Tk 9.0.3 library/print.tcl (do not modify) |
| `src/newtcl8790.tcl` | Compatibility shims for Tcl 8.6 |
| `src/print-8.6erw.tcl` | All fixes + `package provide` |

---

## License

BSD-style, same as Tcl/Tk.

## Origin

Based on the Tcl Wiki contribution
[tk print from 8.7 for 8.6](https://wiki.tcl-lang.org/page/tk+print+from+8%2E7+for+8%2E6)
(2023-09-13), extended and packaged as tkprintcompat.
