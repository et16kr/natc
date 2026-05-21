#!/usr/local/bin/bash

flex  -Cfar  -opsl.cpp psl.l
sed s/"^class istream;$"/"#include <iostream.h>"/ psl.cpp > psl.cpp.old
mv psl.cpp.old psl.cpp

bison -d -t -v -p ps -o psy.cpp psy.y
sed s/"__attribute__ ((__unused__))"/"\/\/__attribute__ ((__unused__))"/ psy.cpp > psy.cpp.old
mv psy.cpp.old psy.cpp

cp psy.hpp psy.cpp.h

rm psy.hpp psy.output
