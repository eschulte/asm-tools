INST=./src/asm-trace

.PHONY: check clean

check: $(INST)
	-@$(MAKE) -C examples/ $(MAKECMDGOALS)
	-@$(MAKE) --no-print-directory -C etc/ $(MAKECMDGOALS)

view: $(INST)
	$(MAKE) -C examples/ $(MAKECMDGOALS)

clean:
	rm -f asm-trace *.fasl *.lx32fsl dumper-*.lisp
	@$(MAKE) -C examples/ $(MAKECMDGOALS)
	@$(MAKE) -C etc/ $(MAKECMDGOALS)
