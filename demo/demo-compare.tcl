#!/usr/bin/env wish
# demo-compare.tcl -- Vergleich: tk print vanilla vs tkprintcompat vs pdf4tcl vs PS+GS
#
# Drei Ausgabewege, zwei Modi (vanilla / tkprintcompat):
#   1. tk print -- vanilla (Tk eingebaut, keine Fixes)
#   2. tk print -- tkprintcompat (mit allen Fixes)
#   3. pdf4tcl canvas -> PDF
#   4. $canvas postscript -> Ghostscript -> PDF
#
# Benoetigt: Ghostscript (gs), pdftocairo
# Optional:  pdf4tcl, tkprintcompat

package require Tk

# tkprintcompat und pdf4tcl optional laden
set have_compat  [expr {![catch {package require tkprintcompat}]}]
set have_pdf4tcl [expr {![catch {package require pdf4tcl}]}]
set compat_version [expr {$have_compat ? [package require tkprintcompat] : "n/a"}]

wm title . "Canvas-Ausgabe Vergleich"
wm geometry . "730x520"

# --- Ausgabeverzeichnis ---
set outdir [file join [file dirname [info script]] output]
file mkdir $outdir

# ---------------------------------------------------------------------------
# Canvas aufbauen
# ---------------------------------------------------------------------------
frame .cf -relief groove -borderwidth 2
pack .cf -fill both -expand 0 -padx 8 -pady 8

canvas .cf.c -width 600 -height 280 -background white \
    -scrollregion {0 0 600 280}

.cf.c create text 20 20 -text "Canvas-Ausgabe Vergleich" \
    -font {Arial 14 bold} -anchor w -fill black
.cf.c create line 20 38 580 38 -width 1 -fill black

# Schriftgroessen (positiv = Punkte)
.cf.c create text 20  58 -text "Schriftgroessen:" \
    -font {Arial 9 bold} -anchor w
.cf.c create text 30  78 -text "Arial 9"       -font {Arial  9} -anchor w
.cf.c create text 30  98 -text "Arial 10"      -font {Arial 10} -anchor w
.cf.c create text 30 118 -text "Arial 11"      -font {Arial 11} -anchor w
.cf.c create text 30 143 -text "Arial 14"      -font {Arial 14} -anchor w
.cf.c create text 30 170 -text "Arial 14 bold" \
    -font {Arial 14 bold} -anchor w -fill navy

# Negative Groesse (Pixel) -- zeigt Bug bei tk print
.cf.c create text 210  78 -text "Arial -10 (pixel)" \
    -font {Arial -10} -anchor w -fill darkred
.cf.c create text 210  98 -text "Arial -14 (pixel)" \
    -font {Arial -14} -anchor w -fill darkred
.cf.c create text 210 118 -text "Arial -18 (pixel)" \
    -font {Arial -18} -anchor w -fill darkred

# Unicode
.cf.c create text 20 198 -text "Unicode:" \
    -font {Arial 9 bold} -anchor w
.cf.c create text 30 218 \
    -text "\u00c4\u00d6\u00dc \u00e4\u00f6\u00fc \u00df \u20ac \u00a9 \u00b0" \
    -font {Arial 12} -anchor w -fill darkgreen

# Grafik
.cf.c create rect  430  55 590 175 -outline black -fill lightyellow
.cf.c create oval  440  65 580 165 -fill lightblue -outline navy
.cf.c create line  430 185 590 185 -width 2 -fill red -dash {6 3}

pack .cf.c -padx 4 -pady 4

# ---------------------------------------------------------------------------
# Log
# ---------------------------------------------------------------------------
text .log -height 5 -font {Courier 9} -state disabled -wrap word
pack .log -fill x -padx 8

proc log {msg} {
    .log configure -state normal
    .log insert end "$msg\n"
    .log see end
    .log configure -state disabled
}

proc open_file {path} {
    if {![file exists $path]} { log "Nicht gefunden: $path"; return }
    switch [tk windowingsystem] {
        win32 { exec cmd /c start "" $path & }
        x11   { exec xdg-open $path & }
        aqua  { exec open $path & }
    }
}

# Fontmap fuer PostScript-Export aufbauen
proc make_fontmap {w arrName} {
    upvar 1 $arrName fm
    array unset fm
    foreach id [$w find withtag all] {
        if {[$w type $id] ne "text"} continue
        set fnt [$w itemcget $id -font]
        if {$fnt eq "" || [info exists fm($fnt)]} continue
        set fa  [font actual $fnt]
        set fam [string tolower [dict get $fa -family]]
        set siz [expr {abs([dict get $fa -size])}]
        set b   [expr {[dict get $fa -weight] eq "bold"}]
        set i   [expr {[dict get $fa -slant]  eq "italic"}]
        if {[string match "*courier*" $fam] || [string match "*mono*" $fam]} {
            set p Courier
            if {$b && $i} {append p -BoldOblique} \
            elseif {$b}   {append p -Bold} \
            elseif {$i}   {append p -Oblique}
        } elseif {[string match "*times*" $fam]} {
            if {$b && $i} {set p Times-BoldItalic} \
            elseif {$b}   {set p Times-Bold} \
            elseif {$i}   {set p Times-Italic} \
            else           {set p Times-Roman}
        } else {
            set p Helvetica
            if {$b && $i} {append p -BoldOblique} \
            elseif {$b}   {append p -Bold} \
            elseif {$i}   {append p -Oblique}
        }
        set fm($fnt) [list $p $siz]
    }
}

# ---------------------------------------------------------------------------
# Buttons
# ---------------------------------------------------------------------------
frame .bf
pack .bf -fill x -padx 8 -pady 2

# 1. tk print vanilla
button .bf.v -text "1. tk print (vanilla)" -background #ffe0e0 \
    -command {
        log "tk print vanilla ..."
        # tkprintcompat temporaer deaktivieren
        set _had [expr {[info commands ::tkprintcompat::_scalingPct] ne ""}]
        try {
            tk print .cf.c
            log "tk print vanilla OK"
        } on error {err} {
            log "FEHLER: $err"
        }
    }
pack .bf.v -side left -padx 3

# 2. tk print + tkprintcompat
button .bf.c -text "2. tk print (tkprintcompat)" -background #e0ffe0 \
    -state [expr {$have_compat ? "normal" : "disabled"}] \
    -command {
        log "tk print + tkprintcompat $::compat_version ..."
        try {
            tk print .cf.c
            log "tk print + tkprintcompat OK"
        } on error {err} {
            log "FEHLER: $err"
        }
    }
pack .bf.c -side left -padx 3

# 3. pdf4tcl
button .bf.p -text "3. pdf4tcl" -background #e0e8ff \
    -state [expr {$have_pdf4tcl ? "normal" : "disabled"}] \
    -command {
        global outdir
        set pdffile [file join $outdir compare-pdf4tcl.pdf]
        set pngbase [file join $outdir compare-pdf4tcl]
        log "pdf4tcl canvas -> PDF ..."
        try {
            set pct [expr {
                [info commands ::tkprintcompat::_scalingPct] ne "" ?
                [::tkprintcompat::_scalingPct] : 100
            }]
            set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true -compress 1]
            $pdf startPage
            $pdf canvas .cf.c -x 20 -y 20 \
                -textscale [expr {100.0 / $pct}]
            $pdf endPage
            $pdf write -file $pdffile
            $pdf destroy
            log "PDF  -> $pdffile"
            exec pdftocairo -png $pdffile $pngbase
            log "PNG  -> ${pngbase}-1.png"
            open_file $pdffile
        } on error {err} {
            log "FEHLER: $err"
        }
    }
pack .bf.p -side left -padx 3

# 4. PostScript + GS
button .bf.gs -text "4. PostScript + GS" -background #fff8e0 \
    -command {
        global outdir
        set psfile  [file join $outdir compare-ps.ps]
        set pdffile [file join $outdir compare-ps.pdf]
        set pngbase [file join $outdir compare-ps]
        log "PostScript + Ghostscript ..."
        try {
            make_fontmap .cf.c _fm
            .cf.c postscript -file $psfile \
                -pageanchor nw -pagex 28.3 -pagey 813.7 \
                -fontmap _fm
            array unset _fm
            log "PS   -> $psfile"
            exec gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite \
                -dCompatibilityLevel=1.4 \
                -sOutputFile=$pdffile $psfile
            log "PDF  -> $pdffile"
            exec pdftocairo -png $pdffile $pngbase
            log "PNG  -> ${pngbase}-1.png"
            open_file $pdffile
        } on error {err} {
            log "FEHLER: $err"
        }
    }
pack .bf.gs -side left -padx 3

# Ausgabeverzeichnis
button .bf.out -text "Ausgabe-Ordner" \
    -command { open_file $outdir }
pack .bf.out -side right -padx 4

# ---------------------------------------------------------------------------
# Statuszeile
# ---------------------------------------------------------------------------
set _pdf4v [expr {$have_pdf4tcl ? [package require pdf4tcl] : "n/a"}]
label .status \
    -text "Tcl [info patchlevel] | [tk windowingsystem] | tkprintcompat: $compat_version | pdf4tcl: $_pdf4v" \
    -anchor w -foreground grey40 -font {Arial 8}
pack .status -fill x -padx 8 -pady 2

log "Ausgabeverzeichnis: $outdir"
if {!$have_compat}  { log "HINWEIS: tkprintcompat nicht gefunden -- Button 2 deaktiviert" }
if {!$have_pdf4tcl} { log "HINWEIS: pdf4tcl nicht gefunden -- Button 3 deaktiviert" }
