SHELL=bash
INST=../asm-trace

.PHONY: check stack-test register-test

%.s: %.c
	$(CC) -S $< -o $@

%-ur.s: %.s
	../ur $< > $@

%.inst.s: %.s
	@$(INST) $^ trace.out inst > $@

%: %.s
	$(CC) $< -o $@

########################################################################
# Testing
stack-test: stack-ur
	-@./$<; if [ $$? -eq 12 ];then echo -n PASS; else echo -n FAIL; fi
	-@echo " stack preservation across macro"

register-test:
	-@for reg in ebx ecx edx esi edi;do \
	    cat register.s|sed "s/reg/$$reg/"|gcc -x assembler - -o reg-$$reg; \
	    ./reg-$$reg; \
	    if [ $$? -eq 12 ];then echo -n PASS; else \
		./reg-$$reg; \
		echo -n "FAIL '$$?'!='12'"; \
	    fi; \
	    echo " register $$reg preservation across macro"; \
	done

check-plain: plain.inst plain.s
	@printf "\e[1;1m$<\t"
	@if diff -q <(./$<; cat trace.out) <(echo -e "right 3\nFB0\nFB0J0\n3");then \
	printf "\e[1;1m\e[1;32mPASS\e[1;0m\t"; \
	else \
	printf "\e[1;1m\e[1;31mFAIL\e[1;0m\t"; \
	fi
	@cat trace.out|sort|uniq -c >trace.counts
	@if [ $$($(INST) plain.s trace.counts label prop|grep -c 1) -eq 30 ];then \
	printf "\e[1;1m\e[1;32mPASS\e[1;0m\n"; \
	else \
	printf "\e[1;1m\e[1;31mFAIL\e[1;0m\n"; \
	fi

check-w-func: w-func.inst w-func.s
	@printf "\e[1;1m$<\t"
	@if diff -q <(./$<; cat trace.out) <(echo -e "right 3\nright in func 7\nFB1\nFB1J0\n6\nFB0\nFB0J0\n1");then \
	printf "\e[1;32mPASS\e[1;0m\t"; \
	else \
	printf "\e[1;1m\e[1;31mFAIL\e[1;0m\t"; \
	fi
	@cat trace.out|sort|uniq -c >trace.counts
	@if [ $$($(INST) w-func.s trace.counts label prop|grep -c 1) -eq 59 ];then \
	printf "\e[1;1m\e[1;32mPASS\e[1;0m\n"; \
	else \
	printf "\e[1;1m\e[1;31mFAIL\e[1;0m\n"; \
	fi

view-plain: plain.inst plain.s
	./$< >/dev/null
	cat trace.out|sort|uniq -c >trace.counts
	paste <(../asm-trace plain.s trace.counts label prop) plain.s

view-w-func: w-func.inst w-func.s
	./$< >/dev/null
	cat trace.out|sort|uniq -c >trace.counts
	paste <(../asm-trace w-func.s trace.counts label prop) w-func.s

check: check-plain check-w-func stack-test register-test
	@printf "\e[1;1m--------------------------------\n"
	@printf "program         inst    prop\e[1;0m\n"

view: view-plain view-w-func

clean:
	rm -f  *.s *.inst plain w-func trace.out trace.counts
