#!/usr/bin/env tclsh
# build.tcl -- tkprintcompat .tm bauen
# Reines Tcl, keine externen Pakete noetig.
# Aufruf: tclsh build.tcl

set VERSION "0.2"
set TARGET  "tkprintcompat-${VERSION}.tm"
set srcdir  [file join [file dirname [info script]] src]

# Datei lesen
proc readfile {path} {
    set fd [open $path r]
    fconfigure $fd -encoding utf-8
    set data [read $fd]
    close $fd
    return $data
}

# Datei schreiben
proc writefile {path data} {
    set fd [open $path w]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd $data
    close $fd
}

# Quelldateien lesen
set newtcl   [readfile [file join $srcdir newtcl8790.tcl]]
set printtcl [readfile [file join $srcdir print.tcl]]
set erw      [readfile [file join $srcdir print-8.6erw.tcl]]

# \f\nreturn\n aus print.tcl entfernen
# Tk-internes return wuerde alle nachfolgenden Fixes abbrechen
set marker "\f\nreturn\n"
if {[string first $marker $printtcl] >= 0} {
    set printtcl [string map [list $marker "\n# <return entfernt>\n"] $printtcl]
} else {
    puts stderr "WARNUNG: '\\f\\nreturn\\n' nicht in print.tcl gefunden!"
    puts stderr "         Bitte pruefen ob print.tcl aktuell ist."
}

# print.tcl nur unter Tcl 8.6 laden
set print_wrapped \
"# print.tcl nur unter Tcl 8.6 laden\n\
# Unter Tcl 9 ist tk print eingebaut -- print.tcl wuerde es ueberschreiben\n\
if \{!\[package vsatisfies \[info tclversion\] 9.0-\]\} \{\n\n\
${printtcl}\n\}\n"

# Header
set datum [clock format [clock seconds] -format "%Y-%m-%d"]
set header \
"# tkprintcompat-${VERSION}.tm -- Tk print Kompatibilitaets-Bibliothek\n\
# Automatisch generiert durch build.tcl aus:\n\
#   src/newtcl8790.tcl   -- ::tk::msgcat Shim + fehlende Tcl 8.7/9 Procs\n\
#   src/print.tcl        -- Tk 9.0.3 library/print.tcl (nur unter Tcl 8.6 geladen)\n\
#   src/print-8.6erw.tcl -- Wrapper + Fixes + package provide\n\
#\n\
# Unter Tcl 9.0.3+: tk print eingebaut, nur Fixes fuer Windows angewandt.\n\
# Unter Tcl 8.6 Linux:   CUPS via ::tk::print::cups\n\
# Unter Tcl 8.6 Windows: printer + gdi (Michael I. Schwartz)\n\
#\n\
# Build: $datum\n\
# print.tcl Quelle: Tk 9.0.3 (BAWT 3.2.0)\n\n"

# Zusammenbauen
set content $header
append content $newtcl "\n"
append content $print_wrapped "\n"
append content $erw

writefile $TARGET $content

set lines [llength [split $content \n]]
puts "OK: $TARGET ($lines Zeilen)"
