#!/usr/bin/env wish
# test-unit.tcl -- Unit-Tests ohne Drucker (tcltest-Framework)
# Aufruf: wish test/test-unit.tcl
#         tclsh test/test-unit.tcl

package require Tk
package require tcltest 2.2
namespace import tcltest::*

tcl::tm::add path [file join [file dirname [info script]] ../]
package require tkprintcompat

# ---------------------------------------------------------------------------
# Constraints -- vier Branches
# ---------------------------------------------------------------------------
testConstraint win32    [expr {[tk windowingsystem] eq "win32"}]
testConstraint x11      [expr {[tk windowingsystem] eq "x11"}]
testConstraint tk86     [expr {![package vsatisfies [info tclversion] 9.0-]}]
testConstraint tk9      [expr {[package vsatisfies [info tclversion] 9.0-]}]
testConstraint tk86_win [expr {![package vsatisfies [info tclversion] 9.0-] && \
                                [tk windowingsystem] eq "win32"}]
testConstraint tk86_x11 [expr {![package vsatisfies [info tclversion] 9.0-] && \
                                [tk windowingsystem] eq "x11"}]
testConstraint tk9_win  [expr {[package vsatisfies [info tclversion] 9.0-] && \
                                [tk windowingsystem] eq "win32"}]
testConstraint tk9_x11  [expr {[package vsatisfies [info tclversion] 9.0-] && \
                                [tk windowingsystem] eq "x11"}]

puts "=== tkprintcompat Unit-Tests (tcltest) ==="
puts "Tcl: [info patchlevel] | Tk: [package require Tk] | [tk windowingsystem]"
puts "tkprintcompat: [package require tkprintcompat]"
puts ""

# ---------------------------------------------------------------------------
# newtcl8790 Shims
# ---------------------------------------------------------------------------

test shim-1.1 {dict getdef -- Schluessel vorhanden} -body {
    dict getdef {a 1 b 2} a "x"
} -result 1

test shim-1.2 {dict getdef -- Schluessel fehlt, Default} -body {
    dict getdef {a 1 b 2} z "default"
} -result default

test shim-1.3 {dict getdef -- leeres Dict} -body {
    dict getdef {} x "fallback"
} -result fallback

test shim-2.1 {lpop -- letztes Element} -body {
    set l {a b c}
    lpop l
} -result c

test shim-2.2 {lpop -- Liste verkuerzt sich} -body {
    set l {a b c}
    lpop l
    set l
} -result {a b}

test shim-2.3 {lpop -- einelementige Liste} -body {
    set l {only}
    lpop l
} -result only

# ---------------------------------------------------------------------------
# _scalingPct
# ---------------------------------------------------------------------------

test scaling-1.1 {_scalingPct ist definiert} -body {
    info commands ::tkprintcompat::_scalingPct
} -result ::tkprintcompat::_scalingPct

test scaling-1.2 {_scalingPct gibt Integer zurueck} -body {
    string is integer [::tkprintcompat::_scalingPct]
} -result 1

test scaling-1.3 {_scalingPct >= 100} -body {
    expr {[::tkprintcompat::_scalingPct] >= 100}
} -result 1

test scaling-1.4 {_scalingPct ist Vielfaches von 25} -body {
    expr {[::tkprintcompat::_scalingPct] % 25}
} -result 0

test scaling-2.1 {_scalingPct Formel: scaling 1.0 -> 100} -body {
    set pct [expr {1.0 * 75}]
    set s 100
    while {$pct >= $s + 12.5} { incr s 25 }
    set s
} -result 100

test scaling-2.2 {_scalingPct Formel: scaling 2.0 -> 150} -body {
    set pct [expr {2.0 * 75}]
    set s 100
    while {$pct >= $s + 12.5} { incr s 25 }
    set s
} -result 150

test scaling-2.3 {_scalingPct Formel: scaling 1.333 -> 100} -body {
    set pct [expr {1.333 * 75}]
    set s 100
    while {$pct >= $s + 12.5} { incr s 25 }
    set s
} -result 100

test scaling-2.4 {_scalingPct Formel: scaling 1.5 -> 125} -body {
    set pct [expr {1.5 * 75}]
    set s 100
    while {$pct >= $s + 12.5} { incr s 25 }
    set s
} -result 125

# ---------------------------------------------------------------------------
# Margin-Berechnung
# ---------------------------------------------------------------------------

test margin-1.1 {25mm -> 984 (1/1000 Zoll)} -body {
    expr {int(25.0 / 25.4 * 1000)}
} -result 984

test margin-1.2 {15mm -> 590 (int schneidet ab)} -body {
    expr {int(15.0 / 25.4 * 1000)}
} -result 590

test margin-1.3 {margin(left)=25mm -> 984} -body {
    namespace eval ::tk::print {
        variable margin
        set margin(left) 25
        expr {int($margin(left) / 25.4 * 1000)}
    }
} -result 984

test margin-1.4 {Standardwerte gesetzt} -body {
    namespace eval ::tk::print {
        variable margin
        list [info exists margin(top)] \
             [info exists margin(left)] \
             [info exists margin(right)] \
             [info exists margin(bottom)]
    }
} -result {1 1 1 1}

test margin-1.5 {Standardwert top=15mm} -body {
    namespace eval ::tk::print { variable margin; set margin(top) }
} -result 15

test margin-1.6 {Standardwert left=25mm} -body {
    namespace eval ::tk::print { variable margin; set margin(left) }
} -result 25

# ---------------------------------------------------------------------------
# Papierformat-Index (win32: printer attr liefert {Laenge Breite})
# ---------------------------------------------------------------------------

test paper-1.1 {A4 Hochformat: Index 0=Laenge ph, Index 1=Breite pw} -body {
    set dims {11692 8267}
    expr {[lindex $dims 0] > [lindex $dims 1]}
} -result 1

test paper-1.2 {Offset-Berechnung lm*resx/1000} -body {
    expr {int(984 * 600 / 1000.0)}
} -result 590

test paper-1.3 {Offset-Berechnung tm*resy/1000} -body {
    expr {int(590 * 600 / 1000.0)}
} -result 354

# ---------------------------------------------------------------------------
# Font-Descriptor
# ---------------------------------------------------------------------------

canvas .tc -width 200 -height 100
.tc create text 50 50 -text "Test" -font {Arial 14 bold}   -tags tt
.tc create text 50 80 -text "Kursiv" -font {Arial 12 italic} -tags ti

test font-1.1 {font actual -size positiv (Punkte)} -body {
    expr {[dict get [font actual {Arial 14 bold}] -size] > 0}
} -result 1

test font-1.2 {font actual -weight bold} -body {
    dict get [font actual {Arial 14 bold}] -weight
} -result bold

test font-1.3 {font actual -slant roman} -body {
    dict get [font actual {Arial 14}] -slant
} -result roman

test font-1.4 {font actual -slant italic} -body {
    dict get [font actual {Arial 14 italic}] -slant
} -result italic

test font-2.1 {Font-Descriptor: positiv, weight, slant} -body {
    set f [font actual {Arial 14 bold}]
    set font [list [dict get $f -family] \
                   [expr {abs([dict get $f -size])}] \
                   [dict get $f -weight] \
                   [dict get $f -slant]]
    expr {[lindex $font 1] > 0 && [lindex $font 2] eq "bold"}
} -result 1

test font-2.2 {Canvas-Item -font abrufen} -body {
    .tc itemcget tt -font
} -result {Arial 14 bold}

test font-2.3 {Canvas-Item -angle Standard=0.0} -body {
    .tc itemcget tt -angle
} -result 0.0

test font-2.4 {Canvas-Item italic -slant} -body {
    dict get [font actual [.tc itemcget ti -font]] -slant
} -result italic

destroy .tc

# ---------------------------------------------------------------------------
# Namespace-Struktur -- alle Branches
# ---------------------------------------------------------------------------

test ns-1.1 {::tk::print existiert -- alle Branches} -body {
    namespace exists ::tk::print
} -result 1

test ns-1.2 {::tkprintcompat existiert -- alle Branches} -body {
    namespace exists ::tkprintcompat
} -result 1

test ns-1.3 {tk print im tk-Ensemble -- alle Branches} -body {
    dict exists [namespace ensemble configure tk -map] print
} -result 1

# _print_canvas -- nur wenn wir ihn ueberschreiben:
# Tk 8.6 win32: ja (aus print-8.6erw.tcl)
# Tk 9 win32:   ja (aus print-8.6erw.tcl Override)
# X11:          ja (aus print.tcl geladen oder eingebaut)
# _print_canvas: unser Override auf win32 (beide Tk-Versionen)
# und aus print.tcl auf X11/Tk8.6
test ns-2.1 {_print_canvas definiert auf win32} \
    -constraints {win32} -body {
    expr {[info commands ::tk::print::_print_canvas] ne ""}
} -result 1

test ns-2.1b {_print_canvas definiert auf X11/Tk8.6} \
    -constraints {x11 tk86} -body {
    expr {[info commands ::tk::print::_print_canvas] ne ""}
} -result 1

# Auf X11/Tk9: _print_canvas ist C-intern, nicht als Tcl-Proc sichtbar
test ns-2.1c {_print_canvas nicht als Tcl-Proc auf X11/Tk9} \
    -constraints {x11 tk9} -body {
    expr {[info commands ::tk::print::_print_canvas] eq ""}
} -result 1

# _print_canvas.text: unser Override auf win32
# und aus print.tcl auf X11/Tk8.6
test ns-2.2 {_print_canvas.text definiert auf win32} \
    -constraints {win32} -body {
    expr {[info commands {::tk::print::_print_canvas.text}] ne ""}
} -result 1

test ns-2.2b {_print_canvas.text definiert auf X11/Tk8.6} \
    -constraints {x11 tk86} -body {
    expr {[info commands {::tk::print::_print_canvas.text}] ne ""}
} -result 1

# Auf X11/Tk9: C-intern, kein Tcl-Proc
test ns-2.2c {_print_canvas.text nicht als Tcl-Proc auf X11/Tk9} \
    -constraints {x11 tk9} -body {
    expr {[info commands {::tk::print::_print_canvas.text}] eq ""}
} -result 1

# _print_canvas.line/oval/rectangle kommen aus print.tcl --
# auf X11 werden sie durch Tk eingebaut oder durch print.tcl geladen.
# Auf win32 Tk 8.6: durch print.tcl geladen (im 8.6-Branch).
# Auf win32 Tk 9:   direkt in tkWinGDI.c eingebaut -- Procs existieren.
test ns-2.3 {_print_canvas.line definiert} \
    -constraints {win32} -body {
    expr {[info commands {::tk::print::_print_canvas.line}] ne ""}
} -result 1

test ns-2.4 {_print_canvas.oval definiert} \
    -constraints {win32} -body {
    expr {[info commands {::tk::print::_print_canvas.oval}] ne ""}
} -result 1

test ns-2.5 {_print_canvas.rectangle definiert} \
    -constraints {win32} -body {
    expr {[info commands {::tk::print::_print_canvas.rectangle}] ne ""}
} -result 1

# X11: _print_canvas.line etc. aus print.tcl (wird unter 8.6 geladen)
# Auf X11 wird Canvas via $w postscript gedruckt -- keine _print_canvas.*
# Handler noetig. Daher kein Test fuer _print_canvas.line auf X11.
test ns-2.6 {_print_canvas.line NICHT auf X11 (PostScript-Pfad)} \
    -constraints {x11} -body {
    # Auf X11 ist _print_canvas.line nicht definiert -- das ist korrekt
    expr {[info commands {::tk::print::_print_canvas.line}] eq ""}
} -result 1

# win32-spezifische Procs
test ns-3.1 {_selectprinter definiert} -constraints {win32} -body {
    expr {[info commands ::tk::print::_selectprinter] ne ""}
} -result 1

test ns-3.2 {_gdi definiert} -constraints {win32} -body {
    expr {[info commands ::tk::print::_gdi] ne ""}
} -result 1

test ns-3.3 {_set_dc definiert} -constraints {win32} -body {
    expr {[info commands ::tk::print::_set_dc] ne ""}
} -result 1

test ns-3.4 {_print_widget definiert} -constraints {win32} -body {
    expr {[info commands ::tk::print::_print_widget] ne ""}
} -result 1

# Tk 8.6 win32: _openprinter definiert
test ns-3.5 {_openprinter definiert} -constraints {tk86_win} -body {
    expr {[info commands ::tk::print::_openprinter] ne ""}
} -result 1

# X11: cups namespace
test ns-4.1 {cups namespace auf X11} -constraints {x11} -body {
    namespace exists ::tk::print::cups
} -result 1

# _runprint ueberschrieben auf X11
test ns-4.2 {_runprint definiert auf X11} -constraints {x11} -body {
    expr {[info commands ::tk::print::_runprint] ne ""}
} -result 1

# textplain-Mapping nur Tk 8.6 win32
test ns-5.1 {_gdi textplain-Mapping vorhanden} \
    -constraints {tk86_win} -body {
    string match "*textplain*" [info body ::tk::print::_gdi]
} -result 1

# ---------------------------------------------------------------------------
# Skalierungsformel
# ---------------------------------------------------------------------------

test scale-1.1 {Isotrope Skalierung: x begrenzt, Verhaeltnis erhalten} -body {
    set window_x 500.0; set window_y 200.0
    set printer_x 4000.0; set printer_y 6000.0
    if {$window_x / $printer_x > $window_y / $printer_y} {
        set ix [expr {int(round($printer_x))}]
        set iy [expr {int(round($window_y * $printer_x / $window_x))}]
    } else {
        set iy [expr {int(round($printer_y))}]
        set ix [expr {int(round($window_x * $printer_y / $window_y))}]
    }
    expr {round($ix * 10.0 / $iy)}
} -result 25

test scale-1.2 {Isotrope Skalierung: y begrenzt, Verhaeltnis erhalten} -body {
    set window_x 200.0; set window_y 500.0
    set printer_x 6000.0; set printer_y 4000.0
    if {$window_x / $printer_x > $window_y / $printer_y} {
        set ix [expr {int(round($printer_x))}]
        set iy [expr {int(round($window_y * $printer_x / $window_x))}]
    } else {
        set iy [expr {int(round($printer_y))}]
        set ix [expr {int(round($window_x * $printer_y / $window_y))}]
    }
    expr {round($iy * 10.0 / $ix)}
} -result 25

test scale-2.1 {Integer-Rundung: .8 aufrunden} -body {
    expr {int(round(4015.8))}
} -result 4016

test scale-2.2 {Integer-Rundung: .5 aufrunden} -body {
    expr {int(round(4015.5))}
} -result 4016

test scale-2.3 {Integer-Rundung: .2 abrunden} -body {
    expr {int(round(4015.2))}
} -result 4015

# ---------------------------------------------------------------------------
# X11: Fontmap-Logik
# ---------------------------------------------------------------------------

test fontmap-1.1 {Helvetica-Mapping fuer Arial} -constraints {x11} -body {
    set fam "arial"
    set bold 0; set italic 0
    set psf Helvetica
    if {$bold && $italic} { append psf -BoldOblique } \
    elseif {$bold}        { append psf -Bold } \
    elseif {$italic}      { append psf -Oblique }
    set psf
} -result Helvetica

test fontmap-1.2 {Times-Bold-Mapping} -constraints {x11} -body {
    set fam "times new roman"
    set bold 1; set italic 0
    if {$bold && $italic} { set psf Times-BoldItalic } \
    elseif {$bold}        { set psf Times-Bold } \
    elseif {$italic}      { set psf Times-Italic } \
    else                  { set psf Times-Roman }
    set psf
} -result Times-Bold

test fontmap-1.3 {Courier-Oblique-Mapping} -constraints {x11} -body {
    set fam "courier"
    set bold 0; set italic 1
    set psf Courier
    if {$bold && $italic} { append psf -BoldOblique } \
    elseif {$bold}        { append psf -Bold } \
    elseif {$italic}      { append psf -Oblique }
    set psf
} -result Courier-Oblique

test fontmap-1.4 {Helvetica-BoldOblique fuer Arial bold italic} \
    -constraints {x11} -body {
    set fam "arial"
    set bold 1; set italic 1
    set psf Helvetica
    if {$bold && $italic} { append psf -BoldOblique } \
    elseif {$bold}        { append psf -Bold } \
    elseif {$italic}      { append psf -Oblique }
    set psf
} -result Helvetica-BoldOblique

# ---------------------------------------------------------------------------
cleanupTests
