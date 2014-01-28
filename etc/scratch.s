	.macro ___mk_unreliable cmd, mask, first, second
	push    %rax              # save original value of rax
	mov     $1479682116, %eax # rand number to tweak flags
	shr     $8, %eax          # discard 1/2 rand, and line up rest
	and     \mask, %rax       # zero out un-masked bits in rand
	push    %rax              # save masked rand to the stack
	\cmd    \first, \second   # perform the comparison
	pushf                     # save the flags
	mov     \mask, %rax       # put the masked bits into rax
	not     %rax              # negate the mask bits
	and     (%rsp), %rax      # un-masked flags in rax
	add     $8, %rsp          # pop flags, expose rand flags
	or      (%rsp), %rax      # combine rand and saved flags
	add     $8, %rsp          # pop rand, expose saved rax
	xchg    (%rsp), %rax      # swap rax and flags, orig rax, flags on stack
	popf                      # apply flags and restore stack
	.endm
.text
.global main

main:
	mov     $35, %rax
	mov     $1, %rbx
        ___mk_unreliable cmp, $1, $2, %rbx
        ja      big
        mov     $0, %eax
        ret
big:
        mov     $1, %eax
        ret
