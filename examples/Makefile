INST=../asm-trace
SHELL=bash

check-plain: plain.inst
	@ printf "\e[1;1m$^\t"
	@ if diff -q <(./$^; cat trace.out) <(echo -e "right 3\nJ0\nJ1\n3");then \
	printf "\e[1;1m\e[1;32mPASS\e[1;0m\n"; \
	else \
	printf "\e[1;1m\e[1;31mFAIL\e[1;0m\n"; \
	fi

check-w-func: w-func.inst
	@ printf "\e[1;1m$^\t"
	@ if diff -q <(./$^; cat trace.out) <(echo -e "right 3\nright in func 7\n1J1\n1J2\n6\nJ0\nJ1\n1\n6J0");then \
	printf "\e[1;32mPASS\e[1;0m\n"; \
	else \
	printf "\e[1;1m\e[1;31mFAIL\e[1;0m\n"; \
	fi

%.s: %.c
	@$(CC) -o $@ -S $^

%.inst.s: %.s
	@$(INST) inst $^ > $@

%: %.s
	@$(CC) -o $@ $^

check: check-plain check-w-func
