#ifndef _TFW_H_
#define _TFW_H_ 1

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sqlcli.h>

void TFW_SECTOR(int num, int ignore, char* str);
void TFW_SKIP_BEGIN(void);
void TFW_SKIP_END(void);
void TFW_PRINT(int level, char* str);
void TFW_CHECK_RTN_CODE(int code, int est);
void TFW_CHECK_ERR_CODE2(int code, int est);
void TFW_CHECK_ERR_CODE(SQLHENV henv, SQLHDBC hdbc, SQLHSTMT hstmt, int e_code);
void TFW_CHECK_ERR_STATE2(char *c_state, char *e_state);
void TFW_CHECK_ERR_STATE(SQLHENV henv, SQLHDBC hdbc, SQLHSTMT hstmt, char *e_state);
void TFW_WAIT_PROCESS(char* process, int time);
void TFW_WAIT_STATE(char* state, int time);
void TFW_POST_STATE(char* state);

#endif
