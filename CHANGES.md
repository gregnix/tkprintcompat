# tkprintcompat — Change History

---

## 0.2 (2026-03-28)

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
- `src/print.tcl` based on Tk 9.0.3 (BAWT 3.2.0)
- Minimum version Tk 9.0.3 (Tk 9.0.2 not supported)

---

## 0.1 / printtk86 (2023-09-13)

Initial release as Tcl Wiki article "tk print from 8.7 for 8.6".
Basic wrapper procs for Windows Tcl 8.6:
`_openprinter`, `_selectprinter`, `_opendoc`, `_closedoc`,
`_openpage`, `_closepage`, `_gdi`.

Source: https://wiki.tcl-lang.org/page/tk+print+from+8.7+for+8.6
