%.s: %.c
	$(CC) -o $@ -S $^

%.inst.s: %.s
	./instrument $^ > $@
	cat $@ >> trace.prefix
	mv trace.prefix $@

%: %.s
	$(CC) -o $@ $^

clean:
	rm -f *.inst *.inst.s *.s plain traced trace.prefix trace.out
