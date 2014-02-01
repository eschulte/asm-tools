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
	.section	.data
___mk_ur_fp:    .string "/dev/urandom"
___mk_ur_fd:    .int 0
___mk_ur_rd:    .quad 0
	.macro ___mk_unreliable cmd, mask, first, second
DEBUG
___mk_ur_enter_\@:
DEBUG
	push    %rax
	push    %rdx
	push    %rsi
	push    %rdi
	mov     ___mk_ur_fd, %rax
	cmp     $0, %rax
	jne     ___mk_ur_fd_\@
	## open /dev/urandom for reading
	mov     $2, %rax        # sys_open
 	mov	$0, %rsi        # O_RDONLY
 	mov	$___mk_ur_fp, %rdi # file name
	syscall
	mov     %rax, ___mk_ur_fd
___mk_ur_fd_\@:
	## read 32 bits into %eax
	mov     $0, %rax           # sys_read
	mov     ___mk_ur_fd, %rdi  # file handle to read from
	mov     $___mk_ur_rd, %rsi # read bytes into my_rd
	mov     $4, %rdx           # length
	syscall
	pop     %rdi
	pop     %rsi
	pop     %rdx
	mov     ___mk_ur_rd, %eax # move random bytes into eax
	cmp     $65535, %ax       # first 1/2 rand determines if unreliable
	jae     ___mk_ur_beg_\@   # jump to reliable or unreliable track
	pop     %rax              # /- reliable path, restore rax
	\cmd    \first, \second   # | perform the original comparison
	pushf                     # | save original flags
TRACE
	push    $___mk_ur_r       # | save ASCII `r' reliable path for tracing
TRACE
	jmp     ___mk_ur_end_\@   # \-jump past unreliable track to popf
___mk_ur_beg_\@:
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
