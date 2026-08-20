#include <atc4ses.h>
#include <stdio.h>
#include <stdlib.h>
#include <idl.h>

int main()
{
    /* declare host variables */
    EXEC SQL BEGIN DECLARE SECTION;
    char usr[10];
    char pwd[10];
    int  i1[5];
    int  i2[5];
    char i3[5][10];
    EXEC SQL END DECLARE SECTION;

    /* set username */
    strcpy(usr, "SYS");
    /* set password */
    strcpy(pwd, "MANAGER");

    EXEC SQL CONNECT :usr IDENTIFIED BY :pwd;

    if (sqlca.sqlcode == SQL_SUCCESS) /* check sqlca.sqlcode */
    {
        printf("< CONNECT >\n\n");
    }
    else
    {
        printf("Error : [%d] %s\n\n", SQLCODE, sqlca.sqlerrm.sqlerrmc);
        exit(1);
    }

    //--------------------------------------------------------
    ATC_MSG( ATOMIC ARRAY INSERT \n );
    //--------------------------------------------------------

    i1[0] = 1;  i2[0] = 2;  strcpy(i3[0], "abc");
    i1[1] = 2;  i2[1] = 3;  strcpy(i3[1], "cde");
    i1[2] = 3;  i2[2] = 4;  strcpy(i3[2], "fgh");
    i1[3] = 4;  i2[3] = 5;  strcpy(i3[3], "ijk");
    i1[4] = 5;  i2[4] = 6;  strcpy(i3[4], "lmn");

    EXEC SQL ATOMIC FOR 5 INSERT INTO T1 VALUES ( :i1, :i2, :i3 );

    ATC_RESULT();

    /* disconnect */
    EXEC SQL DISCONNECT;

    if (sqlca.sqlcode == SQL_SUCCESS) /* check sqlca.sqlcode */
    {
        printf("\n< Disconnet >\n");
    }
    else
    {
        printf("Error : [%d] %s\n\n", SQLCODE, sqlca.sqlerrm.sqlerrmc);
    }
}
