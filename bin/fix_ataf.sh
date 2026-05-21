#!/usr/local/bin/bash

. $HOME/.bashrc

export ALTIBASE_DEV=$ALTIDEV_HOME

export PATH=.:$PATH

LOG=$HOME/fix_ataf.cron
ATAF_HOME=$HOME/ataf_home

cleanup()
{
    echo "cleanup..."
    rm -rf $LOG 
        
    echo "[pass] cleanup"
}

svn_up_altidev4()
{
    echo "svn_up_altidev4..."

    if [ -d $HOME/work/altidev4 ]
    then
        cd $HOME/work/altidev4
        svn cleanup >> $LOG 2>> $LOG
        svn up >> $LOG 2>> $LOG
    else
        cd $HOME/work
        svn co svn://svn.altibase.local/altidev4/trunk altidev4
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

    if [ -d $HOME/work/ataf ]
    then
        cd $HOME/work/ataf
        svn cleanup >> $LOG 2>> $LOG
        svn up >> $LOG 2>> $LOG
    else
        cd $HOME/work
        svn co svn://svn.altibase.local/ataf/trunk ataf 
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
    cd $HOME/work/altidev4
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
    cd $HOME/work/ataf
    rm -fr obj  
    make clean >> $LOG 2>> $LOG
    make       >> $LOG 2>> $LOG

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
    cd $HOME/work/ataf
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
    cd $HOME/work/ataf

    mkdir -p $ATAF_HOME  >> $LOG 2>> $LOG
    if [ $? != 0 ] 
    then
        echo "[erro] fix ataf_home"
        exit
    fi

    rm -rf $ATAF_HOME/*.tgz >> $LOG 2>> $LOG
    if [ $? != 0 ] 
    then
        echo "[erro] fix ataf_home"
        exit
    fi


    mv *.tgz $ATAF_HOME  >> $LOG 2>> $LOG
    if [ $? != 0 ] 
    then
        echo "[erro] fix ataf_home"
        exit
    fi


    cd $ATAF_HOME  >> $LOG 2>> $LOG
    if [ $? != 0 ] 
    then
        echo "[erro] fix ataf_home"
        exit
    fi


    # fix for AIX resource busy problem
    rm -rf lib/*

    gzip -cd *.tgz | tar -xvf - >> $LOG 2>> $LOG

    if [ $? == 0 ] 
    then
        echo "[pass] fix ataf_home"
    else
        echo "[erro] fix ataf_home"
        exit
    fi

    mkdir data >> $LOG 2>> $LOG
    chmod a+rwx data >> $LOG 2>> $LOG
}

delete_id_header_files()
{
    echo "delete idl.h, idl.i, idConfig.h \n"
    rm -f $HOME/work/natc_today/include/idl.h
    rm -f $HOME/work/natc_today/include/idl.i
    rm -f $HOME/work/natc_today/include/idConfig.h
    rm -f $HOME/work/natc/include/idl.h
    rm -f $HOME/work/natc/include/idl.i
    rm -f $HOME/work/natc/include/idConfig.h
}

cleanup

svn_up_altidev4
svn_up_ataf

build_altidev4_for_ataf
build_ataf

make_dist
delete_id_header_files
fix_ataf_home
