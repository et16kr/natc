#!/usr/local/bin/bash

. $HOME/.bashrc

LOG=$HOME/restart.cron
ATAF_HOME=$HOME/ataf_home

mv $LOG $HOME/restart.cron.log

kill_ataf()
{
    echo "[ataf kill]" >> $LOG 2>> $LOG
    ps -ef | grep STAFProc | grep `whoami` | awk '{print $2}' | xargs -n1 kill -9 >> $LOG 2>> $LOG
    ps -ef | grep STAFJVM | grep `whoami` | awk '{print $2}' | xargs -n1 kill -9 >> $LOG 2>> $LOG
}

stop_ataf()
{
    echo "[ataf stop]" >> $LOG 2>> $LOG
    ataf stop >> $LOG 2>> $LOG
}

start_ataf()
{
    echo "[ataf start $STAF_HOME/bin/STAF_$LOGNAME.cfg]" >> $LOG 2>> $LOG
    ataf start $STAF_HOME/bin/STAF_$LOGNAME.cfg >> $LOG 2>> $LOG
}

stop_ataf
sleep 30 

kill_ataf
sleep 30 

start_ataf
