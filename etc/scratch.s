.text
.global main

main:
	mov     $1, %rbx
	mov     $1479682116, %eax # random number in eax (instead of call rand)
	shr     $8, %eax # discard half random bits, and line up unused
	and     $21743, %ax # zero out masked bits in random bits/flags
	push    %ax         # save the random flags to the stack
	cmp     $2, %rbx
	pushf
	mov     $21743, %ax   # put the masked bits into eax
	not     %ax           # negate the mask bits
	and     %ax, 4(%rsp)  # pull masked flags into eax
	sub     $4, %rsp      # pop flags, expose random bits on stack
	and     %ax, 4(%rsp)  # combine saved flags and random bits
	sub     $4, %rsp      # pop random, expose original eax
	xchg    %ax, 4(%rsp)  # swap eax and flags
	popf
        ja      big
        mov     $0, %eax
        ret
big:
        mov     $1, %eax
        ret
