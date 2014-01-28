	.macro ___mk_unreliable cmd, mask, first, second
	push    %rax              # save original value of rax
	mov     $1479682116, %eax # rand number to tweak flags
	shr     $8, %eax          # discard 1/2 rand, and line up rest
	and     \mask, %ax        # zero out un-masked bits in rand
	push    %rax              # save masked rand to the stack
	\cmd    \first, \second   # perform the comparison
	pushf                     # save the flags
	mov     \mask, %ax        # put the masked bits into rax
	not     %ax               # negate the mask bits
	and     %ax, 8(%rsp)      # pull masked flags into rax
	add     $8, %rsp          # pop flags, expose rand flags
	and     %ax, (%rsp)       # combine saved flags and rand
	add     $8, %rsp          # pop rand, expose saved rax
	xchg    %rax, (%rsp)      # swap rax and flags, orig rax, flags on stack
	popf                      # apply flags and restore stack
	.endm
.text
.global main

main:
	mov     $35, %rax
	mov     $1, %rbx
        ___mk_unreliable cmp, $21743, $2, %rbx
        ja      big
        mov     $0, %eax
        ret
big:
        mov     $1, %eax
        ret
