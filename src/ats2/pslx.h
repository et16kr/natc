#ifndef _O_PSLX_H_
#define _O_PSLX_H_ 1

#include <common.h>

class psLexer;
class uttMemory;

#define INNER_SEMICOLON "__$INNER_SEMICOLON$__"
#define INNER_SLASH "__$INNER_SLASH$__"

enum nodeType 
{
    TYPE_NORMAL,
    TYPE_PWAIT
};

enum elementType
{
    TYPE_SKIP, //BEGIN, END
    TYPE_IGNORE,
    TYPE_POST,
    TYPE_WAIT,
    TYPE_COMMENT,
    TYPE_SECTOR,
    TYPE_SET_ENV,
    TYPE_SYSTEM,
    TYPE_RSYSTEM,
    TYPE_APPEND_LST,
    TYPE_LOAD_SQL,
    TYPE_DECLARE,

    TYPE_CONNECT,
    TYPE_DISCONNECT,

    TYPE_INSERT,
    TYPE_SELECT,
    TYPE_TABLES,
    TYPE_XTABLES,
    TYPE_DTABLES,
    TYPE_VTABLES,
    TYPE_SEQUENCE,
    TYPE_DESC,
    TYPE_XDESC,
    TYPE_DDESC,
    TYPE_VDESC,
    TYPE_UPDATE,
    TYPE_DELETE,
    TYPE_AUTOCOMMIT,
    TYPE_SPOOL,
    TYPE_START,
    TYPE_CREATE,
    TYPE_CREATE_OBJECT,
    TYPE_MOVE,
    TYPE_COMMIT,
    TYPE_ABORT,
    TYPE_SAVEPOINT,
    TYPE_DROP,
    TYPE_GRANT,
    TYPE_REVOKE,
    TYPE_ENQUEUE,
    TYPE_DEQUEUE,
    TYPE_ALTER,
    TYPE_RENAME,
    TYPE_TRUNCATE,
    TYPE_LOCK,
    TYPE_PREPARE,
    TYPE_COMMENT_SQL,

    TYPE_SET,
    TYPE_VARIABLE,
    TYPE_PRINT,
    TYPE_SHELL,
    TYPE_EXECUTE,
    TYPE_EXECUTE_FUNCTION,
    TYPE_EXECUTE_PROCEDURE,

    TYPE_EMPTY,
    TYPE_SYNTAX_ERROR,

    TYPE_TEST_RECPTR
};

typedef struct psNamePosition
{
    SInt offset;
    SInt size;
} psNamePosition;

typedef std::map<STAFString, STAFString> KeyMap;
typedef struct psElement
{
    elementType type;     // insert, select, update, delete, system ...
    KeyMap      keyMap;   // if type is insert, (key = sql, value = sql_string) ...
} psElement;

typedef std::deque<psElement>        ElementList;
typedef std::deque<psElement>::iterator ElementIterator;
typedef struct psNode
{
    nodeType    type;    // is pwait or normal process data
    STAFString  process; // process name
    ElementList elementList;
} psNode;

typedef std::deque<psNode>           NodeList;
typedef std::deque<psNode>::iterator NodeIterator;
typedef struct psTable
 {
    NodeList       nodeList;
    SInt           nodeCursor;
    SChar         *text;
    STAFString     error;
    uttMemory     *memory;
    recPointCache *recpointCache;
} psTable;

typedef struct pslx
{
    psLexer     *lexer;
    psTable     *parseTable;

    int          type;
    int          precision;
    char         scale[128];
} pslx;

#endif
