--+SYSTEM server kill;
--+SYSTEM echo y | shmutil -e;
--+SYSTEM echo y | destroydb -n mydb;
--+SYSTEM echo y | createdb -M 10;

--+SYSTEM diskMode.sh;
--+SYSTEM server start;
