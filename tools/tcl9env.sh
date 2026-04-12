#!/bin/sh
# tcl9env.sh -- Tcl 9.0 Umgebung fuer tkprintcompat
#
# Aufruf:
#   . tools/tcl9env.sh
#
# Danach:
#   tclsh9.0 test/test-unit.tcl
#   tclsh9.0 test/test-basic.tcl
#   wish9.0  test/test-print.tcl -printer "PDF24"

HOME_DIR="${HOME:-$(getent passwd "$USER" | cut -d: -f6)}"

export TCLSH=tclsh9.0

export TCLLIBPATH="$HOME_DIR/lib/tcl9.0 $HOME_DIR/lib/tcltk ${TCLLIBPATH:-}"

echo "=== Tcl 9.0 Umgebung aktiv ==="
echo "TCLSH=$TCLSH"
echo "TCLLIBPATH=$TCLLIBPATH"
echo "Tcl version: $(tclsh9.0 <<< 'puts [info patchlevel]' 2>/dev/null)"
echo ""
echo "Tests:"
echo "  tclsh9.0 test/test-basic.tcl"
echo "  tclsh9.0 test/test-unit.tcl"
echo "  wish9.0  test/test-print.tcl -printer \"PDF24\""
echo ""
echo "Build:"
echo "  tclsh9.0 build.tcl"
echo "  make install90"
echo "  -> $HOME_DIR/lib/tcl9.0/site-tcl/"
