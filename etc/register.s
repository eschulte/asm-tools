holder:
        .quad 0

.text
.global main

main:
        mov     $12, %reg
	cmp     $1, %ebx
        mov     $60, %rax
        mov     %reg, holder
        mov     holder, %edi
        syscall
