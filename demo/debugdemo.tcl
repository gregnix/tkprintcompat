#!/usr/bin/env wish
# debugdemo.tcl -- tkprintcompat System-Info und Drucktest

package require Tk
tcl::tm::add path [file join ../]
package require tkprintcompat
set ::filetm [package ifneeded tkprintcompat 0.3]
wm title . "tkprintcompat Debug"
wm geometry . "700x500"

# --- Info-Bereich ---
frame .top -relief sunken -borderwidth 1
pack .top -fill x -padx 4 -pady 4

label .top.t -text "System-Info" -font {Arial 10 bold} -anchor w
pack .top.t -fill x -padx 4

text .top.info -height 10 -font {Courier 9} -wrap none
pack .top.info -fill x -padx 4 -pady 2

proc show_info {} {
    .top.info configure -state normal
    .top.info delete 1.0 end
    .top.info insert end "Tcl:              [info patchlevel]\n"
    .top.info insert end "Tk:               [package require Tk]\n"
    .top.info insert end "windowingsystem:  [tk windowingsystem]\n"
    .top.info insert end "tkprintcompat:    [package require tkprintcompat]\n"

    .top.info insert end "tm-Datei:         [package ifneeded tkprintcompat 0.3]\n"
    .top.info insert end "tk scaling:       [tk scaling]\n"
    .top.info insert end "scalingPct:       [::tkprintcompat::_scalingPct]\n"
    .top.info insert end "\n"
    if {[tk windowingsystem] eq "win32"} {
        foreach pkg {gdi printer struct::list} {
            if {[catch {package require $pkg} v]} {
                .top.info insert end "$pkg: FEHLT ($v)\n"
            } else {
                .top.info insert end "$pkg: $v\n"
            }
        }
        .top.info insert end "\n"
    }
    set procs [lsort [namespace eval ::tk::print { info commands }]]
    .top.info insert end "::tk::print procs: [llength $procs]\n"
    foreach p {_selectprinter _openprinter _gdi _set_dc _print_canvas} {
        set ok [expr {$p in $procs ? "OK" : "fehlt"}]
        .top.info insert end "  $p: $ok\n"
    }
    .top.info configure -state disabled
}
show_info

# --- Canvas ---
frame .mid
pack .mid -fill both -expand 1 -padx 4 -pady 4

canvas .mid.c -width 500 -height 200 -background white \
    -scrollregion {0 0 500 200}
.mid.c create text   50  30 -text "Canvas-Druck Debug" \
    -font {Arial 16 bold} -anchor w -fill black
.mid.c create line   50  50 450  50 -width 2 -fill black
.mid.c create rect   50  70 450 160 -outline black -fill lightyellow
.mid.c create text   60  90 -text "Tcl [info patchlevel]" -anchor w -fill darkblue
.mid.c create text   60 115 -text "[tk windowingsystem]"  -anchor w -fill darkgreen
.mid.c create text   60 150 -text "[lindex $::filetm end]"  -anchor w -fill darkgreen

.mid.c create text   60 140 -text "\u00c4 \u00d6 \u00dc \u00e4 \u00f6 \u00fc \u00df \u20ac \u00a9" -anchor w -fill black
.mid.c create oval  300  80 420 150 -fill lightblue -outline navy
pack .mid.c -side left -padx 4

# --- Buttons ---
frame .bot
pack .bot -fill x -padx 4 -pady 4

button .bot.reload -text "Reload" -command {
    .log configure -state normal
    .log insert end "\n--- Reload tkprintcompat ---\n"
    package forget tkprintcompat
    if {[catch {source ../tkprintcompat-0.3.tm} err]} {
        .log insert end "FEHLER: $err\n"
    } else {
        .log insert end "OK\n"
    }
    show_info
    .log see end
    .log configure -state disabled
}

button .bot.print -text "Canvas drucken" -command {
    .log configure -state normal
    .log insert end "\n--- tk print .mid.c ---\n"
    if {[catch {tk print .mid.c} err]} {
        .log insert end "FEHLER: $err\n"
    } else {
        .log insert end "OK\n"
    }
    .log see end
    .log configure -state disabled
}

# Diagnose-Druck: zeigt printargs-Werte im Log (kein echtes Drucken)
button .bot.diagprint -text "Diagnose-Druck" -command {
    .log configure -state normal
    .log insert end "\n--- Diagnose-Druck ---\n"
    namespace eval ::tk::print {
        proc _print_canvas_diag {hdc cw} {
            variable printargs
            set ::diaglog "printargs: [array get printargs]\n"
            set sc [$cw cget -scrollregion]
            if {$sc eq ""} {
                set wx [winfo pixels $cw [$cw cget -width]]
                set wy [winfo pixels $cw [$cw cget -height]]
            } else {
                set wx [winfo pixels $cw [lindex $sc 2]]
                set wy [winfo pixels $cw [lindex $sc 3]]
            }
            append ::diaglog "window_x=$wx window_y=$wy\n"
            if {[info exists printargs(pw)] && [info exists printargs(resx)]} {
                set lm [expr {[info exists printargs(lm)] ? $printargs(lm) : "?"}]
                set rm [expr {[info exists printargs(rm)] ? $printargs(rm) : "?"}]
                set tm [expr {[info exists printargs(tm)] ? $printargs(tm) : "?"}]
                set bm [expr {[info exists printargs(bm)] ? $printargs(bm) : "?"}]
                set ph_key [expr {[info exists printargs(ph)] ? "ph" : "pl"}]
                set ph_val [expr {[info exists printargs(ph)] ? $printargs(ph) :                     ([info exists printargs(pl)] ? $printargs(pl) : "?")}]
                set px [expr {($printargs(pw) - $lm - $rm) * $printargs(resx) / 1000.0}]
                set py [expr {($ph_val - $tm - $bm) * $printargs(resy) / 1000.0}]
                append ::diaglog "pw=$printargs(pw) ph_key=$ph_key ph_val=$ph_val\n"
                append ::diaglog "lm=$lm tm=$tm rm=$rm bm=$bm\n"
                append ::diaglog "resx=$printargs(resx) resy=$printargs(resy)\n"
                append ::diaglog "printer_x=$px printer_y=$py\n"
                if {$wx / $px < $wy / $py} {
                    set lo $wy ; set phparam $py
                } else {
                    set lo $wx ; set phparam $px
                }
                append ::diaglog "lo=$lo  physical=$phparam\n"
                append ::diaglog "scale=[expr {$phparam/$lo}]\n"
            }
        }
    }
    namespace eval ::tk::print { rename _print_canvas _print_canvas_orig_diag }
    namespace eval ::tk::print { rename _print_canvas_diag _print_canvas }
    set ::diaglog ""
    catch {tk print .mid.c} err
    namespace eval ::tk::print { rename _print_canvas _print_canvas_diag }
    namespace eval ::tk::print { rename _print_canvas_orig_diag _print_canvas }
    if {$::diaglog ne ""} {
        .log insert end $::diaglog
    } else {
        .log insert end "FEHLER: $err\n"
    }
    .log see end
    .log configure -state disabled
}

button .bot.gdi -text "GDI-Info" -command {
    .log configure -state normal
    .log insert end "\n--- GDI-Info ---\n"
    if {[tk windowingsystem] eq "win32"} {
        catch {package require gdi} v
        .log insert end "gdi: $v\n"
        catch {gdi} msg
        .log insert end "$msg\n"
    } else {
        .log insert end "Nicht Windows\n"
    }
    .log see end
    .log configure -state disabled
}

button .bot.cups -text "CUPS-Info" -command {
    .log configure -state normal
    .log insert end "\n--- CUPS Drucker ---\n"
    if {[catch {
        set printers [::tk::print::cups::getprinters]
        dict for {name opts} $printers {
            .log insert end "  $name\n"
        }
    } err]} {
        .log insert end "FEHLER: $err\n"
    }
    .log see end
    .log configure -state disabled
}

button .bot.clear -text "Log leeren" -command {
    .log configure -state normal
    .log delete 1.0 end
    .log configure -state disabled
}

pack .bot.reload .bot.print .bot.diagprint .bot.gdi .bot.cups .bot.clear \
    -side left -padx 4 -pady 4

# --- Log ---
frame .logf
pack .logf -fill both -expand 1 -padx 4 -pady 4

label .logf.l -text "Log:" -anchor w
pack .logf.l -fill x

text .log -height 8 -font {Courier 9} -wrap none \
    -yscrollcommand {.logs set}
scrollbar .logs -command {.log yview} -orient vertical
pack .logs -side right -fill y
pack .log  -side left  -fill both -expand 1

.log configure -state disabled
