%.s: %.c
	$(CC) -o $@ -S $^

%.inst.s: %.s
	./instrument $^ > $@;
	./post-instrument -i $@

%: %.s
	$(CC) -o $@ $^

clean:
	rm -f *.inst *.inst.s *.s plain traced trace.rodata trace.out
