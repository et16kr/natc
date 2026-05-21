@echo off

set command=%1
set option=%2

if "%STAF_INSTANCE_NAME%"=="" %then% goto error 

if "%option%"=="" %then% set option=%ATAF_TEST_CASE%/bin/STAF_win32.cfg

echo "STAF_INSTANCE_NAME is %STAF_INSTANCE_NAME% (%option%)"

if "%command%"=="start" %then% goto start
if "%command%"=="stop" %then% goto stop 
if "%command%"=="status" %then% goto status 
if "%command%"=="ats_status" %then% goto ats_status 
if "%command%"=="version" %then% goto version 
if "%command%"=="kill" %then% goto kill 

echo "Usage: %0 { start | stop | kill | status | version }"

goto done

:start
STAFProc %option% 
goto done

:stop
STAF local shutdown shutdown 
goto done

:status
STAF local service list 
goto done

:ats_status
STAF local ats status 
goto done

:version
STAF local ats version 
goto done

:kill
STAF local ats kill 
goto done

:error
echo "Please set environment variable STAF_INSTANCE_NAME"
goto done

:done
