#include <acp.h>

typedef acp_sint32_t limitPointFunc(const acp_char_t*, const acp_char_t*);
typedef acp_sint32_t limitPointDoneFunc(void);

static acp_dl_t             gDL;
static limitPointFunc*      gLimitPoint     = NULL;
static limitPointDoneFunc*  gLimitPointDone = NULL;

#define LIMITPOINTENV       "ATAF_TEST_CASE"
#define LIMITPOINTSO        "allimso"
#define LIMITPOINTFUNC      "allimSoLimitPoint"
#define LIMITPOINTDONEFUNC  "allimSoLimitPointDone"

static acp_rc_t loadFunctions(void)
{
    acp_rc_t    sRC;
    acp_char_t* sSO;
    acp_char_t  sPath[ACP_PATH_MAX_LENGTH];
    
    sRC = acpEnvGet(LIMITPOINTENV, &sSO);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    (void)acpCStrCpy(sPath, ACP_PATH_MAX_LENGTH, sSO, ACP_PATH_MAX_LENGTH);
    (void)acpCStrCat(sPath, ACP_PATH_MAX_LENGTH, "/lib", 4);

    sRC = acpDlOpen(&gDL, sPath, LIMITPOINTSO, ACP_TRUE);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    gLimitPoint = (limitPointFunc*)acpDlSym(&gDL, LIMITPOINTFUNC);
    ACP_TEST(NULL != gLimitPoint);
    gLimitPointDone = (limitPointDoneFunc*)acpDlSym(&gDL, LIMITPOINTDONEFUNC);
    ACP_TEST(NULL != gLimitPointDone);

    return ACP_RC_SUCCESS;

    ACP_EXCEPTION_END;
    return sRC;
}

static acp_sint32_t limitPoint(const acp_char_t* aFile, const acp_char_t* aID)
{
    if(NULL == gLimitPoint)
    {
        ACP_TEST(ACP_RC_NOT_SUCCESS(loadFunctions()));
    }
    else
    {
        /* No need of loading */
    }

    return (*gLimitPoint)(aFile, aID);

    ACP_EXCEPTION_END;
    return 0;
}

static void limitPointDone(void)
{
    if(NULL == gLimitPointDone)
    {
        ACP_TEST(ACP_RC_NOT_SUCCESS(loadFunctions()));
    }
    else
    {
        /* No need of loading */
    }

    (*gLimitPointDone)();

    ACP_EXCEPTION_END;
}

#define EXAMPLE_LIMITPOINT(aID, aLabel) \
    if(0 != limitPoint(__FILE__, aID)) { goto aLabel; } else {}
#define EXAMPLE_LIMITPOINTDONE() limitPointDone()
#define EXAMPLE_LIMITHANDLER(aLabel) aLabel:

static void exampleReal(void)
{
    int         sFile;
    void*       sTemp;

    (void)acpPrintf("Trying memory alloc...");
    sTemp = malloc(1024);
    (void)acpPrintf("%s\n", (NULL != sTemp)? "Success!" : "Fail!");

    (void)acpPrintf("Trying descriptor.....");
    sFile = open("anyfile", O_CREAT, 0666);
    (void)acpPrintf("%s\n", (-1 != sFile)? "Success!" : "Fail!");
}

acp_sint32_t main(void)
{
    acp_sint32_t i;

    EXAMPLE_LIMITPOINT("PREMIER", PREMIER_FAIL);

    for(i = 0; i < 10; i++)
    {
        (void)acpPrintf("[%X]", i + 1);
        EXAMPLE_LIMITPOINT("BOUCLE", BOUCLE_FAIL);
    }
        
    EXAMPLE_LIMITPOINT("DERNIER", DERNIER_FAIL);
    (void)acpPrintf("\n");

    exampleReal();
    return 0;

    EXAMPLE_LIMITHANDLER(PREMIER_FAIL);
    (void)acpPrintf("Limit point PREMIER activated! errno=%d\n", errno);
    return 1;

    EXAMPLE_LIMITHANDLER(BOUCLE_FAIL);
    (void)acpPrintf("Limit point BOUCLE  activated! errno=%d\n", errno);
    return 1;

    EXAMPLE_LIMITHANDLER(DERNIER_FAIL);
    (void)acpPrintf("Limit point DERNIER activated! errno=%d\n", errno);
    return 1;
}
