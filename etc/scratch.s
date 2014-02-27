	.section	.rodata
___dig_main:    .string "main:"
___dig_big:     .string "big:"
___dig_n:	.ascii "\n"
        .section        .data
___dig_rax:     .quad 0
___dig_rbx:     .quad 0
___dig_rcx:     .quad 0
___dig_rdx:     .quad 0
___dig_rsi:     .quad 0
___dig_rdi:     .quad 0
___dig_r8:      .quad 0
___dig_r9:      .quad 0
___dig_r10:     .quad 0
___dig_r11:     .quad 0
___dig_r12:     .quad 0
        .macro ___save
	mov     %rax, ___dig_rax
	mov     %rbx, ___dig_rbx
	mov     %rcx, ___dig_rcx
	mov     %rdx, ___dig_rdx
	mov     %rsi, ___dig_rsi
	mov     %rdi, ___dig_rdi
	mov     %r8,  ___dig_r8
	mov     %r9,  ___dig_r9
	mov     %r10, ___dig_r10
	mov     %r11, ___dig_r11
	mov     %r12, ___dig_r12
        .endm
        .macro ___restore
	mov     ___dig_r12, %r12
	mov     ___dig_r11, %r11
	mov     ___dig_r10, %r10
	mov     ___dig_r9,  %r9
	mov     ___dig_r8,  %r8
	mov     ___dig_rdi, %rdi
	mov     ___dig_rsi, %rsi
	mov     ___dig_rdx, %rdx
	mov     ___dig_rcx, %rcx
	mov     ___dig_rbx, %rbx
	mov     ___dig_rax, %rax
        .endm
        .macro ___print value, length
        mov     \value, %rsi
        mov     $1, %rax         # write system call
	mov     $2, %rdi         # STDERR file descriptor
	mov     $\length, %rdx   # length
        syscall
        .endm
	.macro ___dig name, length
        ___save
	___print        $___dig_\name, \length
	___print        %rax, 4
	___print        %rbx, 4
	___print        %rcx, 4
	___print        %rdx, 4
	___print        %rsi, 4
	___print        %rdi, 4
	___print        %r8,  4
	___print        %r9,  4
	___print        %r10, 4
	___print        %r11, 4
	___print        %r12, 4
        ___print        $___dig_n, 1
        ___restore
        .endm
.text
.global main

main:
        ___dig  main, 5
	mov     $2, %rbx
	cmp     $1, %rbx
        ja      big
        mov     $60, %rax
        mov     $0, %rdi
        syscall
big:
        ___dig  big, 4
        mov     $60, %rax
        mov     $1, %rdi
        syscall
