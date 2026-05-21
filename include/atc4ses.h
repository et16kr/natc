#ifndef _O_ATC4SES_H_
#define _O_ATC4SES_H_ 1

#include <idl.h>
#include <idtBaseThread.h>

#define STR_LEN 256

#define ATC_EVAL_DETAIL(exp, msg)  if (exp)           \
                             {                        \
                               fprintf(stdout,        \
                               "SUCCESS: (%s) %s\n",  \
                               __FILE__,              \
                               #msg );                \
                             }                        \
                             else                     \
                             {                        \
                               fprintf(stdout,        \
                               "FAILURE: (%s:%d) %s\n", \
                               __FILE__,              \
                               __LINE__,              \
                               #msg );                \
                             }                        \
                             if (ssqlca.sqlcode != SQL_SUCCESS)\
                             {                                 \
                                 fprintf(stdout,               \
                                         "[ SQLCODE = %d, "    \
                                         "SQLSTATE = %s, "     \
                                         "ERR_MSG = %s ]\n",   \
                                         SQLCODE,              \
                                         SQLSTATE,             \
                                         ssqlca.sqlerrm.sqlerrmc);\
                             }

#define ATC_EVAL_DETAIL_NL(exp, msg)  if (exp)           \
                             {                        \
                               fprintf(stdout,        \
                               "SUCCESS: %s\n", \
                               #msg );                \
                             }                        \
                             else                     \
                             {                        \
                               fprintf(stdout,        \
                               "FAILURE: %s\n", \
                               #msg );                \
                             }                        \
                             if (ssqlca.sqlcode != SQL_SUCCESS)\
                             {                                 \
                                 fprintf(stdout,               \
                                         "[ SQLCODE = %d, "    \
                                         "SQLSTATE = %s, "     \
                                         "ERR_MSG = %s ]\n",   \
                                         SQLCODE,              \
                                         SQLSTATE,             \
                                         ssqlca.sqlerrm.sqlerrmc);\
                             }

#define ATC_RESULT()  if (ssqlca.sqlcode != SQL_SUCCESS)\
                             {                                 \
                                 fprintf(stdout,               \
                                         "[ SQLCODE = %d, "    \
                                         "SQLSTATE = %s, "     \
                                         "ERR_MSG = %s ]\n",   \
                                         SQLCODE,              \
                                         SQLSTATE,             \
                                         ssqlca.sqlerrm.sqlerrmc);\
                             }

#define ATC_RESULT_TEST(exp) if (exp)                 \
                             {                        \
                               fprintf(stdout,        \
                               "SUCCESS: \n");        \
                             }                        \
                             else                     \
                             {                                    \
                                 fprintf(stdout,                  \
                                         "FAILURE: (%s:%d) : ,    \
                                         [ SQLCODE = %d,          \
                                         SQLSTATE = %s,           \
                                         ERR_MSG = %s ]\n",       \
                                         __FILE__,                \
                                         __LINE__,                \
                                         SQLCODE,                 \
                                         SQLSTATE,                \
                                         ssqlca.sqlerrm.sqlerrmc);\
                             }
#define ATC_RESULT_TEST_NL(exp) if (exp)                 \
                             {                        \
                               fprintf(stdout,        \
                               "SUCCESS: \n");        \
                             }                        \
                             else                     \
                             {                                    \
                                 fprintf(stdout,                  \
                                         "FAILURE:     \
                                         [ SQLCODE = %d,          \
                                         SQLSTATE = %s,           \
                                         ERR_MSG = %s ]\n",       \
                                         SQLCODE,                 \
                                         SQLSTATE,                \
                                         ssqlca.sqlerrm.sqlerrmc);\
                             }



#define ATC_SECTOR( msg )                                                     \
( fprintf(stdout,                                                             \
"\n\n"                                                                        \
"+-------------------------------------------------------------------+\n"     \
"--+SECTOR; (%s) %s\n"                                                     \
"+-------------------------------------------------------------------+\n"     \
"\n", __FILE__, #msg ) )

#define ATC_MSG(msg) ( fprintf(stdout,#msg) )

#define ATC_EVAL(exp)        if (exp)                 \
                             {                        \
                               fprintf(stdout,        \
                               "SUCCESS: (%s)\n",     \
                               __FILE__);             \
                             }                        \
                             else                     \
                             {                        \
                               fprintf(stdout,        \
                               "FAILURE: (%s:%d)\n",  \
                               __FILE__,              \
                               __LINE__ );            \
                             }
#define ATC_EVAL_MSG(exp, msg)  if (exp)            \
                             {                        \
                               fprintf(stdout,        \
                               "SUCCESS: (%s) %s\n",  \
                               __FILE__,              \
                               #msg );                \
                             }                        \
                             else                     \
                             {                        \
                               fprintf(stdout,        \
                               "FAILURE: (%s:%d) %s\n", \
                               __FILE__,              \
                               __LINE__,              \
                               #msg );                \
                             }
#define ATC_SUCCESS  ( fprintf(stdout,                \
                               "SUCCESS: (%s)\n",     \
                               __FILE__ ) )              
#define ATC_SUCCESS_MSG(msg)                          \
                     ( fprintf(stdout,                \
                               "SUCCESS: (%s) %s\n",  \
                               __FILE__,              \
                               #msg ) )

#define ATC_FAILURE ( fprintf(stdout,                \
                              "FAILURE: (%s:%d)\n",    \
                              __FILE__,              \
                              __LINE__ ) )
#define ATC_FAILURE_MSG(msg)                         \
                    ( fprintf(stdout,                \
                              "FAILURE: (%s:%d) %s\n", \
                              __FILE__,              \
                              __LINE__,              \
                              #msg ) )


#endif /* _O_ATC4SES_H_ */


