--############################################################################
--# Replication Environment Setting
--############################################################################

--############################################################################
--# SET UP three DB System
--############################################################################

--+DECLARE SERVER REPL_SERVER4 DB4;

--+DECLARE CLIENT DEFAULT P41 (SERVER=DB4);

--+SET_ENV PATH=$ATC_HOME/scripts:$PATH;
--+SET_ENV ALTIBASE_REPLICATION_LOCK_TIMEOUT=30;

--+PROCESS P41;

--########################################
--# Set Up DB 4
--########################################

--+SET_ENV @DB4 PATH=$ATC_HOME/scripts:$PATH;
--+SET_ENV @DB4 ALTIBASE_REPLICATION_LOCK_TIMEOUT=30;

--+SYSTEM rm -rf $ATAF_TEST_RESULT/TC/Server/repl4/db4;

--+SYSTEM mkdir $ATAF_TEST_RESULT/TC/Server/repl4/db4;
--+SYSTEM ln -s $ALTIBASE_HOME/bin                      $ATAF_TEST_RESULT/TC/Server/repl4/db4/bin;
--+SYSTEM ln -s $ALTIBASE_HOME/msg                      $ATAF_TEST_RESULT/TC/Server/repl4/db4/msg;
--+SYSTEM ln -s $ALTIBASE_HOME/dlib                     $ATAF_TEST_RESULT/TC/Server/repl4/db4/dlib;
--+SYSTEM ln -s $ALTIBASE_HOME/install                  $ATAF_TEST_RESULT/TC/Server/repl4/db4/install;
--+SYSTEM ln -s $ALTIBASE_HOME/include                  $ATAF_TEST_RESULT/TC/Server/repl4/db4/include;
--+SYSTEM ln -s $ALTIBASE_HOME/lib                      $ATAF_TEST_RESULT/TC/Server/repl4/db4/lib;

--+SYSTEM mkdir $ATAF_TEST_RESULT/TC/Server/repl4/db4/conf;
--+SYSTEM cp -f $ALTIBASE_HOME/conf/altibase.properties $ATAF_TEST_RESULT/TC/Server/repl4/db4/conf;
--+SYSTEM cp -f $ALTIBASE_HOME/conf/license             $ATAF_TEST_RESULT/TC/Server/repl4/db4/conf;

--+SYSTEM mkdir $ATAF_TEST_RESULT/TC/Server/repl4/db4/dbs;
--+SYSTEM mkdir $ATAF_TEST_RESULT/TC/Server/repl4/db4/logs;
--+SYSTEM mkdir $ATAF_TEST_RESULT/TC/Server/repl4/db4/trc;
--+SYSTEM mkdir $ATAF_TEST_RESULT/TC/Server/repl4/db4/arch_logs;

--+SYSTEM @DB4 server kill;
--+SYSTEM @DB4 echo y | shmutil -e;
--+SYSTEM @DB4 echo y | destroydb -n mydb;
--+SYSTEM @DB4 echo y | createdb -M 10;

--+SYSTEM @DB4 server start;


--+PWAIT;

