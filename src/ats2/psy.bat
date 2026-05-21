SET BIN=%ALTIBASE_DEV%\src\pd\port\windows\bin

SET BISON_SIMPLE=%BIN%\bison.simple
SET BISON_HAIRY=%BIN%\bison.hairy
%BIN%\bison -d -t -v -p ps -o psy.cpp psy.y
SET BISON_SIMPLE=
SET BISON_HAIRY=
