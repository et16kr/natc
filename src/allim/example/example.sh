#!/bin/sh

echo 'Cleaning up previous test'
allimctl -d
echo 'Creating new test'
allimctl -c
echo 'Launching example to create shared memory and log file'
./example
echo 'Activate limit point PREMIER and launch example'
setlimitpoint -f main.c -i PREMIER
./example
echo 'Activate limit point DERNIER with errno 17 and launch example'
setlimitpoint -f main.c -i DERNIER -e 17
./example
echo 'Activate limit point BOUCLE with errno 2 and launch example'
setlimitpoint -f main.c -i BOUCLE -e 2
./example
echo 'Activate limit point BOUCLE with errno 12, count 5 and launch example'
setlimitpoint -f main.c -i BOUCLE -e 12 -c 5
./example
echo 'Clear limit point and launch example'
setlimitpoint -k
./example

echo 'Set Hooking and waste memory to the limit'
setlimitreal -m inf -d
export LD_PRELOAD=$ATAF_TEST_CASE/src/allim/allimso/liballimso.so
./example
export LD_PRELOAD=
setlimitreal -m 0 -d
echo 'Set Hooking and makes no waste of memory'
export LD_PRELOAD=$ATAF_TEST_CASE/src/allim/allimso/liballimso.so
./example
export LD_PRELOAD=
setlimitreal -d

allimctl -d
allimctl -c

echo 'Set Hooking and waste descriptors to the limit'
setlimitreal -e inf -d
export LD_PRELOAD=$ATAF_TEST_CASE/src/allim/allimso/liballimso.so
./example
export LD_PRELOAD=
setlimitreal -d
echo 'Set Hooking and makes no waste of descriptors.'
setlimitreal -e 0 -d
export LD_PRELOAD=$ATAF_TEST_CASE/src/allim/allimso/liballimso.so
./example
export LD_PRELOAD=
setlimitreal -d
# echo 'Clearing current test'
allimctl -d
