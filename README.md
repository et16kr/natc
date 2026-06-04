# NATC 테스트 실행

## Clone

```sh
mkdir -p "$HOME/work"

git clone git@192.168.3.201:altibase/ataf.git "$HOME/work/ataf"
git clone git@192.168.3.201:altibase/natc.git "$HOME/work/natc"
```

```sh
git -C "$HOME/work/ataf" pull
git -C "$HOME/work/natc" pull
```

## Environment

```sh
export LANG=C
export OS_NAME=linux

export ATAF_SRC_HOME="$HOME/work/ataf"
export ATAF_HOME="$ATAF_SRC_HOME/ataf_home"
export STAF_HOME="$ATAF_HOME"
export STAF_INSTANCE_NAME="STAF_${LOGNAME}"

export ATAF_TEST_CASE="$HOME/work/natc"
export ATAF_TEST_RESULT="$ATAF_TEST_CASE"
export ATC_HOME="$ATAF_TEST_CASE"
export ATC_WORK="$ATAF_TEST_RESULT/work"

export ALTIBASE_DEV="$HOME/work/altidev4"
export ALTIBASE_HOME="$ALTIBASE_DEV/altibase_home"
export ALTIBASE_PORT_NO=20570
export ALTIBASE_IPC_PORT_NO=20571
export ALTIBASE_NLS_USE=KO16KSC5601

export PATH="$ATAF_HOME/bin:$ATAF_TEST_CASE/bin:$ATAF_TEST_CASE/scripts:$ALTIBASE_HOME/bin:$PATH"
export LD_LIBRARY_PATH="$ATAF_HOME/lib:$ATAF_TEST_CASE/lib:$ALTIBASE_HOME/lib:${LD_LIBRARY_PATH:-}"
export LD_LIBRARY_PATH_64="$ATAF_HOME/lib:$ATAF_TEST_CASE/lib:$ALTIBASE_HOME/lib:${LD_LIBRARY_PATH_64:-}"
export SHLIB_PATH="$LD_LIBRARY_PATH:${SHLIB_PATH:-}"
```

```sh
test -x "$ATAF_HOME/bin/ataf"
test -x "$ATAF_HOME/bin/atsclnt"
test -x "$ALTIBASE_HOME/bin/altibase"

command -v ataf
command -v atsclnt
command -v altibase
```

## Run

```sh
ataf start
```

```sh
atsclnt "$ATAF_TEST_CASE/TC/path/to/testcase.ts"
```

```sh
tail -f "$ATC_WORK/log/report.log"
```

```sh
ataf stop
```

## Build

```sh
make -C "$ATAF_TEST_CASE/src/ats2" install OS_NAME=linux
make -C "$ATAF_TEST_CASE/src/atsclnt" install OS_NAME=linux
make -C "$ATAF_TEST_CASE/src" install
```
