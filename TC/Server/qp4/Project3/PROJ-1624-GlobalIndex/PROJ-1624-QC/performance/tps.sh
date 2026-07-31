#!/usr/local/bin/bash

# TPS를 계산한다.
grep TPS test.log  | awk 'BEGIN { total=0; } { total=total+$5; } END { print  total }'
