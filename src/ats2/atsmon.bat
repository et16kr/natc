@echo off

@for /L %%N in (1 1 9999999) do (
echo "STAF_INSTANCE_NAME is %STAF_INSTANCE_NAME%"
@STAF local ats status
@sleep 1
)


