@echo off
REM "%ALTIBASE_HOME%\bin\shmutil.exe" -e
call server stop
echo Y | rm -fr %ALTIBASE_HOME%/dbs/*
echo Y | rm -fr %ALTIBASE_HOME%/logs/*
echo Y | "%ALTIBASE_HOME%/bin/createdb" -M 4 %1 %2
