.PHONY: check stack-test register-test

%.s: %.c
	$(CC) -S $< -o $@

%-ur.s: %.s
	../ur $< > $@

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

check: stack-test register-test
