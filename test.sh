#!/bin/bash
#
# Run tests of ur.
#

## setup
pushd etc/ >/dev/null
make stack-ur >/dev/null

## tests

# stack
./stack-ur
if [ $? -eq 12 ];then
    echo -n PASS
else
    echo -n FAIL
fi
echo " stack preservation across macro"

# registers
for reg in ebx ecx edx esi edi;do
    cat register.s|sed "s/reg/$reg/"|gcc -x assembler - -o reg-$reg
    ./reg-$reg
    if [ $? -eq 12 ];then
        echo -n PASS
    else
        ./reg-$reg
        echo -n "FAIL '$?'!='12'"
    fi
    echo " register $reg preservation across macro"
done

## close up
popd  >/dev/null
