	.macro ___mk_unreliable cmd, mask, first, second
___mk_ur_left_\@:
	push    %rax              # /-88 save scratch registers
	push    %rbx              # | 80
	push    %rcx              # | 72
	push    %rdx              # | 64
	push    %rsi              # | 56
	push    %rdi              # | 48
	push    %r8               # | 40
	push    %r9               # | 32
	push    %r10              # | 24
	push    %r11              # | 16
	push    %r12              # | 8
	call    random            # place a random number in eax
	cmp     $65535, %ax       # first 1/2 rand determines if unreliable
	pushf                     # push flags to stack
	mov     16(%rsp), %r12    # | restore, offset by 8 from preceeding pushf
	mov     24(%rsp), %r11    # |
	mov     32(%rsp), %r10    # |
	mov     40(%rsp), %r9     # |
	mov     48(%rsp), %r8     # |
	mov     56(%rsp), %rdi    # |
	mov     64(%rsp), %rsi    # |
	mov     72(%rsp), %rdx    # |
	mov     80(%rsp), %rcx    # |
	mov     88(%rsp), %rbx    # \- restore scratch registers
	popf                      # restore comparison flags
	jae     ___mk_ur_beg_\@   # jump to reliable or unreliable track
	sub     $88, %rsp         # /- reliable track: move stack pointer to rax
	pop     %rax              # | restore rax
	\cmd    \first, \second   # | perform the original comparison
	pushf                     # | save original flags
	jmp     ___mk_ur_end_\@   # \- jump past unreliable track to popf
___mk_ur_beg_\@:
	sub     $88, %rsp         # move stack pointer to rax
	shr     $16, %eax         # discard 1/2 rand, and line up rest
	and     \mask, %rax       # zero out un-masked bits in rand
	push    %rax              # save masked rand to the stack
	mov     24(%rsp), %rax    # bring original rax back for comparison
	\cmd    \first, \second   # perform the comparison
	pushf                     # save the flags
	mov     \mask, %rax       # put the masked bits into rax
	not     %rax              # negate the mask bits
	and     (%rsp), %rax      # un-masked flags in rax
	add     $8, %rsp          # pop flags, expose rand flags
	or      (%rsp), %rax      # combine rand and saved flags
	add     $8, %rsp          # pop rand, expose saved rax
	xchg    (%rsp), %rax      # swap rax and flags, orig rax, flags on stack
___mk_ur_end_\@:
	popf                      # apply flags and restore stack
___mk_ur_right_\@:
	.endm
.text
.global main

main:
	mov     $2, %rbx
	push    %rdi
	push    %rax
	mov     $0, %rdi
	call    time
	mov     %rax, %rdi
	mov     $39, %eax
	syscall
	xor     %eax, %edi
	call    srandom
	pop     %rax
	pop     %rdi
	___mk_unreliable     cmp, $2261, $1, %rbx
        ja      big
        mov     $60, %rax
        mov     $0, %rdi
        syscall
big:
        mov     $60, %rax
        mov     $1, %rdi
        syscall
