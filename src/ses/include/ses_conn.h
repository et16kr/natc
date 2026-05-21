#ifndef _O_SES_CONN_H_
#define _O_SES_CONN_H_ 1

void ses_conn_sys();
void ses_conn_user(char *a_usr, char *a_pwd);
void ses_conn_opt(char *a_usr, char *a_pwd, char *a_opt);
void ses_conn_name(char *a_usr, char *a_pwd, char *a_opt, char *a_name);
void ses_disconn();
void ses_disconn_name(char *a_name);

#endif
