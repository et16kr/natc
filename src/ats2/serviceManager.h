/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: serviceManager.h 516 2006-04-12 06:18:24Z sbjang $
 **********************************************************************/

#ifndef _O_SERVICE_MANAGER_H_
#define _O_SERVICE_MANAGER_H_ 1

#include "common.h"

// 하나의 ATAF 인스턴스가 동시에 처리할 수 있는 최대 요청의 개수를 지정한다.
// 현재는 사용되지 않고 있지 않다.
// 따라서 시스템 메모리가 허용하는 한도내에서 모든 요청을 처리한다. 
#define MAX_SERVICE_THREAD 100

class Servicer;

typedef std::deque<Servicer *> ServicerList; 

class ServiceManager
{
public:
    static IDE_RC             initialize();
    static IDE_RC             destroy();

    static SInt               lock();
    static SInt               unlock();
    static SInt               lockLogon();
    static SInt               unlockLogon();

    static IDE_RC             addService( Servicer *aServicer );
    static IDE_RC             rmService( Servicer *aServicer );

    static IDE_RC             registerHandle( STAFHandlePtr &aHandle );

    static STAFResultPtr      handleHelp( STAFServiceRequestLevel30 *aInfo,
                                          ServiceData               *aServiceData );
            
    static STAFResultPtr      handleVersion( STAFServiceRequestLevel30 *aInfo,
                                             ServiceData               *aServiceData );            
                               
    static STAFResultPtr      handleRun( STAFServiceRequestLevel30 *aInfo,
                                         ServiceData               *aServiceData );
    static STAFResultPtr      handleKill( STAFServiceRequestLevel30 *aInfo,
                                          ServiceData               *aServiceData );
    static STAFResultPtr      handleStatus( STAFServiceRequestLevel30 *aInfo,
                                            ServiceData               *aServiceData );
                           
    static STAFResultPtr      resolveOption( STAFServiceRequestLevel30 *aInfo,
                                             ServiceData               *aServiceData,
                                             STAFCommandParseResultPtr &aParsedResult,
                                             const STAFString          &aOption,
                                             UInt                       aOptionIndex = 1 );
                               
    static STAFResultPtr      resolveString( STAFServiceRequestLevel30 *aInfo,
                                             ServiceData               *aServiceData,
                                             const STAFString          &aTheString);
                               
    static void               registerHelpData( ServiceData      *aServiceData,
                                                UInt              aErrorCode,
                                                const STAFString &aShortInfo,
                                                const STAFString &aLongInfo );

    static void               unregisterHelpData( ServiceData *aServiceData,
                                                  UInt         aErrorCode );

private:
    static ServicerList                     mServicerList;
    static pthread_mutex_t               mMutex;
};

#endif
