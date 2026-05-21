# 테스트 케이스를 실행하는 디렉토리에 test 디렉토리를 만들고 isql 실행파일을 
# 복사해야 한다.

--+RSYSTEM target1 mkdir abc;

--+RSYSTEM target1 put test/isql abc;

--+RSYSTEM target1 copy abc/isql abc/isql2;

--+RSYSTEM target1 delete abc/isql;

--+RSYSTEM target1 get abc/isql2;

--+RSYSTEM target1 delete abc/isql2;

--+RSYSTEM target1 rmdir abc;

--+RSYSTEM target1 execute /server args start return stdout;

--+RSYSTEM target1 execute /server args stop return stdout;
