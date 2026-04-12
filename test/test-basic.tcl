#!/usr/bin/env wish
# test-basic.tcl -- Grundlegende Tests fuer tkprintcompat (tcltest)
# Aufruf: tclsh test/test-basic.tcl

package require Tk
package require tcltest 2.2
namespace import tcltest::*

tcl::tm::add path [file join [file dirname [info script]] ../]

testConstraint win32   [expr {[tk windowingsystem] eq "win32"}]
testConstraint notWin32 [expr {[tk windowingsystem] ne "win32"}]

puts "=== tkprintcompat Basic-Tests ==="
puts "Tcl: [info patchlevel] | Tk: [package require Tk] | [tk windowingsystem]"

test basic-1.1 {package laden} -body {
    package require tkprintcompat
    package present tkprintcompat
} -result 0.2

test basic-2.1 {dict getdef vorhanden} -body {
    dict getdef {a 1} a "x"
} -result 1

test basic-2.2 {dict getdef Standardwert} -body {
    dict getdef {a 1} z "default"
} -result default

test basic-3.1 {lpop vorhanden} -body {
    set l {a b c}
    lpop l
} -result c

test basic-4.1 {tk print definiert} -body {
    dict exists [namespace ensemble configure tk -map] print
} -result 1

test basic-5.1 {cups namespace auf X11} -constraints notWin32 -body {
    namespace exists ::tk::print::cups
} -result 1

cleanupTests
