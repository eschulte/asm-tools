	.macro ___mk_unreliable cmd, mask, first, second
	push    %rax              # save original value of rax
	call    random            # place a random number in eax
	cmp     $32767, %ax       # first 1/2 rand determines if unreliable
	jae     ___mk_ur_beg_\@   # jump to reliable or unreliable track
	pop     %rax              # /-reliable track
	\cmd    \first, \second   # | perform the original comparison
	pushf                     # | save original flags
        push    $___mk_ur_r       # | save unrandom path for tracing
	jmp     ___mk_ur_end_\@   # \-jump past unreliable track to popf
___mk_ur_beg_\@:
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
        push    $___mk_ur_u       # save random path for tracing
___mk_ur_end_\@:
        pop     %rsi            # string to write
        push    %rax            # save registers clobbered by the syscall
        push    %rdi            # |
        push    %rdx            # \-
	mov     $1, %rax        # write system call
        mov     $2, %rdi        # STDERR file descriptor
        mov     $1, %rdx        # length
        syscall
        pop     %rdx            # restore saved registers
        pop     %rdi            # |
        pop     %rax            # \-
	popf                    # apply flags and restore stack
	.endm
	.section	.rodata
___mk_ur_u:	.ascii "u"
___mk_ur_r:	.ascii "r"
___mk_ur_f:     .ascii "out"
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
