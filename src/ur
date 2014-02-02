#!/bin/bash
#
# Copyright (C) 2014 Eric Schulte
# Licensed under the Gnu Public License Version 3 or later
#
# Instrument an assembly program with assembler isntructions to make
# the resulting assembler less reliable.
#
HELP="Usage: $0 [OPTION]... [INPUT-ASM-FILE]
 Options:
  -u RATE ----------- set RATE of unreliable computation
  -t ---------------- write trace of (un)reliable cmps to STDERR
  -d ---------------- add labels for debugging
  -r SOURCE --------- read random bits from SOURCE
                      (default to /dev/urandom)
  -i[SUFFIX] -------- edit file in place (optional backup at SUFFIX)"
eval set -- $(getopt hu:tdr:i:: "$@" || echo "$HELP" && exit 1;)
RATE=0.1
SED_OPTS=" "
DEBUG=""
RAND="/dev/urandom"
TRACE=""
while [ $# -gt 0 ];do
    case $1 in
        -h)  echo "$HELP" && exit 0;;
        -u)  RATE=$2; shift;;
        -t)  TRACE="yes";;
        -d)  DEBUG="yes";;
        -r)  RAND=$2; shift;;
        -i)  SED_OPTS+="$1$2"; shift;;
        (--) shift; break;;
        (-*) echo "$HELP" && exit 1;;
        (*)  break;;
    esac
    shift
done
# 65535 is the maximum value in ax
ADJ=$(echo "scale=0;((1 - $RATE) * 65535)/1"|bc)
SED_CMD="
# the macro used to replace comparison instructions
1i\\
$(cat <<"EOF"|sed 's/\\/\\\\/g;s/\t/\\t/g;s/$/\\/;'|sed "s/ADJ/$ADJ/"|sed "s|RAND|$RAND|"
TRACE
	.section	.rodata
___mk_ur_u:	.ascii "u"
___mk_ur_r:	.ascii "r"
___mk_ur_n:	.ascii "\n"
TRACE
	.section	.data
___mk_ur_fp:    .string "RAND"
___mk_ur_fd:    .int 0
___mk_ur_rd:    .quad 0
___mk_ur_top:   .quad 0
___mk_ur_rbx:   .quad 0
___mk_ur_rcx:   .quad 0
___mk_ur_rdx:   .quad 0
___mk_ur_rsi:   .quad 0
___mk_ur_rdi:   .quad 0
___mk_ur_r8:    .quad 0
___mk_ur_r9:    .quad 0
___mk_ur_r10:   .quad 0
___mk_ur_r11:   .quad 0
___mk_ur_r12:   .quad 0
TRACE
___mk_ur_trace: .quad 0
TRACE
	.macro ___mk_unreliable cmd, mask, first, second
DEBUG
___mk_ur_enter_\@:
DEBUG
	## Save everything to memory instead of the stack.
	## also, save the head of the stack to memory so it
	## isn't overwritten by pushf.
	xchg    (%rsp), %rax
	mov     %rax, ___mk_ur_top
	mov     %rbx, ___mk_ur_rbx
	mov     %rcx, ___mk_ur_rcx
	mov     %rdx, ___mk_ur_rdx
	mov     %rsi, ___mk_ur_rsi
	mov     %rdi, ___mk_ur_rdi
	mov     %r8,  ___mk_ur_r8
	mov     %r9,  ___mk_ur_r9
	mov     %r10, ___mk_ur_r10
	mov     %r11, ___mk_ur_r11
	mov     %r12, ___mk_ur_r12
	mov     ___mk_ur_fd, %rax
	cmp     $0, %rax
	jne     ___mk_ur_fd_\@
	## open /dev/urandom for reading
	mov     $2, %rax        # sys_open
 	mov	$0, %rsi        # O_RDONLY
 	mov	$___mk_ur_fp, %rdi # file name
	syscall
	mov     %rax, ___mk_ur_fd
TRACE
	## take this opportunity to print a leading newline for tracing
	mov     $___mk_ur_n, %rsi  # string to write
	mov     $1, %rax           # write system call
	mov     $2, %rdi           # STDERR file descriptor
	mov     $1, %rdx           # length
	syscall
TRACE
___mk_ur_fd_\@:
	## read 32 bits into %eax
	mov     $0, %rax           # sys_read
	mov     ___mk_ur_fd, %rdi  # file handle to read from
	mov     $___mk_ur_rd, %rsi # read bytes into my_rd
	mov     $4, %rdx           # length
	syscall
	mov     ___mk_ur_rbx, %rbx
	mov     ___mk_ur_rcx, %rcx
	mov     ___mk_ur_rdx, %rdx
	mov     ___mk_ur_rsi, %rsi
	mov     ___mk_ur_rdi, %rdi
	mov     ___mk_ur_r8,  %r8
	mov     ___mk_ur_r9,  %r9
	mov     ___mk_ur_r10, %r10
	mov     ___mk_ur_r11, %r11
	mov     ___mk_ur_r12, %r12
	mov     ___mk_ur_rd, %rax  # move random bytes into rax
	cmp     $ADJ, %ax        # first 1/2 rand determines if unreliable
	jae     ___mk_ur_beg_\@    # jump to reliable or unreliable track
	mov     ___mk_ur_top, %rax # /- reliable path, restore rax
	xchg    %rax, (%rsp)
before\@:
	\cmd    \first, \second    # | perform the original comparison
after\@:
TRACE
	movq    $___mk_ur_r, ___mk_ur_trace # | save ASCII `r' for path tracing
TRACE
	jmp     ___mk_ur_end_\@    # \-jump past unreliable track to popf
___mk_ur_beg_\@:
	shr     $16, %rax         # discard 1/2 rand, and line up rest
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
TRACE
	movq    $___mk_ur_u, ___mk_ur_trace # save ASCII `u' for path tracing
TRACE
___mk_ur_end_\@:
TRACE
	mov     ___mk_ur_trace, %rsi # string to write
	mov     %rax, ___mk_ur_rbx # save registers clobbered by the syscall
	mov     %rdi, ___mk_ur_rdi # |
	mov     %rdx, ___mk_ur_rdx # \-
	mov     $1, %rax           # write system call
	mov     $2, %rdi           # STDERR file descriptor
	mov     $1, %rdx           # length
	syscall
	mov     ___mk_ur_rdx, %rdx # /-
	mov     ___mk_ur_rdi, %rdi # |
	mov     ___mk_ur_rbx, %rax # restore saved registers
TRACE
	mov     %rax, (%rsp)
	mov     ___mk_ur_top, %rax
	xchg    %rax, (%rsp)
DEBUG
___mk_ur_exit_\@:
DEBUG
EOF
)
\\t.endm

# replace all comparison instructions with macro calls
s/\(^[[:space:]]\)\(cmp[^[:space:]]*\)\([[:space:]]*\)/\1___mk_unreliable\3\2, \$2261, /"

if [ -z $TRACE ];then
    SED_CMD=$(echo "$SED_CMD"|sed '/^TRACE/,/^TRACE/d')
else
    SED_CMD=$(echo "$SED_CMD"|sed '/^TRACE/d')
fi

if [ -z $DEBUG ];then
    SED_CMD=$(echo "$SED_CMD"|sed '/^DEBUG/,/^DEBUG/d')
else
    SED_CMD=$(echo "$SED_CMD"|sed '/^DEBUG/d')
fi

sed $SED_OPTS "$SED_CMD" $@
# echo "$SED_CMD"
