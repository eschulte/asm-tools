	.macro ___mk_unreliable cmd, mask, first, second
___mk_ur_left_\@:
	push    %rax
        push    %rsi
        push    %rdi
	mov     ___my_fd, %rax
        cmp     $0, %rax
        jne     ___mk_fd_\@
        ## open /dev/random for reading
	mov     $2, %rax        # sys_open
 	mov	$0, %rsi        # O_RDONLY
 	mov	$___my_fp, %rdi # file name
        syscall
        mov     %rax, ___my_fd
        pop     %rdi
        pop     %rsi
___mk_fd_\@:
        ## read 32 bits into %eax
        mov     $0, %rax        # sys_read
        mov     ___my_fd, %rdi  # file handle to read from
        mov     $___my_rd, %rsi # read bytes into my_rd
        mov     $4, %rdx        # length
        syscall
        mov     ___my_rd, %eax  # move random bytes into eax
	cmp     $65535, %ax     # first 1/2 rand determines if unreliable
	jae     ___mk_ur_beg_\@ # jump to reliable or unreliable track
	pop     %rax            # /- reliable path, restore rax
	\cmd    \first, \second # | perform the original comparison
	pushf                   # | save original flags
	jmp     ___mk_ur_end_\@ # \- jump past unreliable track to popf
___mk_ur_beg_\@:
	add     $80, %rsp         # move stack pointer to rax
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
	.section	.data
___my_fp:       .string "/dev/random"
___my_fd:       .int 0
___my_rd:       .quad 0
.text
.global main

main:
	mov     $2, %rbx
	___mk_unreliable     cmp, $2261, $1, %rbx
        ja      big
        mov     $60, %rax
        mov     $0, %rdi
        syscall
big:
        mov     $60, %rax
        mov     $1, %rdi
        syscall
