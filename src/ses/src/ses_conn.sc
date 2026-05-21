#include <ses_conn.h>

EXEC SQL BEGIN DECLARE SECTION;
#define STR_LEN 128
char ses_user[STR_LEN];
char ses_passwd[STR_LEN];
char ses_opt[STR_LEN];
char ses_name[STR_LEN];
EXEC SQL END DECLARE SECTION;

void ses_conn_sys()
{
    strcpy(ses_user, "SYS");
    strcpy(ses_passwd, "MANAGER");

    exec sql connect :ses_user identified by :ses_passwd;
}

void ses_conn_user(char *a_usr, char *a_pwd)
{
    strcpy(ses_user, a_usr);
    strcpy(ses_passwd, a_pwd);

    exec sql connect :ses_user identified by :ses_passwd;
}

void ses_conn_opt(char *a_usr, char *a_pwd, char *a_opt)
{
    strcpy(ses_user, a_usr);
    strcpy(ses_passwd, a_pwd);
    strcpy(ses_opt, a_opt);

    exec sql connect :ses_user identified by :ses_passwd using :ses_opt;
}

void ses_conn_name(char *a_usr, char *a_pwd, char *a_opt, char *a_name)
{
    strcpy(ses_name, a_name);
    strcpy(ses_user, a_usr);
    strcpy(ses_passwd, a_pwd);
    strcpy(ses_opt, a_opt);

    exec sql at :ses_name connect :ses_user identified by :ses_passwd using :ses_opt;
}

void ses_disconn()
{
    exec sql disconnect;
}

void ses_disconn_name(char *a_name)
{
    strcpy(ses_name, a_name);

    exec sql at :ses_name disconnect;
}

