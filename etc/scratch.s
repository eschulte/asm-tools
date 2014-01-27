.text
.global main

main:
	mov     $1, %rbx
## Macro ostensibly start here with the following fake variables
## first -- $2
## second - rbx
## cmd ---- cmp
## mask --- $21743
	mov     $1479682116, %eax # random number in eax (instead of call rand)
	shr     $8, %eax # discard half random bits, and line up unused
	and     $21743, %ax # zero out masked bits in random bits/flags
## %ax is 0x581028 5771304
	push    %rax              # save the random flags to the stack
	cmp     $2, %rbx
	pushf
	mov     $21743, %ax   # put the masked bits into eax
	not     %ax           # negate the mask bits
	and     %ax, 8(%rsp)  # pull masked flags into eax
	sub     $4, %rsp      # pop flags, expose random bits on stack
	and     %ax, 8(%rsp)  # combine saved flags and random bits
	sub     $4, %rsp      # pop random, expose original eax
	xchg    %ax, 8(%rsp)  # swap eax and flags
	popf
        ja      big
        mov     $0, %eax
        ret
big:
        mov     $1, %eax
        ret
