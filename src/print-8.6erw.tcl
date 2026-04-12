# print-8.6erw.tcl
# Wrapper: macht print.tcl (aus Tk 9.0) lauffaehig unter Tcl/Tk 8.6
#
# Version: 0.7
# Stand:   2026-03-28
#
# Dateistruktur:
#   tkprintcompat-0.2.tm  -- newtcl8790.tcl + print.tcl (8.6-only) + dieser Wrapper
#   src/print.tcl         -- Tk 9.0.3 library/print.tcl (unveraendert)
#   src/print-8.6erw.tcl  -- diese Datei

# ---------------------------------------------------------------------------
# Skalierungskorrektur -- VOR dem Versionscheck definieren
# ---------------------------------------------------------------------------
# Muss frueher stehen als jeder Versionscheck, damit _scalingPct in
# Tcl 8.6 und Tcl 9.x gleichermassen verfuegbar ist.
#
# _scalingPct --
#   Ermittelt den Display-Skalierungsprozentsatz.
#   Formel nach Csaba Nemethi (scaleutil): tk scaling * 75,
#   gerundet auf das naechste Vielfache von 25 (mind. 100).
#   Tk 9: ::tk::scalingPct direkt verfuegbar.
namespace eval ::tkprintcompat {
    proc _scalingPct {} {
        if {[info exists ::tk::scalingPct]} {
            return $::tk::scalingPct
        }
        set pct [expr {[tk scaling] * 75}]
        for {set s 100} {1} {incr s 25} {
            if {$pct < $s + 12.5} { return $s }
        }
    }
}

# ---------------------------------------------------------------------------
# Tk 9.x: nur Bugfixes -- print.tcl nicht neu laden
# ---------------------------------------------------------------------------
# Unter Tcl 9 ist tk print eingebaut. print.tcl darf nicht ueberschrieben
# werden. Nur bekannte Bugs werden gepatcht.
#
# Strategie fuer Scaling-Fix:
#   _print_widget NICHT ueberschreiben (Signatur aendert sich zwischen Releases).
#   Stattdessen _print_canvas wrappen -- stabile Signatur {hdc cw} in allen
#   Tk-9.x-Versionen. _print_widget ruft _print_canvas auf; dort wird
#   _gdi map mit korrigierten Werten neu gesetzt.

if {[package vsatisfies [info tclversion] 9.0-]} {
    if {[tk windowingsystem] eq "win32"} {
        namespace eval ::tk::print {

            # Fix 1: _print_canvas.text -- Font-Descriptor vereinfacht.
            # Tk 9 _make_gdi_cfont erzeugt "Arial -21 bold roman" --
            # gdi text gibt rc=0 err=1 zurueck (kein sichtbarer Text).
            # Fix: nur {family -size}, Breite aus bbox statt winfo pixels.
            proc _print_canvas.text {hdc cw id} {
                set txt [$cw itemcget $id -text]
                if {$txt eq ""} return
                set color [_print_canvas.TransColor [$cw itemcget $id -fill]]
                set coords [$cw coords $id]
                set anchr  [$cw itemcget $id -anchor]
                set just   [$cw itemcget $id -justify]
                set f    [font actual [$cw itemcget $id -font]]
                # Font: Familie, Groesse (positiv=Punkte), Stil-Worte.
                # gdi.c GdiParseFontWords verarbeitet bold/italic/roman korrekt.
                # Negative Groesse wuerde den Stil-Parser ueberspringen.
                set font [list [dict get $f -family]                                [expr {abs([dict get $f -size])}]                                [dict get $f -weight]                                [dict get $f -slant]]
                # -width weglassen: width=0 -> DT_WORDBREAK -> Text unsichtbar.
                # Tk 9 GdiText (tkWinGDI.c) kennt kein -unicode -- nicht noetig,
                # da Tcl_UtfToWCharDString intern immer verwendet wird.
                _gdi text $hdc {*}$coords \
                    -fill $color -text $txt -font $font \
                    -anchor $anchr -justify $just
            }

            # Fix 2: _print_canvas -- Scaling-Korrektur (Nemethi-Methode).
            #
            # _print_widget berechnet window_x/y mit winfo pixels (logische
            # Pixel, skaliert mit tk scaling) und setzt _gdi map entsprechend.
            # Bei HiDPI (125%, 150%) wird der Canvas dadurch zu klein gedruckt.
            #
            # Loesung: _print_canvas neu setzen. Es wird als erstes _gdi map
            # mit skalierungskorrigierten Werten (physische Pixel) aufgerufen,
            # danach alle Canvas-Items gezeichnet.
            # Signatur {hdc cw} ist in allen Tk-9.x-Versionen stabil.
            proc _print_canvas {hdc cw} {
                variable printargs
                variable vtgPrint

                # Canvas-Groesse skalierungskorrigiert berechnen.
                # winfo pixels gibt logische Pixel zurueck.
                # physisch = logisch * 100 / scalingPct
                set pct [::tkprintcompat::_scalingPct]

                set sc [$cw cget -scrollregion]
                if {$sc eq ""} {
                    set window_x [winfo pixels $cw [$cw cget -width]]
                    set window_y [winfo pixels $cw [$cw cget -height]]
                } else {
                    set window_x [winfo pixels $cw [lindex $sc 2]]
                    set window_y [winfo pixels $cw [lindex $sc 3]]
                }
                set window_x [expr {int($window_x * 100.0 / $pct)}]
                set window_y [expr {int($window_y * 100.0 / $pct)}]

                set printer_x [expr {
                    ($printargs(pw) - $printargs(lm) - $printargs(rm)) *
                    $printargs(resx) / 1000.0
                }]
                set printer_y [expr {
                    ($printargs(ph) - $printargs(tm) - $printargs(bm)) *
                    $printargs(resy) / 1000.0
                }]

                # MM_ISOTROPIC: kleineren Faktor nehmen damit Canvas vollstaendig
                # auf die Seite passt und Seitenverhaeltnis erhalten bleibt.
                if {$window_x / $printer_x > $window_y / $printer_y} {
                    # x ist der begrenzende Faktor
                    set iprinter_x [expr {int(round($printer_x))}]
                    set iprinter_y [expr {int(round($window_y * $printer_x / $window_x))}]
                } else {
                    # y ist der begrenzende Faktor
                    set iprinter_y [expr {int(round($printer_y))}]
                    set iprinter_x [expr {int(round($window_x * $printer_y / $window_y))}]
                }
                # Offset = linker/oberer Margin in Druckereinheiten
                set off_x [expr {int($printargs(lm) * $printargs(resx) / 1000.0)}]
                set off_y [expr {int($printargs(tm) * $printargs(resy) / 1000.0)}]
                _gdi map $hdc \
                    -logical  "$window_x $window_y" \
                    -physical "$iprinter_x $iprinter_y" \
                    -offset "$off_x $off_y"

                # Canvas-Items zeichnen (Namespace-qualifizierter Check)
                set vtgPrint(canvas.bg) [string tolower [$cw cget -background]]
                foreach id [$cw find all] {
                    if {[$cw itemcget $id -state] eq "hidden"} { continue }
                    set type [$cw type $id]
                    set cmd "::tk::print::_print_canvas.$type"
                    if {[info commands $cmd] eq $cmd} {
                        $cmd $hdc $cw $id
                    }
                }
            }
        }
    }
    package provide tkprintcompat 0.2
    return
}

# ---------------------------------------------------------------------------
# Tcl 8.6: vollstaendige Windows-Implementierung
# ---------------------------------------------------------------------------
# print.tcl steht weiter oben im .tm (return entfernt durch build.py).
# Hier: _selectprinter, _opendoc, _gdi und weitere Overrides fuer Windows.

if {[tk windowingsystem] eq "win32"} {
    package require gdi
    package require printer
    package require struct::list

    namespace eval ::tk::print {

        proc _selectprinter {} {
            variable printer_name
            variable paper_width
            variable paper_height
            variable dpi_x
            variable dpi_y
            variable copies
            variable printargs
            variable margin
            set hDC [printer dialog select]
            if {$hDC eq ""} return
            set attr [struct::list flatten [printer attr -hDc $hDC]]
            set printer_name  [lindex $hDC 0]
            # printer attr "page dimensions" liefert {Laenge Breite} (nicht {Breite Laenge}).
            # Index 0 = Papierlaenge (ph), Index 1 = Papierbreite (pw).
            set paper_width   [lindex [dict get $attr "page dimensions"] 1]
            set paper_height  [lindex [dict get $attr "page dimensions"] 0]
            set dpi_x         [lindex [dict get $attr "pixels per inch"] 0]
            set dpi_y         [lindex [dict get $attr "pixels per inch"] 1]
            set copies        [dict get $attr copies]
            # Margins: wie Tk 9 _init_print -- aus margin-Variablen (mm -> 1/1000 Zoll).
            # Tk 9 Standardwerte: top=15mm left=25mm right=15mm bottom=15mm.
            # Diese Werte koennen via ::tk::print::margin(left) etc. angepasst werden.
            variable margin
            if {![info exists margin(top)]}    { set margin(top)    15 }
            if {![info exists margin(left)]}   { set margin(left)   25 }
            if {![info exists margin(right)]}  { set margin(right)  15 }
            if {![info exists margin(bottom)]} { set margin(bottom) 15 }
            set printargs(tm) [expr {int($margin(top)    / 25.4 * 1000)}]
            set printargs(lm) [expr {int($margin(left)   / 25.4 * 1000)}]
            set printargs(rm) [expr {int($margin(right)  / 25.4 * 1000)}]
            set printargs(bm) [expr {int($margin(bottom) / 25.4 * 1000)}]
        }

        proc _openprinter {args} {
            variable printer_name
            variable paper_width
            variable paper_height
            variable dpi_x
            variable dpi_y
            variable copies
            set hDC [printer open {*}$args]
            set attr [struct::list flatten [printer attr -hDc $hDC]]
            set printer_name  [lindex $hDC 0]
            # printer attr "page dimensions" liefert {Laenge Breite} (nicht {Breite Laenge}).
            # Index 0 = Papierlaenge (ph), Index 1 = Papierbreite (pw).
            set paper_width   [lindex [dict get $attr "page dimensions"] 1]
            set paper_height  [lindex [dict get $attr "page dimensions"] 0]
            set dpi_x         [lindex [dict get $attr "pixels per inch"] 0]
            set dpi_y         [lindex [dict get $attr "pixels per inch"] 1]
            set copies        [dict get $attr copies]
        }

        proc _closeprinter {} { printer close }

        proc _opendoc {jobname {font {}}} {
            variable printargs
            printer job start
            if {$font eq ""} { set font {Arial 12} }
            # charwidth/charheight via gdi characters berechnen
            set charwidth  120
            set charheight 200
            catch {
                array set _cwa {}
                gdi characters $printargs(hDC) -font $font -array _cwa
                set total 0
                set count 0
                foreach {ch w} [array get _cwa] {
                    incr total $w
                    incr count
                }
                if {$count > 0} {
                    set charwidth [expr {$total / $count}]
                }
            }
            # charheight aus DPI und Fontgroesse
            catch {
                set size [lindex $font 1]
                if {[string match {-*} $size]} {
                    set size [string range $size 1 end]
                }
                if {$size > 0} {
                    set charheight [expr {int($size * $printargs(resy) / 72.0)}]
                }
            }
            if {$charwidth  <= 0} { set charwidth  120 }
            if {$charheight <= 0} { set charheight 200 }
            return [list $charwidth $charheight]
        }

        proc _closedoc {}  { printer job end }
        proc _openpage {}  { printer page start }
        proc _closepage {} { printer page end }

        proc _gdi {args} {
            # textplain existiert im alten gdi-Paket nicht:
            # textplain hdc x y string -> gdi text hdc x y -anchor nw -text string
            if {[lindex $args 0] eq "textplain"} {
                set hdc    [lindex $args 1]
                set x      [lindex $args 2]
                set y      [lindex $args 3]
                set string [lindex $args 4]
                gdi text $hdc $x $y -anchor nw -text $string
                return
            }
            gdi {*}$args
        }
    }
}

package provide tkprintcompat 0.2

# Fix: _print_canvas -- Namespace-qualifizierter Check + Scaling-Korrektur.
# Tcl 8.6 Windows.
namespace eval ::tk::print {
    proc _print_canvas {hdc cw} {
        variable vtgPrint
        variable printargs
        set vtgPrint(canvas.bg) [string tolower [$cw cget -background]]
        foreach id [$cw find all] {
            if {[$cw itemcget $id -state] eq "hidden"} { continue }
            set type [$cw type $id]
            set cmd "::tk::print::_print_canvas.$type"
            if {[info commands $cmd] eq $cmd} {
                $cmd $printargs(hDC) $cw $id
            }
        }
    }
}

# Fix: _print_canvas.text -- Font-Descriptor vereinfacht.
namespace eval ::tk::print {
    proc _print_canvas.text {hdc cw id} {
        set txt [$cw itemcget $id -text]
        if {$txt eq ""} return
        set color  [_print_canvas.TransColor [$cw itemcget $id -fill]]
        set coords [$cw coords $id]
        set anchr  [$cw itemcget $id -anchor]
        set just   [$cw itemcget $id -justify]
        set f    [font actual [$cw itemcget $id -font]]
        # Font: Familie, Groesse (positiv=Punkte), bold/italic korrekt.
        set font [list [dict get $f -family]                        [expr {abs([dict get $f -size])}]                        [dict get $f -weight]                        [dict get $f -slant]]
        # -unicode: DrawTextW -> korrekte Umlaute garantiert.
        # kein -angle: gdi 0.9.9.15 unterstuetzt keine Textrotation.
        _gdi text $hdc {*}$coords \
            -fill $color -text $txt -font $font \
            -anchor $anchr -justify $just -unicode
    }
}

# Fix: _print_widget -- Canvas-Groesse skalierungskorrigiert (Tcl 8.6 Windows).
if {![package vsatisfies [info tclversion] 9.0-] &&
    [tk windowingsystem] eq "win32"} {
namespace eval ::tk::print {
    proc _print_widget {w} {
        variable printargs
        variable printer_name
        variable jobname

        set class [winfo class $w]
        if {$class ne "Canvas"} {
            return -code error "Can't print items of type $class."
        }

        _set_dc

        if {![info exists printer_name]} { return }

        _opendoc $jobname
        _openpage

        # Canvas-Groesse skalierungskorrigiert (Nemethi-Methode).
        # physisch = logisch * 100 / scalingPct
        set pct [::tkprintcompat::_scalingPct]

        set sc [$w cget -scrollregion]
        if {$sc eq ""} {
            set window_x [winfo pixels $w [$w cget -width]]
            set window_y [winfo pixels $w [$w cget -height]]
        } else {
            set window_x [winfo pixels $w [lindex $sc 2]]
            set window_y [winfo pixels $w [lindex $sc 3]]
        }
        set window_x [expr {int($window_x * 100.0 / $pct)}]
        set window_y [expr {int($window_y * 100.0 / $pct)}]

        set printer_x [expr {
            ($printargs(pw) - $printargs(lm) - $printargs(rm)) *
            $printargs(resx) / 1000.0
        }]
        set printer_y [expr {
            ($printargs(ph) - $printargs(tm) - $printargs(bm)) *
            $printargs(resy) / 1000.0
        }]

        # MM_ISOTROPIC: kleineren Faktor nehmen damit Canvas vollstaendig passt.
        if {$window_x / $printer_x > $window_y / $printer_y} {
            set iprinter_x [expr {int(round($printer_x))}]
            set iprinter_y [expr {int(round($window_y * $printer_x / $window_x))}]
        } else {
            set iprinter_y [expr {int(round($printer_y))}]
            set iprinter_x [expr {int(round($window_x * $printer_y / $window_y))}]
        }
        # Offset = linker/oberer Margin in Druckereinheiten
        set off_x [expr {int($printargs(lm) * $printargs(resx) / 1000.0)}]
        set off_y [expr {int($printargs(tm) * $printargs(resy) / 1000.0)}]
        _gdi map $printargs(hDC) \
            -logical  "$window_x $window_y" \
            -physical "$iprinter_x $iprinter_y" \
            -offset "$off_x $off_y"

        _print_canvas $printargs(hDC) $w

        _closepage
        _closedoc
    }
}
} ;# end if Tcl 8.6 win32

# ---------------------------------------------------------------------------
# X11/Linux: _runprint -- Canvas-Position und Font-Fix
# ---------------------------------------------------------------------------
# Tk print.tcl (X11) platziert Canvas mit -pageanchor center (Standard).
# Das fuehrt zu grossem Leerraum oben. Fix: -pageanchor nw + -pagey oben.
# Ausserdem: -pagewidth korrekt aus Scrollregion berechnen.
#
# Gilt fuer Tcl 8.6 UND 9.x auf X11 -- ueberschreibt _runprint.

if {[tk windowingsystem] ne "win32"} {
    namespace eval ::tk::print {
        proc _runprint {w class p} {
            variable option
            variable mcmap

            # Widget-Existenz pruefen -- kann durch after idle verspaetet
            # aufgerufen werden wenn Widget schon zerstoert wurde
            if {![winfo exists $w]} {
                catch {destroy $p}
                return
            }

            # Widget-Inhalt sofort lesen bevor Dialog-Lifecycle
            # das Widget zerstoeren kann.
            # Text-Widget: get 1.0 end sofort, nicht erst spaeter im Text-Zweig.
            set _widget_text ""
            if {$class eq "Text"} {
                set _widget_text [$w get 1.0 end]
            }

            array set option [array get dlg::option]

            set media [dict get $mcmap(media) $option(media)]
            set printargs {}
            lappend printargs -title "[tk appname]: Tk window $w"
            lappend printargs -copies $option(copies)
            lappend printargs -media $media

            if {$class eq "Canvas"} {
                set colormode [dict get $mcmap(color) $option(color)]
                set rotate 0
                if {[dict get $mcmap(orient) $option(orient)] eq "landscape"} {
                    set rotate 1
                }

                # Canvas-Dimensionen aus scrollregion oder widget-Groesse
                set args {}
                set sr [$w cget -scrollregion]
                if {$sr ne ""} {
                    set sr [lmap x $sr { winfo pixels $w $x }]
                    foreach k {-x -y -width -height} x $sr {
                        lappend args $k $x
                    }
                    set cwidth  [lindex $sr 2]
                    set cheight [lindex $sr 3]
                } else {
                    set cwidth  [winfo width $w]
                    set cheight [winfo height $w]
                }

                # Druckbreite: zoom anwenden
                set printwidth [expr {$option(czoom) / 100.0 * $cwidth}]

                # Papierhoehe in Punkten (1 Punkt = 1/72 Zoll)
                # A4 = 842pt, letter = 792pt
                set paperh [expr {
                    [dict get $mcmap(media) $option(media)] eq "a4" ? 842.0 : 792.0
                }]

                # Position: oben links, 1cm Abstand vom Rand
                # PostScript-Koordinaten: y=0 ist unten
                # pagey = Papierhoehe - oberer Rand
                set margin_pt 28.3  ;# ~1cm in Punkten (72pt/inch * 1/2.54cm)
                set pagey [expr {$paperh - $margin_pt}]

                # Fontmap aufbauen: Canvas-Fonts -> PostScript-Fonts
                # Ohne fontmap mappt Tk alle Fonts auf Courier.
                # Mapping: Arial/Helvetica -> Helvetica,
                #          Times -> Times-Roman, Courier/Mono -> Courier
                array set _fm {}
                foreach _id [$w find withtag all] {
                    if {[$w type $_id] eq "text"} {
                        set _fnt [$w itemcget $_id -font]
                        if {$_fnt ne "" && ![info exists _fm($_fnt)]} {
                            set _fa  [font actual $_fnt]
                            set _fam [string tolower [dict get $_fa -family]]
                            set _siz [expr {abs([dict get $_fa -size])}]
                            set _b   [expr {[dict get $_fa -weight] eq "bold"}]
                            set _i   [expr {[dict get $_fa -slant]  eq "italic"}]
                            if {[string match "*courier*" $_fam] ||
                                [string match "*mono*"    $_fam] ||
                                [string match "*fixed*"   $_fam]} {
                                set _psf Courier
                                if   {$_b && $_i} { append _psf -BoldOblique } \
                                elseif {$_b}      { append _psf -Bold } \
                                elseif {$_i}      { append _psf -Oblique }
                            } elseif {[string match "*times*" $_fam]} {
                                if   {$_b && $_i} { set _psf Times-BoldItalic } \
                                elseif {$_b}      { set _psf Times-Bold } \
                                elseif {$_i}      { set _psf Times-Italic } \
                                else              { set _psf Times-Roman }
                            } else {
                                set _psf Helvetica
                                if   {$_b && $_i} { append _psf -BoldOblique } \
                                elseif {$_b}      { append _psf -Bold } \
                                elseif {$_i}      { append _psf -Oblique }
                            }
                            set _fm($_fnt) [list $_psf $_siz]
                        }
                    }
                }
                set data [encoding convertto iso8859-1 [$w postscript \
                    -colormode $colormode -rotate $rotate \
                    -pagewidth $printwidth \
                    -pageanchor nw \
                    -pagex $margin_pt \
                    -pagey $pagey \
                    -fontmap _fm \
                    {*}$args]]
                array unset _fm

            } elseif {$class eq "Text"} {
                # Text-Pfad unveraendert
                set tzoom [expr {$option(tzoom) / 100.0}]
                if {$option(tzoom) != 100} {
                    lappend printargs -tzoom $tzoom
                }
                if {$option(pprint)} {
                    lappend printargs -prettyprint
                }
                if {$option(number-up) != 1} {
                    lappend printargs -nup $option(number-up)
                }
                lappend printargs -margins [list                     $option(margin-top)    $option(margin-left)                     $option(margin-bottom) $option(margin-right)]
                set pw [dict get {a4 8.27 legal 8.5 letter 8.5} $media]
                set pw [expr {
                    $pw - ($option(margin-left) + $option(margin-right)) / 72.0
                }]
                set wl [expr {int(9.8 * $pw / $tzoom)}]
                set data [encoding convertto utf-8 [join [_wrapLines $_widget_text $wl] "\n"]]
            }

            after idle [namespace code [list cups print $option(printer) $data {*}$printargs]]
            destroy $p
        }
    }
}
