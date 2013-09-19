INST=../asm-trace
SHELL=bash

check-plain: plain.inst plain.s
	@printf "\e[1;1m$<\t"
	@if diff -q <(./$<; cat trace.out) <(echo -e "right 3\nJ0\nJ1\n3");then \
	printf "\e[1;1m\e[1;32mPASS\e[1;0m\t"; \
	else \
	printf "\e[1;1m\e[1;31mFAIL\e[1;0m\t"; \
	fi
	@cat trace.out|sort|uniq -c >trace.counts
	@if [ $$($(INST) prop plain.s|grep -c 1) -eq 15 ];then \
	printf "\e[1;1m\e[1;32mPASS\e[1;0m\n"; \
	else \
	printf "\e[1;1m\e[1;31mFAIL\e[1;0m\n"; \
	fi

check-w-func: w-func.inst w-func.s
	@printf "\e[1;1m$<\t"
	@if diff -q <(./$<; cat trace.out) <(echo -e "right 3\nright in func 7\n1J1\n1J2\n6\nJ0\nJ1\n1\n6J0");then \
	printf "\e[1;32mPASS\e[1;0m\t"; \
	else \
	printf "\e[1;1m\e[1;31mFAIL\e[1;0m\t"; \
	fi
	@cat trace.out|sort|uniq -c >trace.counts
	@if [ $$($(INST) prop w-func.s|grep -c 1) -eq 31 ];then \
	printf "\e[1;1m\e[1;32mPASS\e[1;0m\n"; \
	else \
	printf "\e[1;1m\e[1;31mFAIL\e[1;0m\n"; \
	fi

view-plain: plain.inst plain.s
	./$< >/dev/null
	cat trace.out|sort|uniq -c >trace.counts
	paste <(../asm-trace prop plain.s) plain.s

view-w-func: w-func.inst w-func.s
	./$< >/dev/null
	cat trace.out|sort|uniq -c >trace.counts
	paste <(../asm-trace prop w-func.s) w-func.s

%.s: %.c
	@$(CC) -o $@ -S $^

%.inst.s: %.s
	@$(INST) inst $^ > $@

%: %.s
	@$(CC) -o $@ $^

check: check-plain check-w-func
	@printf "\e[1;1m--------------------------------\n"
	@printf "program         inst    prop\e[1;0m\n"

view: view-plain view-w-func

clean:
	rm -f  *.s *.inst plain w-func trace.out trace.counts
