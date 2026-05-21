#!/usr/local/bin/bash
# File Separator를 Platform에 관계없이
# 동일하게 만들어 주는 스크립트로
# Windows에서 '\'로 출력하는 File Separator를
# '/'로 변경해 준다.
#
# NATC는 Platform에 관계없이 $ALTIBASE_HOME등 몇 개의 환경변수의
# File Separator를 '/'로 변경해서 출력하기 때문에
# NATC diff를 방지하기 위해서는 이 스크립트를 사용해야 한다.
#

sed -e 's/\\/\//g'
