.text
.global main

main:
	mov     $1, %rbx
## Macro ostensibly start here with the following variables
## first -- $2
## second - rbx
## cmd ---- cmp
## mask --- $21743
	push    %rax
	mov     $1479682116, %eax # rand number to tweak flags
	shr     $8, %eax          # discard 1/2 rand, and line up rest
	and     $21743, %ax       # zero out un-masked bits in rand
	push    %rax              # save masked rand to the stack
	cmp     $2, %rbx          # perform the comparison
	pushf                     # save the flags
	mov     $21743, %ax       # put the masked bits into rax
	not     %ax               # negate the mask bits
	and     %ax, 8(%rsp)      # pull masked flags into rax
	add     $8, %rsp          # pop flags, expose rand flags
	and     %ax, (%rsp)       # combine saved flags and rand
	add     $8, %rsp          # pop rand, expose saved rax
	xchg    %rax, (%rsp)      # swap rax and flags, orig rax, flags on stack
	popf
        ja      big
        mov     $0, %eax
        ret
big:
        mov     $1, %eax
        ret

	## Stack preservation
	## 0x7fffffffdef8 <- before first push
	## 0x7fffffffdef0 <- after push %rax (saving original value)
	## 0x7fffffffdee8 <- after push %rax
	## 0x7fffffffdee0 <- after pushf
	## 0x7fffffffdee8 <- after add # pop flags
	## 0x7fffffffdef0 <- after add # pop random
	## 0x7fffffffdef8 <- after popf

