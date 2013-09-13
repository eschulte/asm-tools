%.s: %.c
	$(CC) -o $@ -S $^

%.temp.s: %.s
	./instrument $^ > $@;

%.inst.s: %.temp.s
	./post-instrument $^ > $@;
	@ rm -f trace.rodata

%: %.s
	$(CC) -o $@ $^

clean:
	rm -f *.inst *.inst.s *.s plain traced trace.rodata trace.out
