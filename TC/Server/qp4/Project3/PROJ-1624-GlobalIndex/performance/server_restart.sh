#!/usr/local/bin/bash

export ALTIBASE_BUFFER_AREA_SIZE=536870912

server kill
clean
server start;
