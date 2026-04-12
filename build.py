#!/usr/bin/env python3
# build.py -- tkprintcompat .tm bauen

import datetime

VERSION = "0.2"
TARGET  = f"tkprintcompat-{VERSION}.tm"

with open('src/newtcl8790.tcl', encoding='utf-8') as f:
    newtcl = f.read()

with open('src/print.tcl', encoding='utf-8') as f:
    printtcl = f.read()

# \f\nreturn entfernen
printtcl = printtcl.replace('\x0c\nreturn\n', '\n# <return entfernt>\n')

with open('src/print-8.6erw.tcl', encoding='utf-8') as f:
    erw = f.read()

# print.tcl nur unter Tcl 8.6 ausfuehren -- unter Tcl 9 ist tk print eingebaut
# und wir wuerden die Tk-9-Implementierung ueberschreiben
print_wrapped = (
    "# print.tcl nur unter Tcl 8.6 laden\n"
    "# Unter Tcl 9 ist tk print eingebaut -- print.tcl wuerde es ueberschreiben\n"
    "if {![package vsatisfies [info tclversion] 9.0-]} {\n\n"
    + printtcl +
    "\n}\n"
)

header = f"""# tkprintcompat-{VERSION}.tm -- Tk print Kompatibilitaets-Bibliothek
# Automatisch generiert durch build.py aus:
#   src/newtcl8790.tcl   -- ::tk::msgcat Shim + fehlende Tcl 8.7/9 Procs
#   src/print.tcl        -- Tk 9.0 library/print.tcl (nur unter Tcl 8.6 geladen)
#   src/print-8.6erw.tcl -- Wrapper + Fixes + package provide
#
# Unter Tcl 9.0: tk print eingebaut, nur Fixes fuer Windows angewandt.
# Unter Tcl 8.6 Linux:   CUPS via ::tk::print::cups
# Unter Tcl 8.6 Windows: printer + gdi (Michael I. Schwartz)
#
# Build: {datetime.date.today()}
# print.tcl Quelle: Tk 9.0 library/print.tcl

"""

with open(TARGET, 'w', encoding='utf-8') as f:
    f.write(header + newtcl + '\n' + print_wrapped + '\n' + erw)

lines = sum(1 for _ in open(TARGET))
print(f"OK: {TARGET} ({lines} Zeilen)")
