# newtcl8790.tcl -- fehlende Tcl 8.7/9.0 Procs fuer Tcl 8.6
# Stand: 2026-03-26

# ::tk::msgcat -- Shim fuer Tcl 8.6
# print.tcl (Tk 9.0) importiert ::tk::msgcat::* — in Tk 8.6 fehlt dieser Namespace.
# Einfacher Shim: mc gibt den Formatstring unveraendert zurueck.
if {![namespace exists ::tk::msgcat]} {
    namespace eval ::tk::msgcat {
        proc mc {src args} {
            if {[llength $args]} { return [format $src {*}$args] }
            return $src
        }
        namespace export mc
    }
}

# dict getdef -- neu in Tcl 8.7 / 9.0
# https://core.tcl-lang.org/tips/doc/trunk/tip/342.md
proc ::tcl::dict::getdef {D args} {
  if {[dict exists $D {*}[lrange $args 0 end-1]]} then {
    dict get $D {*}[lrange $args 0 end-1]
  } else {
    lindex $args end
  }
}
namespace ensemble configure dict -map \
        [dict merge [namespace ensemble configure dict -map] {getdef ::tcl::dict::getdef}]


# https://wiki.tcl-lang.org/page/lpop
# new in 8.7 and 9.0
# https://core.tcl-lang.org/tips/doc/trunk/tip/523.md
proc lpop {lvar args} {
  upvar $lvar l
  if {![llength $args]} {
    set args [list end]
  }
  set v [lindex $l {*}$args]
  set newlist $l

  set path [list]
  set subl $l
  for {set i 0} {$i < [llength $args]} {incr i} {
    set idx [lindex $args $i]
    #inlined list_index_get test
    if {![llength [lrange $subl $idx $idx]]} {
      error "index \"$idx\" out of range"
    }
    #See list_index_resolve/list_index_get below for explanation
    #if {[list_index_resolve $subl $idx] == -1} {
    #    error "tcl_lpop index \"$idx\" out of range"
    #}
    lappend path [lindex $args $i]
    set subl [lindex $l {*}$path]
  }

  set sublist_path [lrange $args 0 end-1]
  set tailidx [lindex $args end]
  if {![llength $sublist_path]} {
    set newlist [lreplace $newlist $tailidx $tailidx]
  } else {
    set sublist [lindex $newlist {*}$sublist_path]
    set sublist [lreplace $sublist $tailidx $tailidx]
    lset newlist {*}$sublist_path $sublist
  }
  #puts "[set l]  -> $newlist" ;#we can do without the newlist variable - but it's here to enable easier debug/verification that we are duplicating builtin lpop
  set l $newlist
  return $v
}

