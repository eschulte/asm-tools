%.s: %.c
	$(CC) -o $@ -S $^

%.inst.s: %.s
	./instrument $^ > $@
	cat $@ >> trace.rodata
	echo "	.section	.rodata" >$@
	cat trace.rodata >> $@

%: %.s
	$(CC) -o $@ $^

clean:
	rm -f *.inst *.inst.s *.s plain traced trace.rodata trace.out
