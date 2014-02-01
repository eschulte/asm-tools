	.section	.data
___my_fp:       .string "/dev/random"
___my_fd:       .int 0
___my_rd:       .quad 0
        .text
        .global main
main:
        ## open /dev/random for reading
	mov     $2, %rax        # sys_open
 	mov	$0, %rsi        # O_RDONLY
 	mov	$___my_fp, %edi # file name
        syscall
        mov     %rax, ___my_fd
        ## read 32 bits into %eax
        mov     $0, %rax        # sys_read
        mov     ___my_fd, %rdi  # file handle to read from
        mov     $___my_rd, %rsi # read bytes into my_rd
        mov     $4, %rdx        # length
        syscall
        ## exit
        mov     $60, %rax
        mov     ___my_rd, %rdi
        syscall
