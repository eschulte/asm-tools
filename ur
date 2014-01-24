#!/bin/sed -f
# -*- shell -*-
#
# Copyright (C) 2014 Eric Schulte
# Licensed under the Gnu Public License Version 3 or later
#
# Instrument an assembly program with assembler isntructions to make
# the resulting assembler less reliable.
1i\
\t.macro  swapit cmd, first, second\
\tcall    rand\
\tcmp     $127, %ah\
\tja      .+9\
\txor     \\first, \\second\
\txor     \\second, \\first\
\txor     \\first, \\second\
\t\\cmd   \\first, \\second\
\t.endm

# replace `cmp' with `swapcmp'
s/\(^[[:space:]]\)\(cmp[^[:space:]]*\)\([[:space:]]*\)/\1swapit\3\2, /
