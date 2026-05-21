#!/bin/sh
wc $* |  awk '{ print $1"    "$2"    "$3"    "$4}'
