#!/usr/bin/env wish
# demoprint.tcl -- Einfache Druck-Demo fuer tkprintcompat

package require Tk
tcl::tm::add path [file join ../]
package require tkprintcompat

wm title . "demoprint"

canvas .c -width 400 -height 300 -background white
.c create text 20 20 -text "Drucktest" -font {Arial 16 bold} -anchor w
.c create text 20 60 -text "Tcl [info tclversion] | [tk windowingsystem]" -anchor w
.c create line 20 80 380 80
.c create rect 20 100 380 280 -outline black
pack .c

button .btn -text "Drucken" -command { tk print .c }
pack .btn -pady 8
