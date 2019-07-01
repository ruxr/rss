#
#	@(#) Makefile V1.19.1 (C) 2007-2019 by Roman Oreshnikov
#
# Note: Use SQLite version 3 & xdelta3
#
BINDIR	= /bin
JOBDIR	= /etc/cron.d
MANDIR	= /usr/share/man/man1
RSSDIR	= /etc

#
# DON'T EDIT BELOW!!!
#
NAME	= Reports/Restore shell scripts for administration

BZIP2	= /usr/bin/bzip2
CHMOD	= /bin/chmod
CMP	= /usr/bin/cmp
CP	= /bin/cp
DATE	= /bin/date
INSTALL	= /usr/bin/install
MKDIR	= /bin/mkdir
RM	= /bin/rm
RMDIR	= /bin/rmdir
SED	= /bin/sed
TAR	= /bin/tar

BIN	= Rss
DOC	= Rss.ru.html
JOB	= Rss.cron
MAN	= Rss.1
RSS	= Check
TST	= Rss.tst

SRC	= $(BIN) $(DOC) $(MAN) $(RSS) $(TST)

.PHONY:	all build clean dist install uninstall

all:
	@D=$(DESTDIR); \
	echo "$(NAME) make(1) scenario"; \
	echo "Settings:"; \
	echo "  Directory for main script:    BINDIR = $(BINDIR)"; \
	echo "  Directory for scripts:        RSSDIR = $(RSSDIR)"; \
	echo "  Directory for crond(8) jobs:  JOBDIR = $(JOBDIR)"; \
	echo "  Directory for manual docs:    MANDIR = $(MANDIR)"; \
	echo "Make targets:"; \
	echo "  build     - build scripts from sources"; \
	echo "  test      - test main script"; \
	echo "  install   - install software relative $${D:-/}"; \
	echo "  uninstall - remove installed software"; \
	echo "  dist      - create tarball for distribute"

build: $(JOB)

Rss.cron: Makefile
	@echo "Build $@"; { \
	echo "#"; echo "# $(JOBDIR)/Rss: Rss cron jobs"; echo "#"; \
	echo "4 4 * * * $(BINDIR)/Rss -s" \
		"$(RSSDIR)/Check Rss report from \`/bin/uname -n\`"; \
	} >$@

install: $(JOB) $(BIN) $(MAN) $(RSS)
	@echo "Install software"; set -e; \
	$(INSTALL) -Dm 555 $(BIN) "$(DESTDIR)$(BINDIR)/$(BIN)"; \
	$(INSTALL) -Dm 755 $(RSS) "$(DESTDIR)$(RSSDIR)/$(RSS)"; \
	$(INSTALL) -Dm 644 $(JOB) "$(DESTDIR)$(JOBDIR)/Rss"; \
	$(INSTALL) -Dm 644 $(MAN) "$(DESTDIR)$(MANDIR)/$(MAN)"

uninstall: $(JOB) $(BIN) $(MAN) $(RSS)
	@echo "Uninstall software"; \
	Uninstall() { D=$$1; shift; \
		while [ $$# != 0 ]; do \
			F=$$1; $(CMP) -s "$$1" "$$D/$$F"; \
			case $$? in \
			0) $(RM) -f "$$D/$$F";; \
			1) echo "$$D/$$F has been changed, removing skipped";; \
			esac; \
			shift; \
		done; \
		[ ! -d "$$D" ] || $(RMDIR) -p "$$D" 2>/dev/null || :; \
	}; \
	Uninstall "$(DESTDIR)$(BINDIR)" $(BIN); \
	Uninstall "$(DESTDIR)$(RSSDIR)" $(RSS); \
	Uninstall "$(DESTDIR)$(JOBDIR)" Rss; \
	Uninstall "$(DESTDIR)$(MANDIR)" $(MAN)

test:	$(TST) $(BIN)
	@$(CHMOD) 755 $(BIN) $?; ./$?

clean:
	@$(RM) -rf $(JOB) tst

dist: Makefile $(SRC)
	@set -e; D=`$(SED) '/@(#)/!d;s/^.*V\([^ ]*\).*/Rss-\1/;q' Makefile`; \
	echo "Create $$D.tar.bz2"; \
	[ ! -d "$$D" ] || $(RM) -rf "$$D"; $(MKDIR) "$$D"; \
	$(CP) Makefile "$$D"; \
	V=`$(SED) '/@(#)/!d;s/^.*\(V.*\)$$/\1/;q' Makefile`; \
	for F in $(SRC); do \
		$(SED) "s/\(@(#)\).*/\1 $$F $$V/" $$F >"$$D/$$F"; \
	done; \
	C=$${V#* * } V=$${V#*V} V=$${V%% *}; Y=`$(DATE) +%Y`; \
	$(SED) -i "1s/.*/.TH Rss 1 $$Y $$V/;\$$s/.*/Copyright $$C/" \
		"$$D/Rss.1"; \
	$(TAR) cf - --remove-files "$$D" | $(BZIP2) -9c >"$$D.tar.bz2"
