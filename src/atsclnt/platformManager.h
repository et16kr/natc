/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: platformManager.h 634 2006-06-03 06:22:10Z mkjung $
 **********************************************************************/
#ifndef _O_PLATFORM_MANAGER_
#define _O_PLATFORM_MANAGER_ 1

#include "common.h"

class PlatformManager
{
public:
    IDE_RC      initialize();
    IDE_RC      destroy();

    IDE_RC      load( SChar *aFileName );
    idBool      contains( STAFString aGroupName );
    IDE_RC      status();

private:
    mPlatform             mPlatformList;
    std::list<STAFString> mList;
};

#endif
