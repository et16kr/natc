/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: serverManager.h 725 2006-06-29 08:34:05Z copyrei $
 **********************************************************************/
#ifndef _O_SERVER_MANAGER_
#define _O_SERVER_MANAGER_ 1

#include "common.h"

class ServerManager
{
public:
    IDE_RC      initialize();
    IDE_RC      destroy();

    IDE_RC      load(SChar *aFileName);

    ServerMap  *getList() { return &mSrvMap; };

private:
    std::list<STAFString> mList;
    ServerParam mSrvParam;
    ServerMap   mSrvMap;
};

#endif
