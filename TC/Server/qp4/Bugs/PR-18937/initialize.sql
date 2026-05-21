--+SYSTEM server kill;
--+SYSTEM clean;
--+SYSTEM server start;

drop tablespace tbs1 including contents and datafiles;
drop tablespace tbs2 including contents and datafiles;
drop tablespace tbs3 including contents and datafiles;
drop tablespace tbs4 including contents and datafiles;
drop tablespace tbs5 including contents and datafiles;
drop tablespace tbs6 including contents and datafiles;
drop tablespace tbs7 including contents and datafiles;
drop tablespace tbs8 including contents and datafiles;

create tablespace tbs1 datafile 'tbs1.dbf' size 5m;
create tablespace tbs2 datafile 'tbs2.dbf' size 5m;
create tablespace tbs3 datafile 'tbs3.dbf' size 5m;
create tablespace tbs4 datafile 'tbs4.dbf' size 5m;
create tablespace tbs5 datafile 'tbs5.dbf' size 5m;
create tablespace tbs6 datafile 'tbs6.dbf' size 5m;
create tablespace tbs7 datafile 'tbs7.dbf' size 5m;
create tablespace tbs8 datafile 'tbs8.dbf' size 5m;

