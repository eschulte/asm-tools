SHELL=bash
INST=../src/asm-trace
UR=../src/ur

.PHONY: check stack-test register-test

%.s: %.c
	$(CC) -S $< -o $@

%-ur.s: %.s
	$(UR) $< > $@

%-ur-t.s: %.s
	$(UR) -t $< > $@

%.inst.s: %.s
	$(INST) $^ trace.out inst > $@

%: %.s
	$(CC) $< -o $@

########################################################################
# Testing
PASS=\e[1;1m\e[1;32mPASS\e[1;0m
FAIL=\e[1;1m\e[1;31mFAIL\e[1;0m

stack-test.%: %
	-@./$< 2>/dev/null; \
	if [ $$? -eq 12 ];then printf "$(PASS)"; else printf "$(FAIL)"; fi; \
	echo " stack preservation across macro: $<"

register-test.%: %.s
	-@for reg in ebx ecx edx esi edi;do \
	    cat $<|sed "s/reg/$$reg/"|gcc -x assembler - -o $<-$$reg; \
	    ./$<-$$reg 2>/dev/null; \
	    if [ $$? -eq 12 ];then printf "$(PASS)"; else \
		./$<-$$reg 2>/dev/null; \
		printf "$(FAIL)" \
		echo -n " '$$?'!='12'"; \
	    fi; \
	    echo " register $$reg preservation across macro: $<"; \
	done

check-plain: plain.inst plain.s
	@printf "\e[1;1m$<\t"
	@if diff -q <(./$<; cat trace.out) <(echo -e "right 3\nFB0\nFB0J0\n3");then \
	printf "$(PASS)\t"; \
	else \
	printf "$(FAIL)\t"; \
	fi
	@cat trace.out|sort|uniq -c >trace.counts
	@if [ $$($(INST) plain.s trace.counts label prop|grep -c 1) -eq 30 ];then \
	printf "$(PASS)\n"; \
	else \
	printf "$(FAIL)\n"; \
	fi

check-w-func: w-func.inst w-func.s
	@printf "\e[1;1m$<\t"
	@if diff -q <(./$<; cat trace.out) <(echo -e "right 3\nright in func 7\nFB1\nFB1J0\n6\nFB0\nFB0J0\n1");then \
	printf "$(PASS)\t"; \
	else \
	printf "$(FAIL)\t"; \
	fi
	@cat trace.out|sort|uniq -c >trace.counts
	@if [ $$($(INST) w-func.s trace.counts label prop|grep -c 1) -eq 59 ];then \
	printf "$(PASS)\n"; \
	else \
	printf "$(FAIL)\n"; \
	fi

view-plain: plain.inst plain.s
	./$< >/dev/null
	cat trace.out|sort|uniq -c >trace.counts
	paste <(../asm-trace plain.s trace.counts label prop) plain.s

view-w-func: w-func.inst w-func.s
	./$< >/dev/null
	cat trace.out|sort|uniq -c >trace.counts
	paste <(../asm-trace w-func.s trace.counts label prop) w-func.s

check-ur-header:
	@printf "\e[1;1m-------------ur-----------------\n"

check-ur: check-ur-header stack-ur stack-ur-t stack-test.stack-ur stack-test.stack-ur-t \
	register-ur.s register-ur-t.s register-test.register-ur register-test.register-ur-t

check-asm-trace-header:
	@printf "\e[1;1m----------asm-trace-------------\n"
	@printf "program         inst    prop\e[1;0m\n"

check-asm-trace: check-asm-trace-header check-plain check-w-func

check: check-asm-trace check-ur

view: view-plain view-w-func

clean:
	rm -f *.inst *.inst.s reg-* *-ur *-ur-t *-ur.s *-ur-t.s plain w-func trace.out trace.counts *-e{b,c,d,s}{x,i}
