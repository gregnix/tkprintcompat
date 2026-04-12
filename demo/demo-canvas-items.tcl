#!/usr/bin/env wish
# demo-canvas-items.tcl -- Alle Canvas-Item-Typen drucken
# Zeigt: line, rectangle, oval, arc, polygon, text (normal/bold/italic/rotiert)

package require Tk
tcl::tm::add path [file join ../]
package require tkprintcompat

wm title . "Canvas Items Demo"
wm geometry . "650x550"

# --- Canvas mit allen Item-Typen ---
canvas .c -width 580 -height 420 -background white \
    -scrollregion {0 0 580 420}

# Titel
.c create text 20 20 -text "tkprintcompat -- Canvas Item Demo" \
    -font {Arial 14 bold} -anchor w -fill black

.c create line 20 38 560 38 -width 1 -fill black

# Linien
.c create text 20 55 -text "Linien:" -anchor w -font {Arial 9 bold}
.c create line  20  70 150  70 -width 1 -fill black
.c create line  20  85 150  85 -width 2 -fill navy
.c create line  20 100 150 100 -width 4 -fill red -dash {6 3}
.c create line 160  70 290 100 -width 2 -fill darkgreen -arrow last

# Rechtecke
.c create text 300 55 -text "Rechtecke:" -anchor w -font {Arial 9 bold}
.c create rect 300  70 430  90 -outline black -fill lightyellow
.c create rect 300  95 430 115 -outline navy  -fill lightblue  -width 2
.c create rect 300 120 430 140 -outline red   -fill {}

# Ovale
.c create text 20 130 -text "Ovale:" -anchor w -font {Arial 9 bold}
.c create oval  20 145 120 185 -fill lightblue -outline navy
.c create oval 130 145 200 175 -fill {}        -outline darkgreen -width 2
.c create oval 210 145 250 185 -fill salmon    -outline red

# Bogen (arc)
.c create text 20 200 -text "Boegen:" -anchor w -font {Arial 9 bold}
.c create arc  20 215 120 285 -start 0   -extent 90  -fill lightgreen -outline black
.c create arc 130 215 230 285 -start 45  -extent 180 -fill lightyellow -outline navy \
    -style chord
.c create arc 240 215 340 285 -start 0   -extent 270 -style arc \
    -outline red -width 2

# Polygon
.c create text 360 130 -text "Polygon:" -anchor w -font {Arial 9 bold}
.c create polygon 360 145 430 145 460 185 390 200 340 175 \
    -fill lightyellow -outline black

# Text-Varianten
.c create text 20 305 -text "Text:" -anchor w -font {Arial 9 bold}
.c create text 20 325 -text "Normal Arial 10" \
    -font {Arial 10} -anchor w
.c create text 20 345 -text "Bold Arial 10" \
    -font {Arial 10 bold} -anchor w -fill navy
.c create text 20 365 -text "Italic Arial 10" \
    -font {Arial 10 italic} -anchor w -fill darkgreen
.c create text 20 385 -text "Bold+Italic" \
    -font {Arial 10 bold italic} -anchor w -fill darkred

# Rotierter Text (nur Tk 9.0.3 auf Windows)
.c create text 200 360 -text "Rotiert 30\u00b0" \
    -font {Arial 11 bold} -angle 30 -anchor w -fill purple
.c create text 300 360 -text "Rotiert 45\u00b0" \
    -font {Arial 11} -angle 45 -anchor w -fill darkblue

# Unicode
.c create text 400 325 \
    -text "\u00c4\u00d6\u00dc \u00e4\u00f6\u00fc \u00df \u20ac \u00a9" \
    -font {Arial 11} -anchor w -fill darkgreen

pack .c -padx 8 -pady 8

# Buttons
frame .bot
button .bot.print -text "Drucken (tk print)" \
    -command {tk print .c}
button .bot.info -text "Tcl [info patchlevel] | [tk windowingsystem]" \
    -state disabled -relief flat
pack .bot.print -side left -padx 8
pack .bot.info  -side right -padx 8
pack .bot -fill x -pady 4
