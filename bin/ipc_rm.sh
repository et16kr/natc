#!/usr/local/bin/bash

    for i in `ipcs -pbs | grep $LOGNAME | awk ' { printf("%s ",$2); }'`; do ipcrm -s $i; done;
    for i in `ipcs -pbm | grep $LOGNAME | awk ' { printf("%s ",$2); }'`; do ipcrm -m $i; done;
