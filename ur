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
  -i[SUFFIX] -------- edit file in place (optional backup at SUFFIX)"
eval set -- $(getopt hu:tdi:: "$@" || echo "$HELP" && exit 1;)
RATE=0.1
SED_OPTS=" "
DEBUG=""
TRACE=""
while [ $# -gt 0 ];do
    case $1 in
        -h)  echo "$HELP" && exit 0;;
        -u)  RATE=$2; shift;;
        -t)  TRACE="yes";;
        -d)  DEBUG="yes";;
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
$(cat <<"EOF"|sed 's/\\/\\\\/g;s/\t/\\t/g;s/$/\\/;'|sed "s/ADJ/$ADJ/"
TRACE
	.section	.rodata
___mk_ur_u:	.ascii "u"
___mk_ur_r:	.ascii "r"
TRACE
	.macro ___mk_unreliable cmd, mask, first, second
DEBUG
___mk_ur_enter_\@:
DEBUG
	push    %rax              # /-88 save scratch registers
	push    %rbx              # | 80
	push    %rcx              # | 72
	push    %rdx              # | 64
	push    %rsi              # | 56
	push    %rdi              # | 48
	push    %r8               # | 40
	push    %r9               # | 32
	push    %r10              # | 24
	push    %r11              # | 16
	push    %r12              # | 8
	call    random            # place a random number in eax
	cmp     $65535, %ax       # first 1/2 rand determines if unreliable
	pushf                     # push flags to stack
	mov     8(%rsp), %r12     # | restore, offset by 8 from preceeding pushf
	mov     16(%rsp), %r11    # |
	mov     24(%rsp), %r10    # |
	mov     32(%rsp), %r9     # |
	mov     40(%rsp), %r8     # |
	mov     48(%rsp), %rdi    # |
	mov     56(%rsp), %rsi    # |
	mov     64(%rsp), %rdx    # |
	mov     72(%rsp), %rcx    # |
	mov     80(%rsp), %rbx    # \- restore scratch registers
	popf                      # restore comparison flags
	jae     ___mk_ur_beg_\@   # jump to reliable or unreliable track
	add     $80, %rsp         # /- reliable track: move stack pointer to rax
	pop     %rax              # | restore rax
	\cmd    \first, \second   # | perform the original comparison
	pushf                     # | save original flags
TRACE
        push    $___mk_ur_r       # | save ASCII `r' reliable path for tracing
TRACE
	jmp     ___mk_ur_end_\@   # \-jump past unreliable track to popf
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
TRACE
        push    $___mk_ur_u       # save ASCII `u' unreliable path for tracing
TRACE
___mk_ur_end_\@:
TRACE
        pop     %rsi              # string to write
        push    %rax              # save registers clobbered by the syscall
        push    %rdi              # |
        push    %rdx              # \-
	mov     $1, %rax          # write system call
        mov     $2, %rdi          # STDERR file descriptor
        mov     $1, %rdx          # length
        syscall
        pop     %rdx              # /-
        pop     %rdi              # |
        pop     %rax              # restore saved registers
TRACE
	popf                      # apply flags and restore stack
DEBUG
___mk_ur_exit_\@:
DEBUG
EOF
)
\\t.endm

# replace all comparison instructions with macro calls
s/\(^[[:space:]]\)\(cmp[^[:space:]]*\)\([[:space:]]*\)/\1___mk_unreliable\3\2, \$2261, /

# seed the random number generator before the first macro invocation
0,/___mk_unreliable/{s/\t___mk_unreliable/$(cat <<"EOF"|sed 's/\\/\\\\/g;s|/|\\/|g;s/\t/\\t/g;s/$/\\/;'
	push    %rax            # /- save scratch registers
	push    %rbx            # |
	push    %rcx            # |
	push    %rdx            # |
	push    %rsi            # |
	push    %rdi            # |
	push    %r8             # |
	push    %r9             # |
	push    %r10            # |
	push    %r11            # |
	push    %r12            # |
	mov     $0, %rdi        #
	call    time            # time(NULL)
	mov     %rax, %rdi      #
	mov     $39, %eax       # getpid system call
	syscall                 #
	xor     %eax, %edi      # mix time and pid for random seed
	call    srandom         # srandom
	pop     %r12            # |
	pop     %r11            # |
	pop     %r10            # |
	pop     %r9             # |
	pop     %r8             # |
	pop     %rdi            # |
	pop     %rsi            # |
	pop     %rdx            # |
	pop     %rcx            # |
	pop     %rbx            # |
	pop     %rax            # \- save scratch registers
EOF
)
\\t___mk_unreliable/}"

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
