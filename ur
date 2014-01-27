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

ADJUSTED=$(echo "scale=0;((1 - $RATE) * 255)/1"|bc)

SED_CMD="1i\\
\\
\\t.macro  swapit cmd, first, second\\
\\tcall    rand\\
\\tcmp     \$$ADJUSTED, %ah\\
\\tja      .+8\\
\\t\\\\cmd   \\\\first, \\\\second\\
\\tpushf\\
\\tjmp     .+6\\
\\t\\\\cmd   \\\\second, \\\\first\\
\\tpushf\\
\\t.endm\\
\\
# This second macro uses \reg to hold the first operand to \cmd,\\
# necessary in case \first is not a register because the second\\
# (i.e. \first after the swap) operand to many values of \cmd (e.g.,\\
# cmpl) *must* be a register.\\
\\
\\t.macro  moveit reg, cmd, first, second\\
\\tcall    rand\\
\\tcmp     \$$ADJUSTED, %ah\\
\\tja      .+9\\
\\t\\\\cmd   \\\\first, \\\\second\\
\\tpushf\\
\\tjmp     .+26\\
\\tpushl   \\\\reg\\
\\t\\\\cmd   \\\\second, \\\\reg\\
\\tpopl    \\\\reg\\
\\tpushf\\
\\tpopf\\
\\t.endm
"

# replace `cmp*' with `swapcmp*'
SED_CMD+="s/\(^[[:space:]]\)\(cmp[^[:space:]]*\)\([[:space:]]*\)/\1swapit\3\2, /"

sed $SED_OPTS "$SED_CMD" $@
