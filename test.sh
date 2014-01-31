#!/bin/bash
#
# Run tests of ur.
#

## setup
pushd etc/ >/dev/null
make stack-ur >/dev/null

## tests
./stack-ur
if [ $? -eq 12 ];then
    echo PASS stack
else
    echo FAIL stack
fi

## close up
popd  >/dev/null
