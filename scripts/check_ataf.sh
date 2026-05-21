#!/usr/local/bin/bash

if [ $# -lt 3 ]
then
    echo "Usage : check_ataf.sh hostname userid usepasswd"
    exit;
fi

test_ataf.sh $1 $2 $3

