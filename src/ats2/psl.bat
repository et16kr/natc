SET BIN=%ALTIBASE_DEV%\src\pd\port\windows\bin

%BIN%\flex  -Cfar  -opsl.cpp psl.l
%BIN%\sed s,"class istream;","#include <iostream>\n\r using std::istream;\n\r using std::ostream;\n\r using std::cin;\n\r using std::cout;\n\r using std::cerr;\n\r", < psl.cpp > psl.cpp.old
echo Y | move psl.cpp.old psl.cpp
