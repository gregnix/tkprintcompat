#!/usr/bin/env wish
# demo-complete.tcl -- tkprintcompat Demo

package require Tk
tcl::tm::add path [file join ../]
package require tkprintcompat

wm title . "tkprintcompat [package require tkprintcompat] Demo"
wm geometry . "700x500"

label .info \
    -text "tkprintcompat [package require tkprintcompat] | Tk [info patchlevel] | [tk windowingsystem]" \
    -anchor w -foreground grey40
pack .info -fill x -padx 8 -pady 4

ttk::notebook .nb
pack .nb -fill both -expand 1 -padx 8 -pady 4

# --- Tab 1: Canvas ---
set fc [ttk::frame .nb.canvas]
.nb add $fc -text "Canvas"

canvas $fc.c -width 500 -height 300 -background white \
    -scrollregion {0 0 500 300}
$fc.c create text   50  40 -text "Canvas-Druck Demo" -font {Arial 18 bold} -anchor w
$fc.c create line   50  60 450  60 -width 2
$fc.c create rect   50  80 450 200 -outline black -fill lightyellow
$fc.c create text   60 100 -text "Tcl [info tclversion] / Tk [package require Tk]" -anchor w
$fc.c create text   60 125 -text "tk windowingsystem: [tk windowingsystem]" -anchor w
$fc.c create oval  200 220 300 280 -fill lightblue -outline navy
pack $fc.c -padx 8 -pady 8

button $fc.btn -text "Canvas drucken (tk print)" \
    -command { tk print .nb.canvas.c }
pack $fc.btn -pady 4

# --- Tab 2: Text ---
set ft [ttk::frame .nb.text]
.nb add $ft -text "Text"

text $ft.t -wrap word -font {Arial 11} -height 12
$ft.t insert end "tkprintcompat [package require tkprintcompat] -- Textdruck-Demo\n\n"
$ft.t insert end "Dieses Text-Widget wird per tk print gedruckt.\n"
$ft.t insert end "Plattform: $::tcl_platform(platform)\n"
$ft.t insert end "Tcl: [info tclversion]\n"
$ft.t insert end "Windowingsystem: [tk windowingsystem]\n\n"
$ft.t insert end "Lorem ipsum dolor sit amet, consectetur adipiscing elit.\n"
$ft.t insert end "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\n"
$ft.t configure -state disabled
pack $ft.t -fill both -expand 1 -padx 8 -pady 8

button $ft.btn -text "Text drucken (tk print)" \
    -command { tk print .nb.text.t }
pack $ft.btn -pady 4
