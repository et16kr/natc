/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: service.cpp 1021 2006-12-11 03:42:03Z ataf $
 **********************************************************************/

#include "service.h"
#include "serviceManager.h"

STAFString       gLineSep;
const STAFString gVersionInfo("3.0.1");
const STAFString gLocal("local");
const STAFString gHelp("help");
const STAFString gVar("var");
const STAFString gResStrResolve("RESOLVE REQUEST ");
const STAFString gString(" STRING ");
const STAFString gLeftCurlyBrace(kUTF8_LCURLY);

STAFRC_t 
STAFServiceGetLevelBounds( UInt  aLevelID,
                           UInt *aMinimum,
                           UInt *aMaximum )
{
    switch( aLevelID )
    {
        case kServiceInfo:
        {
            *aMinimum = 30;
            *aMaximum = 30;
            break;
        }
        case kServiceInit:
        {
            *aMinimum = 30;
            *aMaximum = 30;
            break;
        }
        case kServiceAcceptRequest:
        {
            *aMinimum = 30;
            *aMaximum = 30;
            break;
        }
        case kServiceTerm:
        case kServiceDestruct:
        {
            *aMinimum = 0;
            *aMaximum = 0;
            break;
        }
        default:
        {
            return kSTAFInvalidAPILevel;
        }
    }

    return kSTAFOk;
}

STAFRC_t 
STAFServiceConstruct( STAFServiceHandle_t *aServiceHandle,
                      void                *aServiceInfo, 
                      UInt                 aInfoLevel,
                      STAFString_t        *aErrorBuffer )
{
    UInt                    i;
    STAFRC_t                sEcode = kSTAFUnknownError;
    STAFString              sEbuffer;
    ServiceData             sData;
    STAFServiceInfoLevel30 *sInfo;

    if( aInfoLevel != 30 )
    {
        return kSTAFInvalidAPILevel;
    }

    try
    {
        sInfo = reinterpret_cast<STAFServiceInfoLevel30 *>(aServiceInfo);

        sData.debugMode = 0;
        sData.shortName = sInfo->name; // ats
        sData.name = "STAF/Service/";  // STAF/Service/ats
        sData.name += sInfo->name;
        
        for( i = 0; i < sInfo->numOptions; ++i )
        {            
            if( STAFString( sInfo->pOptionName[i]).upperCase() == "DEBUG" )
            {
                sData.debugMode = 1;
            }           
            else
            {
                sEbuffer = STAFString( sInfo->pOptionName[i] );
                *aErrorBuffer = sEbuffer.adoptImpl();
                return kSTAFServiceConfigurationError;
            }
        }        

        // Set service handle
        *aServiceHandle = new ServiceData(sData);

        return kSTAFOk;
    }
    catch( STAFException &e )
    {
        sEbuffer += STAFString("In ats.cpp: STAFServiceConstruct")
            + kUTF8_SCOLON;
            
        sEbuffer += STAFString("Name: ") + e.getName() + kUTF8_SCOLON;
        sEbuffer += STAFString("Location: ") + e.getLocation() + kUTF8_SCOLON;
        sEbuffer += STAFString("Text: ") + e.getText() + kUTF8_SCOLON;
        sEbuffer += STAFString("Error code: ") + e.getErrorCode() + kUTF8_SCOLON;
        
        *aErrorBuffer = sEbuffer.adoptImpl();
    }
    catch( ... )
    {
        sEbuffer = STAFString( "ats.cpp: STAFServiceConstruct: Caught "
                    "unknown exception in STAFServiceConstruct()");
        *aErrorBuffer = sEbuffer.adoptImpl();
    }    

    return kSTAFUnknownError;
}

STAFRC_t
STAFServiceInit( STAFServiceHandle_t aServiceHandle,
                 void               *aInitInfo, 
                 UInt                aInitLevel,
                 STAFString_t       *aErrorBuffer )
{
    STAFRC_t                sEcode = kSTAFUnknownError;
    STAFString              sEbuffer;
    ServiceData            *sData = NULL;
    STAFServiceInitLevel30 *sInfo = NULL;
    STAFResultPtr           sResult;

    try
    {    
        if( aInitLevel != 30 )
        { 
            return kSTAFInvalidAPILevel;
        }

        sData = reinterpret_cast<ServiceData *>(aServiceHandle);
        
        sInfo = reinterpret_cast<STAFServiceInitLevel30 *>(aInitInfo);        

        sEcode = STAFHandle::create( sData->name, sData->handlePtr );

        if( sEcode != kSTAFOk )
        {
            return sEcode;
        }
       
        //RUN options 
        sData->runParser = STAFCommandParserPtr( new STAFCommandParser, 
                                                  STAFCommandParserPtr::INIT );
        sData->runParser->addOption( "RUN", 
                                      1,
                                      STAFCommandParser::kValueRequired );
        sData->runParser->addOption( "TS", 
                                      1,
                                      STAFCommandParser::kValueRequired );
        sData->runParser->addOption( "FULLTS", 
                                      1,
                                      STAFCommandParser::kValueRequired );
        sData->runParser->addOption( "COMMENT", 
                                      1,
                                      STAFCommandParser::kValueRequired );
        sData->runParser->addOption( "LOGNAME", 
                                      1,
                                      STAFCommandParser::kValueRequired );
        sData->runParser->addOption( "HOSTNAME", 
                                      1,
                                      STAFCommandParser::kValueRequired );
        sData->runParser->addOption( "LINK", 
                                      1,
                                      STAFCommandParser::kValueRequired );
        sData->runParser->addOption( "UNLINK", 
                                      1,
                                      STAFCommandParser::kValueRequired );
        sData->runParser->addOption( "UNLINK2",
                                      1,
                                      STAFCommandParser::kValueRequired );
        sData->runParser->addOption( "BEGIN",
                                      1,
                                      STAFCommandParser::kValueRequired );
        sData->runParser->addOption( "PROGRESS",
                                      1,
                                      STAFCommandParser::kValueRequired );
        // PRJ-1552
        sData->runParser->addOption( "TESTTYPE",
                                      1,
                                      STAFCommandParser::kValueRequired );

        sData->runParser->addOption( "RECDATAFILE",
                                      1,
                                      STAFCommandParser::kValueRequired );

        sData->runParser->addOption( "RECPOINTID",
                                      1,
                                      STAFCommandParser::kValueRequired );
        //HELP options
        sData->helpParser = STAFCommandParserPtr( new STAFCommandParser, 
                                                   STAFCommandParserPtr::INIT );
        sData->helpParser->addOption( "HELP", 
                                       1, 
                                       STAFCommandParser::kValueNotAllowed );

        //VERSION options
        sData->versionParser = STAFCommandParserPtr( new STAFCommandParser, 
                                                      STAFCommandParserPtr::INIT );
        sData->versionParser->addOption( "VERSION", 
                                          1, 
                                          STAFCommandParser::kValueNotAllowed );
        //KILL options
        sData->killParser = STAFCommandParserPtr( new STAFCommandParser, 
                                                  STAFCommandParserPtr::INIT );
        sData->versionParser->addOption( "KILL", 
                                          1, 
                                          STAFCommandParser::kValueNotAllowed );

        //STATUS options
        sData->statusParser = STAFCommandParserPtr( new STAFCommandParser, 
                                                    STAFCommandParserPtr::INIT );
        sData->statusParser->addOption( "STATUS", 
                                        1, 
                                        STAFCommandParser::kValueNotAllowed);

        // Resolve the line separator variable for the local machine
        sResult = sData->handlePtr->submit( "local", 
                                            "VAR", 
                                            "RESOLVE STRING {STAF/Config/Sep/Line}" );

        if( sResult->rc != 0 )
        {
            *aErrorBuffer = sResult->result.adoptImpl();
            return sResult->rc;
        }
        else 
        {
            gLineSep = sResult->result;
        }
        
        // Resolve the machine name variable for the local machine
        sResult = sData->handlePtr->submit( "local", 
                                             "VAR", 
                                             "RESOLVE STRING {STAF/Config/Machine}");

        if( sResult->rc != 0 )
        {
            *aErrorBuffer = sResult->result.adoptImpl();
            return sResult->rc;
        }
        else 
        {
            sData->localMachineName = sResult->result;
        }
       
        // Register Help Data
        ServiceManager::registerHelpData( sData,
                                          kServieInvalidOption,
                                          STAFString("Invalid option"),
                                          STAFString("Invalid option was specified") );

        if( ServiceManager::initialize() != IDE_SUCCESS )
        {
            sEcode = kSTAFUnknownError;
        }
        
    }
    catch( STAFException &e )
    {
        sEbuffer += STAFString("In ats.cpp: STAFServiceInit") + kUTF8_SCOLON;
        sEbuffer += STAFString("Name: ") + e.getName() + kUTF8_SCOLON;
        sEbuffer += STAFString("Location: ") + e.getLocation() + kUTF8_SCOLON;
        sEbuffer += STAFString("Text: ") + e.getText() + kUTF8_SCOLON;
        sEbuffer += STAFString("Error code: ") + e.getErrorCode() + kUTF8_SCOLON;
        
        *aErrorBuffer = sEbuffer.adoptImpl();
    }
    catch( ... )
    {
        sEbuffer = STAFString( "ats.cpp: STAFServiceInit: Caught unknown " "exception in STAFServiceServiceInit()");
        *aErrorBuffer = sEbuffer.adoptImpl();
    }    

    return sEcode;
}


STAFRC_t 
STAFServiceAcceptRequest( STAFServiceHandle_t aServiceHandle,
                          void               *aRequestInfo, 
                          UInt                aReqLevel,
                          STAFString_t       *aResultBuffer )
{
    STAFRC_t                   sEcode = kSTAFUnknownError;
    STAFString                 sEbuffer;
    STAFResultPtr              sResult;
    STAFServiceRequestLevel30 *sInfo = NULL;
    ServiceData               *sData = NULL;
    STAFString                 sRequest;
    STAFString                 sAction;

    if( aReqLevel != 30 ) 
    {
        return kSTAFInvalidAPILevel;
    }

    try
    {
        sResult = STAFResultPtr( new STAFResult(), STAFResultPtr::INIT);        

        sInfo = reinterpret_cast<STAFServiceRequestLevel30 *>(aRequestInfo);

        sData = reinterpret_cast<ServiceData *>(aServiceHandle);

        sRequest = STAFString( sInfo->request );
        sAction = sRequest.subWord(0, 1).toLowerCase();
        
        // Call functions for the request
        if( sAction == "help" )
        {
            sResult = ServiceManager::handleHelp( sInfo, sData );
        }
        else if( sAction == "version" )
        {
            sResult = ServiceManager::handleVersion( sInfo, sData );
        }
        else if( sAction == "run" )
        {
            sResult = ServiceManager::handleRun( sInfo, sData );
        }
        else if( sAction == "kill" )
        {
            sResult = ServiceManager::handleKill( sInfo, sData );
        }
        else if( sAction == "status" )
        {
            sResult = ServiceManager::handleStatus( sInfo, sData );
        }
        else
        {
            sResult = STAFResultPtr( new STAFResult(kSTAFInvalidRequestString, sRequest.subWord(0, 1)), 
                                     STAFResultPtr::INIT);
        }

        *aResultBuffer = sResult->result.adoptImpl();
        sEcode = sResult->rc;
    }
    catch( STAFException &e )
    { 
        sEbuffer += STAFString("In ats.cpp: STAFServiceAcceptRequest") + kUTF8_SCOLON;
        sEbuffer += STAFString("Name: ") + e.getName() + kUTF8_SCOLON;
        sEbuffer += STAFString("Location: ") + e.getLocation() + kUTF8_SCOLON;
        sEbuffer += STAFString("Text: ") + e.getText() + kUTF8_SCOLON;
        sEbuffer += STAFString("Error code: ") + e.getErrorCode() + kUTF8_SCOLON;
        
        *aResultBuffer = sEbuffer.adoptImpl();
    }
    catch( ... )
    {
        sEbuffer = STAFString( "ats.cpp: STAFServiceAcceptRequest: Caught "
                               "unknown exception in STAFServiceAcceptRequest()");
        *aResultBuffer = sEbuffer.adoptImpl();
    }

    return sEcode;
}


STAFRC_t 
STAFServiceTerm( STAFServiceHandle_t aServiceHandle,
                 void               *aTermInfo, 
                 UInt                aTermLevel,
                 STAFString_t       *aErrorBuffer )
{
    STAFRC_t     sEcode = kSTAFUnknownError;
    STAFString   sEbuffer;
    ServiceData *sData = NULL;

    if( aTermLevel != 0 ) 
    {
        return kSTAFInvalidAPILevel;
    }

    try
    {
        sEcode = kSTAFOk;

        sData = reinterpret_cast<ServiceData *>(aServiceHandle);

        // Un-register Help Data
        ServiceManager::unregisterHelpData( sData, kServieInvalidOption );
        
        if( ServiceManager::destroy() != IDE_SUCCESS )
        {
            sEcode = kSTAFUnknownError;
        }
    }
    catch( STAFException &e )
    { 
        sEbuffer += STAFString("In ats.cpp: STAFServiceTerm") + kUTF8_SCOLON;
            
        sEbuffer += STAFString("Name: ") + e.getName() + kUTF8_SCOLON;
        sEbuffer += STAFString("Location: ") + e.getLocation() + kUTF8_SCOLON;
        sEbuffer += STAFString("Text: ") + e.getText() + kUTF8_SCOLON;
        sEbuffer += STAFString("Error code: ") + e.getErrorCode() + kUTF8_SCOLON;
        
        *aErrorBuffer = sEbuffer.adoptImpl();
    }
    catch( ... )
    {
        sEbuffer = STAFString( "ats.cpp: STAFServiceTerm: Caught unknown "
                               "exception in STAFServiceTerm()" );
        *aErrorBuffer = sEbuffer.adoptImpl();
    }

    return sEcode;
}


STAFRC_t 
STAFServiceDestruct( STAFServiceHandle_t *aServiceHandle,
                     void                *aDestructInfo, 
                     UInt                 aDestructLevel,
                     STAFString_t        *aErrorBuffer )
{
    STAFRC_t     sEcode = kSTAFUnknownError;
    STAFString   sEbuffer;
    ServiceData *sData = NULL;

    if( aDestructLevel != 0 ) 
    {
        return kSTAFInvalidAPILevel;
    }

    try
    {
        sData = reinterpret_cast<ServiceData *>(*aServiceHandle);

        delete sData;
        *aServiceHandle = 0;

        sEcode = kSTAFOk;
    }
    catch( STAFException &e )
    { 
        sEbuffer += STAFString("In ats.cpp: STAFServiceDestruct") + kUTF8_SCOLON;
        sEbuffer += STAFString("Name: ") + e.getName() + kUTF8_SCOLON;
        sEbuffer += STAFString("Location: ") + e.getLocation() + kUTF8_SCOLON;
        sEbuffer += STAFString("Text: ") + e.getText() + kUTF8_SCOLON;
        sEbuffer += STAFString("Error code: ") + e.getErrorCode() + kUTF8_SCOLON;
        
        *aErrorBuffer = sEbuffer.adoptImpl();
    }
    catch( ... )
    {
        sEbuffer = STAFString( "ats.cpp: STAFServiceDestruct: Caught "
                               "unknown exception in STAFServiceDestruct()");
        *aErrorBuffer = sEbuffer.adoptImpl();
    }

    return sEcode;
}
