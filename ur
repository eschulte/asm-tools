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
  -i[SUFFIX] -------- edit file in place (w/back if SUFFIX)
  -n ---------------- expand in place, no ASM macros"
eval set -- $(getopt hr:in "$@" || echo "$HELP" && exit 1;)
RATE=0.1
SED_OPTS=" "
IN_PLACE=""
while [ $# -gt 0 ];do
    case $1 in
        -h)  echo "$HELP" && exit 0;;
        -r)  RATE=$2; shift;;
        -i*) SED_OPTS+="$1 ";;
        -n)  IN_PLACE="YES";;
        (--) shift; break;;
        (-*) echo "$HELP" && exit 1;;
        (*)  break;;
    esac
    shift
done

if [ -z $IN_PLACE ];then
    SED_CMD="1i\\
\\t.macro  swapit cmd, first, second\\
\\tcall    rand\\
\\tcmp     \$$(echo "scale=0;((1 - $RATE) * 255)/1"|bc), %ah\\
\\tja      .+8\\
\\t\\\\cmd   \\\\first, \\\\second\\
\\tpushf\\
\\tjmp     .+6\\
\\t\\\\cmd   \\\\second, \\\\first\\
\\tpushf\\
\\tpopf\\
\\t.endm
"
    # replace `cmp*' with `swapcmp*'
    SED_CMD+="s/\(^[[:space:]]\)\(cmp[^[:space:]]*\)\([[:space:]]*\)/\1swapit\3\2, /"
else
    SED_CMD="$(echo "s/\(^[[:space:]]\)\(cmp[^[:space:]]*\)[[:space:]]\([^[:space:],]\+\),\+[[:space:]]\+\([^[:space:]]\+\)/\1call    rand\\
\1cmp     \$$(echo "scale=0;((1 - $RATE) * 255)/1"|bc), %ah\\
\1ja      .+8\\
\1\2   \3, \4\\
\1pushf\\
\1jmp     .+6\\
\1\2   \4, \3\\
\1pushf\\
\1popf\\
/")"
fi

sed $SED_OPTS "$SED_CMD" $@
