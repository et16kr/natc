#include <common.h>
#include <uttString.h>
#include <stdlib.h>

SChar* uttString::utt_strdup(const SChar* s)

{

    SChar* temp;

    

    if (s == NULL)

    {

        return NULL;

    }

    if ((temp = (SChar*)malloc(strlen(s)+1)) == NULL)

    {

        return NULL;

    }

    strcpy(temp, s);

    return temp;

}



SChar* uttString::utt_strcpy(SChar* s1, const SChar* s2, int n)

{

    if (s1 == NULL || s2 == NULL)

    {

        return NULL;

    }

    

    if (n > 0 && n < (SInt)strlen(s2)+1 )

    {

        return NULL;

    }

    return strcpy(s1,s2);

}

SInt   uttString::streq(SChar* s1, const SChar* s2)

{

    if (s1 == NULL || s2 == NULL)

    {

        return -1;

    }

    return strcmp(s1,s2);

}

SInt   uttString::strneq(SChar* s1, const SChar* s2, int n)

{

    if (s1 == NULL || s2 == NULL)

    {

        return -1;

    }

    return strncmp(s1,s2,n);

}

SInt   uttString::strcaseeq(SChar* s1, const SChar* s2)

{

    if (s1 == NULL || s2 == NULL)

    {

        return -1;

    }

    return strcasecmp(s1,s2);

}

SInt   uttString::strncaseeq(SChar* s1, const SChar* s2, int n)

{

    if (s1 == NULL || s2 == NULL)

    {

        return -1;

    }

    return strncasecmp(s1,s2,n);

}



void   uttString::strfree(SChar* s)

{

    if (s != NULL)

    {

        free(s);

        s = NULL;

    }

}

