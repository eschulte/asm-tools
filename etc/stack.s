.text
.global main

main:
        push    $12
	mov     $2, %rbx
	cmp     $1, %rbx
        mov     $60, %rax
        pop     %rdi
        syscall
        
