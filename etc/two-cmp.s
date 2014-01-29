.text
.global main

main:
	mov     $1, %rax
	mov     $2, %rbx
	mov     $3, %rcx
	cmp     $3, %rax
	cmp     $2, %rbx
	cmp     $1, %rcx
        ja      big
        mov     $0, %eax
        ret
big:
        mov     $1, %eax
        ret
