#!/usr/bin/env wish
# WICHTIG: Mit wish ausfuehren, nicht tclsh!
# tclsh hat kein Fenster -> hDC=0x0 -> Druckfehler
#   RICHTIG: wish test/test-print.tcl
#   FALSCH:  tclsh test/test-print.tcl
# test-print.tcl -- Drucktests mit PDF-Drucker
# Aufruf: wish test/test-print.tcl ?-printer "PDF24"?
# WICHTIG: wish (nicht tclsh) -- braucht Tk-Display fuer Druckdialog
#
# Benoetigt einen PDF-Drucker (PDF24, "Microsoft Print to PDF" etc.)
# Druckt auf den angegebenen Drucker und prueft ob kein Fehler auftritt.
# Das erzeugte PDF muss manuell visuell geprueft werden.

package require Tk

# Sicherstellen dass ein Fenster vorhanden ist (wish, nicht tclsh).
# Ohne sichtbares Fenster: hDC=0x0 -> Canvas wird nicht gedruckt.
if {[tk windowingsystem] eq "win32"} {
    # Dummy-Fenster erzwingen damit GDI DC verfuegbar ist
    wm withdraw .
    update
}

tcl::tm::add path [file join [file dirname [info script]] ../]
package require tkprintcompat

set ok   0
set fail 0
set skip 0

# Drucker aus Kommandozeile lesen
set testprinter ""
for {set i 0} {$i < [llength $argv]} {incr i} {
    if {[lindex $argv $i] eq "-printer"} {
        set testprinter [lindex $argv [expr {$i+1}]]
    }
}

proc test {name body expected} {
    set rc [catch {uplevel 1 $body} result]
    if {$rc != 0} {
        # Echte Tcl-Exception
        puts "FAIL $name"
        puts "     EXCEPTION: $result"
        incr ::fail
    } elseif {$expected eq "*" || $result eq $expected} {
        puts "OK   $name"
        incr ::ok
    } else {
        puts "FAIL $name"
        puts "     erwartet: [list $expected]"
        puts "     erhalten: [list $result]"
        incr ::fail
    }
}

proc skip {name reason} {
    puts "SKIP $name ($reason)"
    incr ::skip
}

proc section {title} {
    puts ""
    puts "--- $title ---"
}

# Hilfsproc: Canvas mit Standard-Inhalt erstellen
proc make_test_canvas {w} {
    canvas $w -width 500 -height 200 -background white \
        -scrollregion {0 0 500 200}
    $w create text   50  30 -text "tkprintcompat Test" \
        -font {Arial 16 bold} -anchor w
    $w create line   50  50 450  50 -width 2
    $w create rect   50  70 450 160 -outline black -fill lightyellow
    $w create text   60  90 -text "Normal Text" -anchor w
    $w create text   60 115 -text "Fett Bold" \
        -font {Arial 11 bold} -anchor w
    $w create text   60 140 -text "\u00c4 \u00d6 \u00dc \u00e4 \u00f6 \u00fc \u00df \u20ac" \
        -anchor w -fill darkgreen
    $w create oval  300  80 420 150 -fill lightblue -outline navy
    pack $w
    # update: Widget muss sichtbar sein damit winfo pixels korrekte Werte liefert
    update idletasks
}

puts "=== tkprintcompat Drucktests ==="
puts "Tcl: [info patchlevel] | Tk: [package require Tk] | [tk windowingsystem]"
puts "tkprintcompat: [package require tkprintcompat]"
puts ""

if {[tk windowingsystem] ne "win32"} {
    puts "INFO: Drucktests nur auf win32 sinnvoll."
    puts "      Auf Linux/macOS: 'lp' oder CUPS direkt."
    puts ""
}

# ---------------------------------------------------------------------------
section "Druckerliste (win32)"
# ---------------------------------------------------------------------------

if {[tk windowingsystem] eq "win32"} {
    test "printer list liefert Liste" {
        package require printer
        set pl [printer list]
        expr {[llength $pl] >= 0}
    } "1"

    test "printer list nicht leer" {
        package require printer
        expr {[llength [printer list]] > 0}
    } "1"

    if {$testprinter eq ""} {
        # Ersten verfuegbaren Drucker nehmen
        catch {
            package require printer
            set testprinter [lindex [printer list] 0]
        }
        if {$testprinter ne ""} {
            puts "INFO: Verwende Drucker: $testprinter"
        }
    }
} else {
    skip "printer list" "nicht win32"
}

# ---------------------------------------------------------------------------
section "Canvas drucken (tk print)"
# ---------------------------------------------------------------------------

make_test_canvas .testcanvas

test "tk print Canvas -- kein unerwarteter Fehler" {
    # Rückgabewert ignorieren (kann Seitenanzahl o.ae. sein).
    # Nur echte Tcl-Exception zaehlt als FAIL.
    tk print .testcanvas
    set "ok"
} "*"

destroy .testcanvas

# ---------------------------------------------------------------------------
section "Canvas stiller Druck (ohne Dialog)"
# ---------------------------------------------------------------------------

if {[tk windowingsystem] eq "win32" && $testprinter ne ""} {
    make_test_canvas .testcanvas2

    test "Stiller Druck -- _openprinter" {
        package require printer
        set hDC [printer open -name $::testprinter]
        set pname [lindex $hDC 0]
        printer close
        expr {$pname ne ""}
    } "1"

    destroy .testcanvas2
} else {
    skip "Stiller Druck" \
        [expr {[tk windowingsystem] ne "win32" ? "nicht win32" : "kein Drucker angegeben (-printer NAME)"}]
}

# ---------------------------------------------------------------------------
section "Text-Widget drucken"
# ---------------------------------------------------------------------------

text .testtext -wrap word -font {Courier 11}
.testtext insert end "Zeile 1: Normaler Text\n"
.testtext insert end "Zeile 2: \u00c4\u00d6\u00dc \u00e4\u00f6\u00fc \u00df\n"
.testtext insert end "Zeile 3: Test 1234567890\n"
pack .testtext

test "tk print Text -- kein unerwarteter Fehler" {
    tk print .testtext
    # update: after idle aus _runprint abarbeiten bevor destroy
    update
    set "ok"
} "*"

# Widget erst nach update zerstoeren
update
destroy .testtext

# ---------------------------------------------------------------------------
puts ""
puts "=== Ergebnis: $ok OK, $fail FAIL, $skip SKIP ==="
puts ""
puts "Hinweis: Visuelle Pruefung des Ausdrucks erforderlich."
puts "  - Schrift korrekt (Normal, Bold, Kursiv)?"
puts "  - Umlaute sichtbar?"
puts "  - Oval proportional?"
puts "  - Groesse gleich bei Tcl 8.6 und 9.0.3?"
if {$fail > 0} { exit 1 }
