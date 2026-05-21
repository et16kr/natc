#STAF local ads run "select * from tab" dsn 127.0.0.1 user sys passwd manager nls_use us7ascii conntype tcp

a="drop table t1"
STAF local ads run $a dsn 127.0.0.1 user sys passwd manager nls_use us7ascii conntype tcp
a="create table t1 ( a double )"
STAF local ads run $a dsn 127.0.0.1 user sys passwd manager nls_use us7ascii conntype tcp
a="insert into t1 values ( 1 )"
STAF local ads run $a dsn 127.0.0.1 user sys passwd manager nls_use us7ascii conntype tcp
a="insert into t1 values ( 1 )"
STAF local ads run $a dsn 127.0.0.1 user sys passwd manager nls_use us7ascii conntype tcp
a="insert into t1 values ( 1 )"
STAF local ads run $a dsn 127.0.0.1 user sys passwd manager nls_use us7ascii conntype tcp

a="update t1 set a = 999"
STAF local ads run $a dsn 127.0.0.1 user sys passwd manager nls_use us7ascii conntype tcp

STAF local ads run "select * from t1" dsn 127.0.0.1 user sys passwd manager nls_use us7ascii conntype tcp

a="delete from t1"
STAF local ads run $a dsn 127.0.0.1 user sys passwd manager nls_use us7ascii conntype tcp


STAF local ads run "select * from t1" dsn 127.0.0.1 user sys passwd manager nls_use us7ascii conntype tcp
