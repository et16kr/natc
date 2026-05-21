#!/bin/sh
allimctl -c
export LD_PRELOAD=$ATC_HOME/lib/liballimso.so
server start
export LD_PRELOAD=
