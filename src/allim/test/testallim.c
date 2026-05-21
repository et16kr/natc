#include <allimPoint.h>
#include <acp.h>
#include <act.h>

#define TEST_ERROR ACP_RC_EEXIST
#define TEST_MEMUSE (acp_sint64_t)(ACP_UINT32_MAX)

acp_sint32_t main(acp_sint32_t aArgc, acp_char_t** aArgv)
{
    acp_rc_t        sRC;
    acp_key_t       sKey;
    acp_bool_t      sProceeding;
    acp_sint32_t    sErrNo;
    acp_bool_t      sHit;
    acp_file_t      sFile;
    acp_sock_t      sTestSock;

    void*           sTestAlloc;

    ACT_TEST_BEGIN();

    sKey = (acp_key_t)acpProcGetSelfID();

#if defined(VC_WIN32)
    (void)allimCreate(sKey);
#else
	while(ACP_RC_IS_EEXIST(sRC = allimCreate(sKey)))
    {
        sKey++;
    }
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
#endif

    sProceeding = allimIsProceeding();
    ACT_CHECK(ACP_TRUE == sProceeding);

    /* Check whether count was reset */
    sRC = allimPointSet("AFile", "AID", 1, TEST_ERROR);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));

    sRC = allimPointPass("AFile", "AID", &sErrNo, &sHit);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    ACT_CHECK(ACP_TRUE == sHit);
    ACT_CHECK(TEST_ERROR == sErrNo);

    sRC = allimPointSet("AFile", "AID", 2, TEST_ERROR);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));

    sRC = allimPointPass("AFile", "AID", &sErrNo, &sHit);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    ACT_CHECK(0 == sErrNo);
    ACT_CHECK(ACP_FALSE == sHit);
    sRC = allimPointPass("AFile", "AID", &sErrNo, &sHit);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    ACT_CHECK(TEST_ERROR == sErrNo);
    ACT_CHECK(ACP_TRUE == sHit);

    /* Check whether count was reset */
    sRC = allimPointPass("AFile", "AID", &sErrNo, &sHit);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    ACT_CHECK(0 == sErrNo);
    ACT_CHECK(ACP_FALSE == sHit);
    sRC = allimPointPass("AFile", "AID", &sErrNo, &sHit);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    ACT_CHECK(TEST_ERROR == sErrNo);
    ACT_CHECK(ACP_TRUE == sHit);

    /* Check whether count was reset */
    sRC = allimPointClear();
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));

    sRC = allimPointPass("AFile", "AID", &sErrNo, &sHit);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    ACT_CHECK(0 == sErrNo);
    ACT_CHECK(ACP_FALSE == sHit);

    /* Set logging */
    sRC = allimSetLogging(1, 1, 1, 1, 1, 1);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    /* Set loggging once more */
    sRC = allimSetLogging(0, 0, 0, 0, 0, 0);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    /* Disable logging */
    sRC = allimEnableLogging(0);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    /* Set logging */
    sRC = allimSetLogging(1, 1, 1, 1, 1, 1);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    /* Set loggging once more */
    sRC = allimSetLogging(0, 0, 0, 0, 0, 0);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    /* Enable loggging */
    sRC = allimEnableLogging(1);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    /* Set logging */
    sRC = allimSetLogging(0, 1, 0, 1, 0, 1);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    /* Set loggging once more */
    sRC = allimSetLogging(1, 0, 1, 0, 1, 0);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));

#if !defined(VC_WIN32)
#if defined(ACP_CFG_COMPILE_32BIT)
    /* Test memory waste */
    sRC = allimSetMemoryWaste(TEST_MEMUSE);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    sRC = allimMemory();
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));

    sRC = acpMemAlloc((void**)&sTestAlloc, 1024*1024);
    ACT_CHECK(ACP_RC_NOT_SUCCESS(sRC));

    sRC = allimSetMemoryWaste(0);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    sRC = allimMemory();
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));

    sRC = acpMemAlloc((void**)&sTestAlloc, 1024*1024);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    acpMemFree((void*)sTestAlloc);
#endif

    /* Test disk waste */
    sRC = allimSetDiskWaste("./", 1024 * 1024);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    sRC = allimDisk();
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));

    sRC = allimSetDiskWaste("./", 0);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    sRC = allimDisk();
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));

    sRC = allimSetDescWaste(1024 * 1024);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    sRC = allimDesc();
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));

    sRC = acpSockOpen(&sTestSock, ACP_AF_INET, ACP_SOCK_DGRAM, 0);
    ACT_CHECK(ACP_RC_IS_EMFILE(sRC));
 
    sRC = allimSetDescWaste(0);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    sRC = allimDesc();
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));

    sRC = acpSockOpen(&sTestSock, ACP_AF_INET, ACP_SOCK_DGRAM, 0);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
    sRC = acpSockClose(&sTestSock);
    ACT_CHECK(ACP_RC_IS_SUCCESS(sRC));
#endif

    /* Finish test */
    ACT_CHECK(ACP_RC_IS_SUCCESS(allimDestroy()));

    sProceeding = allimIsProceeding();
    ACT_CHECK(ACP_FALSE == sProceeding);

    ACT_TEST_END();
}

