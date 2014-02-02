.PHONY: check clean

src/%:
	@$(MAKE) --no-print-directory -C src/ $*

check: src/asm-trace
	@$(MAKE) --no-print-directory -C etc/ $(MAKECMDGOALS)

view: $(INST)
	@$(MAKE) --no-print-directory -C etc/ $(MAKECMDGOALS)

clean:
	$(MAKE) -C src/ $(MAKECMDGOALS)
	$(MAKE) -C etc/ $(MAKECMDGOALS)
