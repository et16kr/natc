DEF IB_GET_IP()
{
    NODISPLAY ON;

    $IB_IP;
    $i = 0;

    LOOP 4
    {
        EXEC P1 "ifconfig ib${i}";
        P_WAIT P1;

        GETROW "inet addr:" $Ret_ $IB_IP;
        GETROW 1 $IB_IP;
        GETCOLUMN -d ":" "${2}" $IB_IP;
        GETCOLUMN -d " " "${1}" $IB_IP;

        IF ($IB_IP != "")
        {
            break;
        }

        $i = $i + 1;
    }

    NODISPLAY OFF;

    return $IB_IP;
}

DEF IB_GET_IPv6()
{
    NODISPLAY ON;

    $IB_IP;
    $i = 0;

    LOOP 4
    {
        EXEC P1 "ifconfig ib${i}";
        P_WAIT P1;

        GETROW "inet6 addr:" $Ret_ $IB_IP;
        GETROW 1 $IB_IP;
        GETCOLUMN -d " " "${4}" $IB_IP;
        GETCOLUMN -d "/" "${1}" $IB_IP;

        IF ($IB_IP != "")
        {
            $IB_IP = $IB_IP || "%ib${i}";
            break;
        }

        $i = $i + 1;
    }

    NODISPLAY OFF;

    return $IB_IP;
}


DEF RESTART_IB_CLIENT()
{
    NODISPLAY ON;

    $IB_IP = CALL IB_GET_IP();

    SET_ENV ISQL_CONNECTION="IB";
    SET_ENV CLIENT CLIENT_COMMAND="isql -silent -u SYS -p MANAGER -s ${IB_IP}";

    RESTART_CLIENT;

    NODISPLAY OFF;
}

DEF RESTART_IB_CLIENT_IPv6()
{
    NODISPLAY ON;

    $IB_IP = CALL IB_GET_IPv6();

    SET_ENV ISQL_CONNECTION="IB";
    SET_ENV CLIENT CLIENT_COMMAND="isql -silent -u SYS -p MANAGER -s ${IB_IP}";

    RESTART_CLIENT;

    NODISPLAY OFF;
}


DEF RESTART_TCP_CLIENT()
{
    NODISPLAY ON;

    SET_ENV ISQL_CONNECTION="TCP";
    SET_ENV CLIENT CLIENT_COMMAND="isql -silent -u SYS -p MANAGER -s localhost";

    RESTART_CLIENT;

    NODISPLAY OFF;
}

DEF RESTART_TCP_CLIENT_IPv6()
{
    NODISPLAY ON;

    SET_ENV ISQL_CONNECTION="TCP";
    SET_ENV CLIENT CLIENT_COMMAND="isql -silent -u SYS -p MANAGER -s ::1";

    RESTART_CLIENT;

    NODISPLAY OFF;
}

