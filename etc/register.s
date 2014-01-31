format:
        .string "%d\n"

.text
.global main

main:
        mov     $12, %reg
	cmp     $1, %ebx
        mov     $60, %rax
        mov     %reg, %edi
        syscall
