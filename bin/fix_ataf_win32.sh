#!/usr/local/bin/bash

WORK_HOME=work_ataf

. /cygdrive/c/$WORK_HOME/ataf/env/env.win32.sh

LOG=c:/$WORK_HOME/fix_ataf.log
ATAF_HOME=c:/$WORK_HOME/ataf_home

cleanup()
{
    echo "cleanup..."
    rm -rf $LOG 
        
    echo "[pass] cleanup"
}

svn_up_altidev4()
{
    echo "svn_up_altidev4..."

    if [ -d c:/$WORK_HOME/altidev4 ]
    then
        cd c:/$WORK_HOME/altidev4
        svn cleanup >> $LOG 2>> $LOG
        svn up >> $LOG 2>> $LOG
    else
        cd c:/$WORK_HOME
        svn co svn://svn.altibase.local/opt/svnrepos/altidev4/trunk altidev4
    fi

    if [ $? == 0 ] 
    then
        echo "[pass] svn up altidev4"
    else
        echo "[erro] svn up altidev4"
        exit
    fi
}

svn_up_ataf()
{
    echo "svn_up_ataf..."

    if [ -d c:/$WORK_HOME/ataf ]
    then
        cd c:/$WORK_HOME/ataf
        svn cleanup >> $LOG 2>> $LOG
        svn up >> $LOG 2>> $LOG
    else
        cd c:/$WORK_HOME
        svn co svn://svn.altibase.local/opt/svnrepos/ataf/trunk ataf 
    fi

    if [ $? == 0 ] 
    then
        echo "[pass] svn up ataf"
    else
        echo "[erro] svn up ataf"
        exit
    fi
}

build_altidev4_for_ataf()
{
    echo "build_altidev4_for_ataf..."
    cd c:/$WORK_HOME/altidev4
    ./configure     >> $LOG 2>> $LOG
    make clean      >> $LOG 2>> $LOG
    make build_ataf >> $LOG 2>> $LOG

    if [ $? == 0 ] 
    then
        echo "[pass] build altidev4"
    else
        echo "[erro] build altidev4"
        exit
    fi
}

build_ataf()
{
    echo "build_ataf..."
    cd c:/$WORK_HOME/ataf
    rm -fr obj  
    ./sync.sh                    >> $LOG 2>> $LOG
    rm -rf obj rel               >> $LOG 2>> $LOG
#    make_cygwin -f makefile.real >> $LOG 2>> $LOG
    make_cygwin -f makefile.real
    #make_cygwin clean >> $LOG 2>> $LOG
    #make_cygwin       >> $LOG 2>> $LOG

    if [ $? == 0 ] 
    then
        echo "[pass] build ataf"
    else
        echo "[erro] build ataf"
        exit
    fi
}

make_dist()
{
    echo "make_dist..."
    cd c:/$WORK_HOME/ataf
    rm -rf *.tgz  >> $LOG 2>> $LOG
    make dist >> $LOG 2>> $LOG

    if [ $? == 0 ] 
    then
        echo "[pass] make dist"
    else
        echo "[erro] make dist"
        exit
    fi
}

fix_ataf_home()
{
    echo "fix_ataf_home"
    cd c:/$WORK_HOME/ataf

    cp -r rel/win32/staf/retail/* c:/ataf_home

    if [ $? == 0 ] 
    then
        echo "[pass] fix ataf_home"
    else
        echo "[erro] fix ataf_home"
        exit
    fi

    cd c:/ataf_home

    cp $ALTIBASE_HOME/lib/altiutil_sl.dll lib 
    cp $ALTIBASE_HOME/lib/odbccli_sl.dll lib 
    cp $ALTIBASE_HOME/lib/ispapi_sl.dll lib 
    cp lib/* bin 

    mkdir data >> $LOG 2>> $LOG
    chmod a+rwx -R . >> $LOG 2>> $LOG
}

cleanup

svn_up_ataf

build_ataf

fix_ataf_home
