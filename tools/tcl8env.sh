#!/bin/sh
# tcl8env.sh -- Tcl 8.6 Umgebung fuer tkprintcompat
#
# Aufruf:
#   . tools/tcl8env.sh
#
# Danach:
#   tclsh test/test-unit.tcl
#   tclsh test/test-basic.tcl
#   wish test/test-print.tcl -printer "PDF24"

HOME_DIR="${HOME:-$(getent passwd "$USER" | cut -d: -f6)}"

export TCLSH=tclsh8.6

export TCLLIBPATH="$HOME_DIR/lib/tcl8.6 $HOME_DIR/lib/tcltk ${TCLLIBPATH:-}"

echo "=== Tcl 8.6 Umgebung aktiv ==="
echo "TCLSH=$TCLSH"
echo "TCLLIBPATH=$TCLLIBPATH"
echo "Tcl version: $(tclsh8.6 <<< 'puts [info patchlevel]' 2>/dev/null)"
echo ""
echo "Tests:"
echo "  tclsh test/test-basic.tcl"
echo "  tclsh test/test-unit.tcl"
echo "  wish  test/test-print.tcl -printer \"PDF24\""
echo ""
echo "Build:"
echo "  tclsh build.tcl"
echo "  make install"
echo "  -> $HOME_DIR/lib/tcl8.6/site-tcl/"
