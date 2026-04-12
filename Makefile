# Makefile fuer tkprintcompat
#
# Aufruf:
#   make              -> tkprintcompat-0.2.tm bauen
#   make install      -> nach ~/lib/tcl8.6/site-tcl/ und ~/lib/tcl9.0/site-tcl/
#   make test         -> Unit-Tests ausfuehren
#   make clean        -> .tm loeschen
#
# WICHTIG: print.tcl enthaelt am Ende ein "return" (fuer Tk-internen Gebrauch).
# Beim Einbetten ins .tm wird es entfernt, sonst wuerde print-8.6erw.tcl
# nie ausgefuehrt. Das build.tcl-Skript erledigt das automatisch.

VERSION = 0.2
TARGET  = tkprintcompat-$(VERSION).tm

SRCFILES = src/newtcl8790.tcl src/print.tcl src/print-8.6erw.tcl

INSTALL_86 = $(HOME)/lib/tcl8.6/site-tcl
INSTALL_90 = $(HOME)/lib/tcl9.0/site-tcl

TCLSH = tclsh

all: $(TARGET)

$(TARGET): $(SRCFILES) build.tcl
	$(TCLSH) build.tcl

install: $(TARGET)
	mkdir -p $(INSTALL_86)
	cp $(TARGET) $(INSTALL_86)/
	@echo "OK: installiert nach $(INSTALL_86)/"

install90: $(TARGET)
	mkdir -p $(INSTALL_90)
	cp $(TARGET) $(INSTALL_90)/
	@echo "OK: installiert nach $(INSTALL_90)/"

test: $(TARGET)
	$(TCLSH) test/test-basic.tcl
	$(TCLSH) test/test-unit.tcl

clean:
	rm -f tkprintcompat-*.tm

.PHONY: all install test clean
