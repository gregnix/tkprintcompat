#!/usr/bin/env wish
# demo-margins.tcl -- Konfigurierbare Margins
# Zeigt wie ::tk::print::margin(left/top/right/bottom) angepasst wird

package require Tk
tcl::tm::add path [file join ../]
package require tkprintcompat

wm title . "Margins Demo"
wm geometry . "500x480"

# Canvas
canvas .c -width 460 -height 180 -background white \
    -scrollregion {0 0 460 180}
.c create text 20 20 -text "Margins Demo" -font {Arial 14 bold} -anchor w
.c create line 20 38 440 38 -width 1
.c create rect 20 50 440 160 -outline black -fill lightyellow
.c create text 30 80  -text "Der Ausdruck zeigt den Canvas" -anchor w
.c create text 30 105 -text "mit den eingestellten Raendern." -anchor w
.c create oval 340 60 420 150 -fill lightblue -outline navy
pack .c -padx 8 -pady 8

# Margin-Einstellungen
frame .mf -relief groove -borderwidth 2
pack .mf -fill x -padx 8 -pady 4

label .mf.title -text "Seitenraender (mm):" -font {Arial 9 bold} -anchor w
grid .mf.title - - - -sticky w -padx 4 -pady 4

foreach {key label col} {
    top    "Oben:"   0
    left   "Links:"  2
    right  "Rechts:" 4
    bottom "Unten:"  0
} {
    namespace eval ::tk::print { variable margin }
    set ::tk::print::margin($key) \
        [expr {[info exists ::tk::print::margin($key)] ? \
               $::tk::print::margin($key) : 15}]
}
set ::tk::print::margin(left) 25

label  .mf.ltop -text "Oben (mm):"   -anchor e
entry  .mf.etop -textvariable ::tk::print::margin(top)   -width 6
label  .mf.lleft -text "Links (mm):"  -anchor e
entry  .mf.eleft -textvariable ::tk::print::margin(left)  -width 6
label  .mf.lright -text "Rechts (mm):" -anchor e
entry  .mf.eright -textvariable ::tk::print::margin(right) -width 6
label  .mf.lbottom -text "Unten (mm):"  -anchor e
entry  .mf.ebottom -textvariable ::tk::print::margin(bottom) -width 6

grid .mf.ltop   .mf.etop   .mf.lleft   .mf.eleft   -sticky ew -padx 4 -pady 2
grid .mf.lright .mf.eright .mf.lbottom .mf.ebottom -sticky ew -padx 4 -pady 2

# Aktuelle Werte anzeigen
proc show_margins {} {
    namespace eval ::tk::print { variable margin }
    .log configure -state normal
    .log delete 1.0 end
    foreach k {top left right bottom} {
        set mm  $::tk::print::margin($k)
        set pts [expr {int($mm / 25.4 * 1000)}]
        .log insert end "margin($k) = ${mm}mm -> ${pts} (1/1000 Zoll)\n"
    }
    .log configure -state disabled
}

# Log
text .log -height 5 -font {Courier 9} -state disabled
pack .log -fill x -padx 8

show_margins

# Buttons
frame .bot
button .bot.show  -text "Werte anzeigen" -command show_margins
button .bot.reset -text "Zurücksetzen" -command {
    set ::tk::print::margin(top)    15
    set ::tk::print::margin(left)   25
    set ::tk::print::margin(right)  15
    set ::tk::print::margin(bottom) 15
    show_margins
}
button .bot.print -text "Drucken (tk print)" -command {
    show_margins
    tk print .c
}
pack .bot.show .bot.reset .bot.print -side left -padx 4 -pady 4
pack .bot -fill x -padx 8
