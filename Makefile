BINDIR=$(DESTDIR)/usr/bin/
DOCDIR=$(DESTDIR)/usr/share/man/man1

.PHONY: check clean

all: src/asm-trace

src/%:
	@$(MAKE) --no-print-directory -C src/ $*

check: src/asm-trace
	$(MAKE) --no-print-directory -C etc/ check

view: $(INST)
	@$(MAKE) --no-print-directory -C etc/ $(MAKECMDGOALS)

clean:
	$(MAKE) -C src/ $(MAKECMDGOALS)
	$(MAKE) -C etc/ $(MAKECMDGOALS)

install: src/asm-trace src/ur doc/ur.1 doc/asm-trace.1
	mkdir -p $(DOCDIR)
	install -Dm644 doc/ur.1 $(DOCDIR)/ur.1
	install -Dm644 doc/asm-trace.1 $(DOCDIR)/asm-trace.1
	mkdir -p $(BINDIR)
	install -Dm755 src/ur $(BINDIR)
	install -Dm755 src/asm-trace $(BINDIR)
