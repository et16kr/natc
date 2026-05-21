@echo off

set ATAF_RESULT_SUFFIX=_A4_32
set ATAF_ORACLE_SUFFIX=_A4_64,_WIN_NT_A4_64,_A4_32,_WIN_NT_A4_32

altibase -v | findstr /c:"64bit" > NUL
if %errorlevel% equ 0 set ATAF_RESULT_SUFFIX=_A4_64
if %errorlevel% equ 0 set ATAF_ORACLE_SUFFIX=_A4_64,_WIN_NT_A4_64

set lang=%LANG%
if "%lang%"=="" %then% goto error_lang

set arg1=%1
set arg2=%2
set arg3=%3

if "%arg1%"=="" %then% goto error_usage 

if "%arg2%"=="" %then% goto run1 

if "%arg3%"=="" %then% goto run2 

if "%arg2%"=="--skip" %then% goto run3 %else% goto error_skip

:run1
set CommonCase=%1
set MyCase=%1
set SkipCase=none
set ArgCnt=2 
goto real

:run2
set CommonCase=%1
set MyCase=%2
set SkipCase=none
set ArgCnt=2
goto real

:run3
set CommonCase=%1
set MyCase=%1
set SkipCase=%3
set ArgCnt=1

:real

rm -rf %ATAF_TEST_RESULT%/work/*
mkdir "%ATAF_TEST_RESULT%/work/log"
altibase -v > %ATAF_TEST_RESULT%/work/altibase.info

cmd /c is -silent -f %ATAF_TEST_CASE%/scripts/system-default-properties.sql

atsc -c %CommonCase% -m %MyCase% -l %lang% -n %ArgCnt% -i %SkipCase%
goto done

:error_lang
echo "Please set environment variable LANG"
goto done

:error_skip
echo "Usage: atsclnt CommonCase --skip SkipCase"
goto done

:error_usage
echo "Usage: atsclnt CommonCase [MyCase]"
goto done

:done
