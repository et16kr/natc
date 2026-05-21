#include <allimPoint.h>
#include <acp.h>

/*
 * This shared object shall contain Limit Point Functions and
 * hookings of APIs
 */

acp_bool_t gHookLoaded = ACP_FALSE;

ACP_EXPORT acp_sint32_t allimSoLimitPoint(acp_char_t* aFile, acp_char_t* aID)
{
    acp_rc_t        sRC;
    acp_sint32_t    sErrNo;
    acp_bool_t      sHit;

    if(ACP_TRUE != allimIsProceeding())
    {
        acp_key_t       sKey;

        sKey = (acp_key_t)acpProcGetSelfID();
        while(ACP_RC_IS_EEXIST(sRC = allimCreate(sKey)))
        {
            sKey++;
        }
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    }
    else
    {
        /* Do nothing */
    }

    sRC = allimPointPass(aFile, aID, &sErrNo, &sHit);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    errno = sErrNo;

    gHookLoaded = ACP_TRUE;

    return (ACP_TRUE == sHit)? 1 : 0;

    ACP_EXCEPTION_END;
    return 0;
}

ACP_EXPORT void allimSoLimitPointDone(void)
{
    acp_rc_t        sRC;

    if(ACP_TRUE != allimIsProceeding())
    {
        acp_key_t       sKey;

        sKey = (acp_key_t)acpProcGetSelfID();
        while(ACP_RC_IS_EEXIST(sRC = allimCreate(sKey)))
        {
            sKey++;
        }
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    }
    else
    {
        /* Do nothing */
    }

    sRC = allimPointDone();
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    return;

    ACP_EXCEPTION_END;
}
