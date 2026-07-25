# tkprintcompat — Change History

---

## 0.3

Maintenance and cleanup; no functional change to printing.

- Updated `src/print.tcl` to the Tk 9.0.4 core version (verbatim). The change
  from 9.0.3 is cosmetic only (a copyright line and a comment); `print.tcl` and
  `tkWinGDI.c` are otherwise unchanged, so all fixes remain necessary and
  correct.
- Single build path: removed `build.py`, fixed a whitespace bug in `build.tcl`
  (leading space on generated comment lines) so it is the one source of truth.
- Source comments translated to English throughout (except `src/print.tcl`,
  kept verbatim from the Tk core so version diffs stay meaningful).
- Documented the platform test skips (`win32` / `tk86`) as expected.

---

## 0.2

Complete rewrite. Renamed to `tkprintcompat` (previously `printtk86`).

### New Features
- Tk 9.0.3 support — `_print_canvas` wrapper for stable Tk 9.x compatibility
- Bold/Italic in Canvas printing (positive font size + GdiParseFontWords)
- `-unicode` flag for DrawTextW (umlauts, special characters, €)
- `-angle` text rotation under Tk 9.0.3
- Isotropic scaling — Canvas aspect ratio exactly preserved
- Margins in mm, consistent with Tk 9 `_init_print` (configurable)
- `_gdi map -offset` correctly calculated from margins
- `::tkprintcompat::_scalingPct` — HiDPI scaling correction (Nemethi)
- 45 automated tests (unit, basic, print)

### Bug Fixes
- Paper size index: `printer attr "page dimensions"` index 0=length, 1=width
- Font descriptor: negative size disables GdiParseFontWords → changed to positive
- `_gdi map` expects integer (sscanf %ld) — float rounding applied
- `_print_canvas` namespace-qualified check (all Tk versions)
- `_gdi textplain` → `gdi text -anchor nw` mapping
- `_gdi text -width 0` makes text invisible → removed

### Source Base
- `src/print.tcl` based on Tk 9.0.4 (verbatim from the Tk core)
- Minimum version Tk 9.0.3 (Tk 9.0.2 not supported)

---

## 0.1 / printtk86

Initial release as Tcl Wiki article "tk print from 8.7 for 8.6".
Basic wrapper procs for Windows Tcl 8.6:
`_openprinter`, `_selectprinter`, `_opendoc`, `_closedoc`,
`_openpage`, `_closepage`, `_gdi`.

Source: https://wiki.tcl-lang.org/page/tk+print+from+8.7+for+8.6
