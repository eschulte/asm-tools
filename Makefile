%.s: %.c
	$(CC) -o $@ -S $^

%: %.s
	$(CC) -o $@ $^

clean:
	rm -f *.s plain traced trace.out
