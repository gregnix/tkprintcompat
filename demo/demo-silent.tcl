#!/usr/bin/env wish
# demo-silent.tcl -- Stiller Druck ohne Dialog (Windows)
# Demonstriert printer open -name / -default ohne Druckdialog

package require Tk
tcl::tm::add path [file join ../]
package require tkprintcompat

wm title . "Stiller Druck Demo"
wm geometry . "500x400"

# Canvas
canvas .c -width 460 -height 200 -background white \
    -scrollregion {0 0 460 200}
.c create text 20 20 -text "Stiller Druck Demo" \
    -font {Arial 14 bold} -anchor w
.c create line 20 38 440 38 -width 1
.c create rect 20 50 440 150 -outline black -fill lightyellow
.c create text 30 75  -text "Tcl [info patchlevel]" -anchor w -fill darkblue
.c create text 30 100 -text "[tk windowingsystem]"  -anchor w -fill darkgreen
.c create text 30 130 \
    -text "\u00c4\u00d6\u00dc \u00e4\u00f6\u00fc \u00df \u20ac" \
    -anchor w -fill darkred
.c create oval 330 60 420 140 -fill lightblue -outline navy
pack .c -padx 8 -pady 8

# Log
text .log -height 6 -font {Courier 9} -state disabled
pack .log -fill x -padx 8

proc log {msg} {
    .log configure -state normal
    .log insert end "$msg\n"
    .log see end
    .log configure -state disabled
}

proc do_print {printer} {
    log "Drucke auf: $printer ..."
    if {[catch {tk print .c} err]} {
        log "FEHLER: $err"
    } else {
        log "OK (Rueckgabe: $err)"
    }
}

# Buttons
frame .bot
pack .bot -fill x -padx 8 -pady 4

if {[tk windowingsystem] eq "win32"} {
    # Druckerliste laden
    catch {
        package require printer
        set plist [printer list]
    }

    button .bot.dialog -text "Mit Dialog (tk print)" \
        -command {tk print .c}
    pack .bot.dialog -side left -padx 4

    if {[info exists plist] && [llength $plist] > 0} {
        # Standarddrucker
        button .bot.default -text "Standarddrucker (kein Dialog)" \
            -command {
                log "Oeffne Standarddrucker ..."
                if {[catch {
                    namespace eval ::tk::print {
                        variable printer_name paper_width paper_height
                        variable dpi_x dpi_y copies
                    }
                    set hDC [printer open -default]
                    set ::tk::print::printer_name [lindex $hDC 0]
                    log "Drucker: $::tk::print::printer_name"
                    printer close
                } err]} {
                    log "FEHLER: $err"
                }
            }
        pack .bot.default -side left -padx 4

        # Druckerliste als Menubutton
        menubutton .bot.choose -text "Drucker waehlen ..." \
            -relief raised -menu .bot.choose.m
        menu .bot.choose.m -tearoff 0
        foreach p $plist {
            .bot.choose.m add command -label $p \
                -command [list do_print $p]
        }
        pack .bot.choose -side left -padx 4
    }

    button .bot.list -text "Druckerliste" -command {
        catch {
            package require printer
            log "Drucker: [join [printer list] {, }]"
        }
    }
    pack .bot.list -side right -padx 4
} else {
    label .bot.info -text "Stiller Druck nur auf Windows verfuegbar."
    button .bot.print -text "Drucken (tk print)" \
        -command {tk print .c}
    pack .bot.info .bot.print -side left -padx 4
}
