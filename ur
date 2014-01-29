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
  -r RATE ----------- set RATE of unreliable computation
  -i[SUFFIX] -------- edit file in place (w/back if SUFFIX)"
eval set -- $(getopt hir: "$@" || echo "$HELP" && exit 1;)
RATE=0.1
SED_OPTS=" "
while [ $# -gt 0 ];do
    case $1 in
        -h)  echo "$HELP" && exit 0;;
        -r)  RATE=$2; shift;;
        -i*) SED_OPTS+="$1 "; break;;
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
	.macro ___mk_unreliable cmd, mask, first, second
	push    %rax              # save original value of rax
	call    random            # place a random number in eax
	cmp     $ADJ, %ax         # first 1/2 rand determines if unreliable
	jae     .+9               # jump to reliable or unreliable track
	pop     %rax              # /-reliable track
	\cmd    \first, \second   # | perform the original comparison
	pushf                     # | save original flags
	jmp     .+51              # \-jump past unreliable track to popf
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
	popf                      # apply flags and restore stack
EOF
)
\\t.endm

# replace all comparison instructions with macro calls
s/\(^[[:space:]]\)\(cmp[^[:space:]]*\)\([[:space:]]*\)/\1___mk_unreliable\3\2, \$2261, /

# seed the random number generator before the first macro invocation
0,/___mk_unreliable/{s/___mk_unreliable/push    %rdi\\
	push    %rax\\
	mov     \$0, %rdi\\
	call    time\\
	mov     %rax, %rdi\\
	mov     \$0x14, %eax\\
	int     \$0x80\\
	xor     %eax, %edi\\
	call    srandom\\
	pop     %rax\\
	pop     %rdi\\
	___mk_unreliable/}"

sed $SED_OPTS "$SED_CMD" $@
# echo "$SED_CMD"
