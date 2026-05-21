create user UPAGE identified by "1111";

grant create tablespace to UPAGE;

connect "UPAGE" / "1111"

CREATE TABLESPACE UPAGE_DATA_DTBS DATAFILE '/tmp/INC-35201' SIZE 10M AUTOEXTEND ON;
