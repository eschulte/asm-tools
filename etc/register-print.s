        .section        .data
buffer:         .ascii 64
main:
        ## Register printing routine
        ## -------------------------
        ## adapted from Frank Kotler's post
        ## http://forum.nasm.us/index.php?topic=1371.0
        ##
        ## variables
        ## ---------
        ## rax --- the original value
        ## rbx --- holds the divisor
        ## rcx --- temporary storage
        ## rdx --- division remainder
        ## TODO: rdi --- location of destination buffer
	mov     $12, %rax      # put the value to write in rax
        mov     $10, %rbx      # divisor
        ## byte storage setup
        std                    # set direction flag to count backwards
        mov     64($buffer), %rdi # point to end of buffer for accumulation
### divide by 10, push remainder into buffer
push_digit:
        ## divide off the largest power of ten
        xor     %rdx, %rdx      # clear rdx
        idiv    %rbx            # rdx:rax/rbx -> rax quotient, rdx remainder
        mov     %rax, %rcx      # temporarily save the quotient into rcx
        ## print the remainder
        add     %rdx, '0'       # convert remainder to ascii
        mov     %rdx, %ral      # move the remainder for printing
        stosb                   # push the byte into the buffer
        ## conditional loop
        mov     %rcx, %rax      # restore the quotient
        or      %rax, %rax      # is quotient zero?
        jnz     push_digit      # if not then repeat
        ## print the accumulated buffer
        mov     %rdi, %rsi      # pointer to filled front of buffer 
        mov     $1, %rax        # write system call
	mov     64($buffer), %rdx # buffer end in rdx
        sub     %rdi, %rdx # subtract buffer start -> buffer length in rdx
        mov     $1, %rdi   # STDOUT file descriptor
        syscall            # print buffer contents
        ## return
        mov     $60, %rax
        mov     $0, %rdi
        syscall
