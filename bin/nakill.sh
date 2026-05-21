#/bin/sh

if [ "$OS_NAME" = "win32" ]; then
taskkill /F /FI "USERNAME eq $USERNAME" /IM altibase.exe;
taskkill /F /FI "USERNAME eq $USERNAME" /IM isql.exe;
taskkill /F /FI "USERNAME eq $USERNAME" /IM ALA.exe;
closehandle.py altibase_home
else
ps -ef | grep altibase | grep `whoami` | awk '{print $2}' | xargs -n1 kill -9;
ps -ef | grep isql | grep `whoami` | awk '{print $2}' | xargs -n1 kill -9;
ps -ef | grep ALA | grep `whoami` | awk '{print $2}' | xargs -n1 kill -9;
fi
