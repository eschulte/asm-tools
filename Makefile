INST=./asm-inst
SHELL=bash

.PHONY: check clean

all: plain.inst.s plain.inst w-func.inst.s w-func.inst

%.s: %.c
	$(CC) -o $@ -S $^

%.inst.s: %.s
	$(INST) $^ > $@

%: %.s
	$(CC) -o $@ $^

check-plain: plain.inst
	@ printf "\e[1;1m$^\t"
	@ if diff -q <(./$^; cat trace.out) <(echo -e "right 3\n3");then \
	printf "\e[1;1m\e[1;32mPASS\e[1;0m\n"; \
	else \
	printf "\e[1;1m\e[1;31mFAIL\e[1;0m\n"; \
	fi

check-w-func: w-func.inst
	@ printf "\e[1;1m$^\t"
	@ if diff -q <(./$^; cat trace.out) <(echo -e "right 3\nright in func 7\n6\n1");then \
	printf "\e[1;32mPASS\e[1;0m\n"; \
	else \
	printf "\e[1;1m\e[1;31mFAIL\e[1;0m\n"; \
	fi

check: check-plain check-w-func

clean:
	rm -f *.s *.inst plain w-func trace.out
