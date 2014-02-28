        .section        .data
buffer:         .skip 64

.text
.global main
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
	mov     $2345, %rax      # put the value to write in rax
        mov     $10, %rbx      # divisor
        ## byte storage setup
        std                   # set direction flag to count backwards
        mov     $buffer, %rdi # buffer start
        add     $64, %rdi     #        \->end in rdx
### divide by 10, push remainder into buffer
push_digit:
        ## divide off the largest power of ten
        xor     %rdx, %rdx      # clear rdx
        idiv    %rbx            # rdx:rax/rbx -> rax quotient, rdx remainder
        mov     %rax, %rcx      # temporarily save the quotient into rcx
        ## print the remainder
        add     $48, %rdx       # convert remainder to ascii (by adding '0')
        mov     %rdx, %rax      # move the remainder to rax (really ral) for printing
        ## stos   %al,%es:(%rdi)
        stosb                   # push the byte into the buffer
        ## conditional loop
        mov     %rcx, %rax      # restore the quotient
        or      %rax, %rax      # is quotient zero?
        jnz     push_digit      # if not then repeat
        ## print the accumulated buffer
        mov     %rdi, %rsi      # pointer to 1-before filled front of buffer
        add     $1, %rsi        # pointer to beginning of decimal
        mov     $1, %rax        # write system call
	mov     $buffer, %rdx   # buffer start
        add     $64, %rdx       #        \->end in rdx
        sub     %rdi, %rdx # subtract buffer start -> buffer length in rdx
        mov     $1, %rdi   # STDOUT file descriptor
        syscall            # print buffer contents
        ## return
        mov     $60, %rax
        mov     $0, %rdi
        syscall
