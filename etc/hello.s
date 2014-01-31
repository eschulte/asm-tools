	.section	.data
___my_u:	.ascii "u"
___my_r:	.ascii "r"
___my_f:        .ascii "out"
___my_fd:       .int 0
        .text
        .global main
main:
        ## open the fd for record keeping
        mov     $2, %rax        # open system call
 	mov	$1088, %rsi     # O_APPEND | O_CREAT
 	mov	$___my_f, %edi  # file name
        syscall
        movq    %rax, ___my_fd(%rip)
        ## write to the file
	mov     $1, %rax             # write system call
        mov     ___my_fd(%rip), %rdi # file descriptor
        mov     $___my_r, %rsi       # string to write
        mov     $1, %rdx             # length
        syscall
        ## close
        mov     $3, %rax            # close system call
 	mov	___my_f(%rip), %edi # file name
        syscall
        ## exit
        mov     $60, %rax
        mov     $___my_fd, %rdi
        syscall
