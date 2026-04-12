#!/usr/bin/env wish
# printtestfont.tcl -- Font-Drucktest fuer tkprintcompat

package require Tk
tcl::tm::add path [file join ../]
package require tkprintcompat

wm title . "Font-Test"

text .t -wrap word -height 20 -width 50
foreach {name size} {Arial 8 Arial 10 Arial 12 Arial 14
                     {Arial bold} 12 {Arial italic} 12
                     Courier 10 Courier 12
                     {Times New Roman} 12} {
    .t insert end "${name} ${size}pt: Hello World 0123456789\n"
}
pack .t -fill both -expand 1

button .btn -text "Drucken" -command { tk print .t }
pack .btn -pady 8
