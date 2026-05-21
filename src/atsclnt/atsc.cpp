/*****************************************************************************/
/* Software Testing Automation Framework (STAF)                              */
/* (C) Copyright IBM Corp. 2001, 2004                                        */
/*                                                                           */
/* This software is licensed under the Common Public License (CPL) V1.0.     */
/*****************************************************************************/

#include "STAF.h"
#include "STAFString.h"
#include "STAF_iostream.h"
#include "STAFUtil.h"
#include <stdlib.h>
#include <list>
#include <vector>

#include "common.h"
#include "caseManager.h"
#include "platformManager.h"

#define SMALL_BUFFER 1024

#if defined(STAF_OS_NAME_WIN32)
#define WIN_BADCH   (int)'?'
#define WIN_BADARG  (int)':'
#define WIN_EMSG    ""

SChar    *optarg;                /* argument associated with option */
SInt     optind = 1;             /* index into parent argv vector */
SInt     opterr = 1;             /* if error message should be printed */
SInt     optopt = '?';           /* character checked for validity */
static SInt     optreset;               /* reset getopt */

SInt
getopt(SInt nargc, SChar * const *nargv, const SChar *ostr)
{
    static SChar *place = WIN_EMSG;              /* option letter processing */
    SChar *oli;                              /* option letter list index */

    if (optreset || !*place) {              /* update scanning pointer */
        optreset = 0;
        if (optind >= nargc || *(place = nargv[optind]) != '-') {
            place = WIN_EMSG;
            return (EOF);
        }
        if (place[1] && *++place == '-') {      /* found "--" */
            ++optind;
            place = WIN_EMSG;
            return (EOF);
        }
    }                                       /* option letter okay? */
    if ((optopt = (SInt)*place++) == (SInt)':' ||
        !(oli = (SChar*)strchr(ostr, optopt))) {
        /*
         * if the user didn't specify '-' as an option,
         * assume it means EOF.
         */
        if (optopt == (SInt)'-')
            return (EOF);
        if (!*place)
            ++optind;
        if (opterr && *ostr != ':')
            (void)fprintf(stderr,
                          "%s: illegal option -- %c\n", __FILE__, optopt);
        return (WIN_BADCH);
    }
    if (*++oli != ':') {                    /* don't need argument */
        optarg = NULL;
        if (!*place)
            ++optind;
    }
    else {                                  /* need an argument */
        if (*place)                     /* no white space */
            optarg = place;
        else if (nargc <= ++optind) {   /* no arg */
            place = WIN_EMSG;
            if (*ostr == ':')
                return (WIN_BADARG);
            if (opterr)
                (void)fprintf(stderr,
                              "%s: option requires an argument -- %c\n",
                              __FILE__, optopt);
            return (WIN_BADCH);
        }
        else                            /* white space */
            optarg = nargv[optind];
        place = WIN_EMSG;
        ++optind;
    }
    return (optopt);                        /* dump back option letter */
}
#endif

/*  PRJ-1552 복구지점목록의 STL list */
RecPtrList         gRecPtrList;

idBool runnable( PlatformManager *aPM,
                 caseInfo         aIn );

SInt writeAllTestCase( PlatformManager *aPM,
                       CaseList *aInList, 
                       STAFString aEnvRESULT );

SInt checkConfFile( STAFString aEnvCASE, 
                    STAFString aEnvRESULT );

IDE_RC logTimestamp( FILE *aTarget );

STAFString gMessage;

// Debugging flag

bool gDebug = false;

// Print Mode

const unsigned int kPMAuto = 0;
const unsigned int kPMVerbose = 1;
const unsigned int kPMRaw = 2;

bool gPrintModeLocked = false;
unsigned int gPrintMode = kPMAuto;
unsigned int gUnmarshallingFlags = kSTAFUnmarshallingDefaults;
bool gPrintQuotes = false;

// Indentation

unsigned int gIndentDelta = 2;
STAFString gSpaces("                                        "    // 40 Spaces
                   "                                        ");  // times 2
STAFString gListIndent("[");
STAFString gListOutdent("]");
STAFString gMapIndent("{");
STAFString gMapOutdent("}");

// Separators

STAFString gEntrySeparator("");
STAFString gMapKeySeparator(": ");

// Table data

STAFString gHyphens("----------------------------------------"    // 40 Hyphens
                    "----------------------------------------");  // times 2
STAFString gColumnSeparator(" ");
STAFString gCRLF = STAFString(kUTF8_CR) + STAFString(kUTF8_LF);
STAFString gCR = STAFString(kUTF8_CR);
STAFString gLF = STAFString(kUTF8_LF);
STAFString gTab = STAFString(kUTF8_TAB);
STAFString gSpace(" ");
bool gPrintTables = true;
bool gStrictTables = true;
unsigned int gMaxTableWidth = 79;
unsigned int gMaxLinesPerTableRecord = 20;

struct TableColumn
{
    STAFString key;
    STAFString header;
    STAFString longHeader;
    STAFString shortHeader;
    unsigned int longHeaderLength;
    unsigned int shortHeaderLength;
    unsigned int maxValueLength;
    unsigned int minimumWidth;
    unsigned int maximumWidth;
    unsigned int width;

    unsigned int currTestWidth;
    unsigned int maxTestWidth;
    unsigned int bestTestWidth;

    // sizeCounts[x] = # records with size 'x'
    std::vector<unsigned int> sizeCounts;

    // cwLineCounts[x][y] = # records that fit on 'y' lines with 'x' width
    std::vector<std::vector<unsigned int> > cwLineCounts;

    // cwLineCountSums[x][y] = # records that fit on <= 'y' lines with 'x' width
    std::vector<std::vector<unsigned int> > cwLineCountSums;

    // cwLineSums[x] = # lines used to display all column data using 'x' width
    std::vector<unsigned int> cwLineSums;
};

typedef std::vector<TableColumn> TableColumnList;

inline unsigned int cwLineCountsIndex(unsigned int columnWidth,
                                      unsigned int lineNumber)
{
    return (columnWidth * (gMaxLinesPerTableRecord + 1)) + lineNumber;
}

inline unsigned int cwLinesNeeded(TableColumnList::iterator &clIter,
                                  unsigned int widthToCheck,
                                  unsigned int numItems)
{
    for (unsigned int line = 0; line < gMaxLinesPerTableRecord; ++line)
    {
        if (clIter->cwLineCountSums[widthToCheck - 1][line] == numItems)
            return line + 1;
    }

    return gMaxLinesPerTableRecord + 1;
}

bool incColumnTestWidths(TableColumnList &columnList,
                         unsigned int remainingTableWidth)
{
    bool noMoreArrangements = true;
    int index = 0;

    // First, start from the next to last index and go back towards the
    // beginning of the list looking for loop indices that have maxed out.
    //
    // 'index' will be set to the index of the innermost column which didn't
    // max out.

    for (index = columnList.size() - 2; index >= 0; --index)
    {
        TableColumn &currCol = columnList[index];

        // Set the column to the next increment that decreases line counts
        //
        // XXX: This algorithm could use a little extra help.  For example,
        //      it might want to take header lengths into accounts, so that
        //      you might get a full header length, even though the data
        //      won't show up any better.  This probably needs to be hooked
        //      into the same data/algorithm that "eval" uses.

        unsigned int currMax = STAF_MIN(currCol.maxTestWidth,
                                        currCol.maximumWidth);
        unsigned int currLineSums =
                     currCol.cwLineSums[currCol.currTestWidth - 1];

        while ((currCol.currTestWidth <= currMax) &&
               (currCol.cwLineSums[currCol.currTestWidth - 1] == currLineSums))
        {
            ++currCol.currTestWidth;
        }

        // If this column has maxed out, reset its curr counter to the minimum.
        // It's max counter is set farther down.
        //
        // If it hasn't maxed out, then terminate the loop.

        if (currCol.currTestWidth > currMax)
        {
            currCol.currTestWidth = currCol.minimumWidth;
        }
        else
        {
            noMoreArrangements = false;
            break;
        }
    }

    if (noMoreArrangements) return false;

    // Now, calculate how much width is taken up by the columns that didn't
    // max out

    unsigned int currWidth = 0;
    int i = 0;

    for (i = 0; i <= index; ++i)
        currWidth += columnList[i].currTestWidth - columnList[i].minimumWidth;

    // Next, set the maxed out columns new max values

    for (i = index + 1; i < (columnList.size() - 1); ++i)
    {
        columnList[i].maxTestWidth = columnList[i].minimumWidth +
                                     remainingTableWidth - currWidth;
    }

    // Finally update the last column
    //
    // Note: The last column is not "free".  I.e., it's value is completely
    //       dependent on the values of the other columns.
    //
    // XXX: Might want to look at being able to set which column is the
    //      dependent column, as currently, the last column can sometimes get
    //      "odd" values, including settings greater than its maximum necessary
    //      width.

    columnList[i].currTestWidth = columnList[i].minimumWidth + 
                                  remainingTableWidth - currWidth;

    return true;
}

unsigned int evalColumnWidths(TableColumnList &columnList)
{
    if (gDebug) cout << "Evaluating (curr/min/tmax/max): ";

    unsigned int bestEval = 0;
    unsigned int currEval = 0;

    for (unsigned int i = 0; i < columnList.size(); ++i)
    {
        if (gDebug)
        {
            cout << columnList[i].currTestWidth << "/"
                 << columnList[i].minimumWidth << "/"
                 << columnList[i].maxTestWidth << "/"
                 << columnList[i].maximumWidth << " ";
        }

        bestEval += columnList[i].cwLineSums[columnList[i].bestTestWidth - 1];
        currEval += columnList[i].cwLineSums[columnList[i].currTestWidth - 1];
    }

    if (gDebug) cout << endl;

    if (bestEval > currEval)
    {
        for (unsigned int j = 0; j < columnList.size(); ++j)
            columnList[j].bestTestWidth = columnList[j].currTestWidth;
    }

    return 1;
}

void dumpTableColumnList(TableColumnList &tableColumnList)
{
    for (TableColumnList::iterator iter = tableColumnList.begin();
         iter != tableColumnList.end();
         ++iter)
    {
        cout << "Key                : " << iter->key << endl;
        cout << "Header             : " << iter->header << endl;
        cout << "Long header        : " << iter->longHeader << endl;
        cout << "Short header       : " << iter->shortHeader << endl;
        cout << "Long Header Length : " << iter->longHeaderLength << endl;
        cout << "Short Header Length: " << iter->shortHeaderLength << endl;
        cout << "Max Value Length   : " << iter->maxValueLength << endl;
        cout << "Minimum width      : " << iter->minimumWidth << endl;
        cout << "Maximum width      : " << iter->maximumWidth << endl;
        cout << "Width              : " << iter->width << endl;

        unsigned int maxSizeCount = gMaxTableWidth * gMaxLinesPerTableRecord;

        for (unsigned int i = 0; i <= maxSizeCount; ++i)
        {
            if (iter->sizeCounts[i])
                cout << "Size " << i << ": " << iter->sizeCounts[i] << endl;
        }

        for (unsigned int j = 0; j < gMaxTableWidth; ++j)
        {
            cout << "Lines need for column width " << (j + 1) << ": "
                 << iter->cwLineSums[j] << endl;
        }

        for (unsigned int x = 0; x < gMaxTableWidth + 1; ++x)
        {
            cout << "Column width: " << (x + 1) << endl
                 << "Number of lines/records/total-records: " << endl;

            for (unsigned int y = 0; y < gMaxLinesPerTableRecord + 1; ++y)
            {
                cout << (y + 1) << "/" << iter->cwLineCounts[x][y]
                     << "/" << iter->cwLineCountSums[x][y] << " ";
            }

            cout << endl;
        }
    }

    cout << endl;
}


inline void pauseIt(STAFString message = "Enter a number: ")
{
    cout << message << endl;
    unsigned int a = 0;
    cin >> a;
}

// General constants

STAFString sMapClassKey("staf-map-class-name");
STAFString sKey("key");
STAFString sDisplayName("display-name");
STAFString sShortDisplayName("display-short-name");
STAFString sColon(kUTF8_COLON);
STAFString sSingleQuote(kUTF8_SQUOTE);
STAFString sDoubleQuote(kUTF8_DQUOTE);
STAFString sEscapedSingleQuote("\\'");

STAFString massageArgument(char *theArg)
{
    STAFString arg(theArg);

    if (getenv("STAF_OLDCLI") != 0) return arg;

    if (arg.find(kUTF8_SPACE) != STAFString::kNPos)
    {
        if ((arg.find(sDoubleQuote) != 0) ||
            (arg.findLastOf(sDoubleQuote, STAFString::kNPos,
                            STAFString::kChar) !=
             arg.length(STAFString::kChar)))
        {
            arg = sColon + STAFString(arg.length(STAFString::kChar)) +
                  sColon + arg;
        }
    }

    return arg;
}


STAFString quoteString(const STAFString &input)
{
    if (!gPrintQuotes) return input;

    if (input.find(sSingleQuote) == STAFString::kNPos)
        return STAFString(sSingleQuote) + input + STAFString(sSingleQuote);

    if (input.find(sDoubleQuote) == STAFString::kNPos)
        return STAFString(sDoubleQuote) + input + STAFString(sDoubleQuote);

    return STAFString(sSingleQuote) +
           input.replace(sSingleQuote, sEscapedSingleQuote) +
           STAFString(sSingleQuote);
}


void printVerbose(const STAFObjectPtr &objPtr, const STAFObjectPtr &context,
                  unsigned int indentLevel)
{
    switch (objPtr->type())
    {
        case kSTAFListObject:
        {
            //cout << gListIndent;

            ++indentLevel;

            //if (objPtr->size() > 0) cout << endl;

            // Print out each object

            for (STAFObjectIteratorPtr iterPtr = objPtr->iterate();
                 iterPtr->hasNext();)
            {
                STAFObjectPtr thisObj = iterPtr->next();

                if ((thisObj->type() == kSTAFListObject) ||
                    (thisObj->type() == kSTAFMapObject) ||
                    (thisObj->type() == kSTAFMarshallingContextObject))
                {
                    //cout << gSpaces.subString(0, indentLevel * gIndentDelta);

                    printVerbose(thisObj, context, indentLevel);
                }
                else
                {
                    //cout << gSpaces.subString(0, indentLevel * gIndentDelta);

                    //if (thisObj->type() == kSTAFNoneObject)
                    //    cout << thisObj->asString();
                    //else
                    //    cout << thisObj->asString();
                }

                //if (iterPtr->hasNext()) cout << gEntrySeparator;

                //cout << endl;
            }

            --indentLevel;

            //if (objPtr->size() > 0)
            //    cout << gSpaces.subString(0, indentLevel * gIndentDelta);

            //cout << gListOutdent;

            break;
        }
        case kSTAFMapObject:
        {
            //cout << gMapIndent;

            ++indentLevel;

            //if (objPtr->size() > 0) cout << endl;

            if (objPtr->hasKey(sMapClassKey))
            {
                STAFMapClassDefinitionPtr mapClass =
                    context->getMapClassDefinition(
                        objPtr->get(sMapClassKey)->asString());

                // Determine maximum key length

                STAFObjectIteratorPtr iterPtr;
                unsigned int maxKeyLength = 0;

                for (iterPtr = mapClass->keyIterator(); iterPtr->hasNext();)
                {
                    STAFObjectPtr theKey = iterPtr->next();
                    STAFString theKeyString;

                    if (theKey->hasKey(sDisplayName))
                        theKeyString = theKey->get(sDisplayName)->asString();
                    else
                        theKeyString = theKey->get(sKey)->asString();

                    if (theKeyString.length(STAFString::kChar) > maxKeyLength)
                        maxKeyLength = theKeyString.length(STAFString::kChar);
                }

                // Now print each object in the map

                for (iterPtr = mapClass->keyIterator(); iterPtr->hasNext();)
                {
                    STAFObjectPtr theKey = iterPtr->next();
                    STAFString theKeyString;

                    if (theKey->hasKey(sDisplayName))
                        theKeyString = theKey->get(sDisplayName)->asString();
                    else
                        theKeyString = theKey->get(sKey)->asString();

                    //cout << gSpaces.subString(0, indentLevel * gIndentDelta)
                    //     << theKeyString
                    //     << gSpaces.subString(0, maxKeyLength -
                    //            theKeyString.length(STAFString::kChar))
                    //     << gMapKeySeparator;

                    STAFObjectPtr thisObj =
                        objPtr->get(theKey->get(sKey)->asString());

                    if ((thisObj->type() == kSTAFListObject) ||
                        (thisObj->type() == kSTAFMapObject) ||
                        (thisObj->type() == kSTAFMarshallingContextObject))
                    {
                        printVerbose(thisObj, context, indentLevel);
                    }
                    else if (thisObj->type() == kSTAFNoneObject)
                    {
                        if( theKeyString == "result" )
                        {
                            gMessage = thisObj->asString();
                            //cout << thisObj->asString() << endl;
                        }
                        //cout << thisObj->asString();
                    }
                    else
                    {
                        if( theKeyString == "result" )
                        {
                            gMessage = thisObj->asString();
                            //cout << thisObj->asString() << endl;
                        }
                        //cout << thisObj->asString();
                    }

                    //if (iterPtr->hasNext()) cout << gEntrySeparator;

                    //cout << endl;
                }
            }
            else
            {
                // Determine maximum key length

                STAFObjectIteratorPtr iterPtr;
                unsigned int maxKeyLength = 0;

                for (iterPtr = objPtr->keyIterator(); iterPtr->hasNext();)
                {
                    STAFString theKeyString = iterPtr->next()->asString();

                    if (theKeyString.length(STAFString::kChar) > maxKeyLength)
                        maxKeyLength = theKeyString.length(STAFString::kChar);
                }

                // Now print each object in the map

                for (iterPtr = objPtr->keyIterator(); iterPtr->hasNext();)
                {
                    STAFString theKeyString = iterPtr->next()->asString();

                    //cout << gSpaces.subString(0, indentLevel * gIndentDelta)
                    //     << theKeyString
                    //     << gSpaces.subString(0, maxKeyLength -
                    //            theKeyString.length(STAFString::kChar))
                    //     << gMapKeySeparator;

                    STAFObjectPtr thisObj = objPtr->get(theKeyString);

                    if ((thisObj->type() == kSTAFListObject) ||
                        (thisObj->type() == kSTAFMapObject) ||
                        (thisObj->type() == kSTAFMarshallingContextObject))
                    {
                        printVerbose(thisObj, context, indentLevel);
                    }
                    else if (thisObj->type() == kSTAFNoneObject)
                    {
                        if( theKeyString == "result" )
                        {
                            gMessage = thisObj->asString();
                            //cout << thisObj->asString() << endl;
                        }
                        //cout << thisObj->asString();
                    }
                    else
                    {
                        if( theKeyString == "result" )
                        {
                            gMessage = thisObj->asString();
                            //cout << thisObj->asString() << endl;
                        }
                        //cout << thisObj->asString();
                    }

                    //if (iterPtr->hasNext()) cout << gEntrySeparator;

                    //cout << endl;
                }
            }

            --indentLevel;

            //if (objPtr->size() > 0)
            //    cout << gSpaces.subString(0, indentLevel * gIndentDelta);

            //cout << gMapOutdent;

            break;
        }
        case kSTAFMarshallingContextObject:
        {
            printVerbose(objPtr->getRootObject(), objPtr, indentLevel);
            break;
        }
        default:
        {
            //cout << gSpaces.subString(0, indentLevel * gIndentDelta)
            //     << objPtr->asString();
            break;
        }
    }
}


bool printSimple(const STAFObjectPtr &objPtr, const STAFObjectPtr &context)
{
    if (objPtr->type() == kSTAFMarshallingContextObject) return false;

    if ((objPtr->type() == kSTAFListObject) ||
        (objPtr->type() == kSTAFMapObject))
    {
        STAFObjectIteratorPtr iter =
            (objPtr->type() == kSTAFListObject) ?
                objPtr->iterate() :
                objPtr->valueIterator();

        while (iter->hasNext())
        {
            STAFObjectPtr thisObj = iter->next();

            switch (thisObj->type())
            {
                case kSTAFListObject:
                case kSTAFMapObject:
                case kSTAFMarshallingContextObject:
                    return false;
                default:
                    break;
            }
        }
    }

    if (objPtr->type() == kSTAFListObject)
    {
        for (STAFObjectIteratorPtr iterPtr = objPtr->iterate();
             iterPtr->hasNext();)
        {
            STAFObjectPtr thisObj = iterPtr->next();

            //cout << thisObj->asString() << endl;
        }
    }
    else if (objPtr->type() == kSTAFMapObject)
    {
        if (objPtr->hasKey(sMapClassKey))
        {
            STAFMapClassDefinitionPtr mapClass =
                context->getMapClassDefinition(
                    objPtr->get(sMapClassKey)->asString());

            // Determine maximum key length

            STAFObjectIteratorPtr iterPtr;
            unsigned int maxKeyLength = 0;

            for (iterPtr = mapClass->keyIterator(); iterPtr->hasNext();)
            {
                STAFObjectPtr theKey = iterPtr->next();
                STAFString theKeyString;

                if (theKey->hasKey(sDisplayName))
                    theKeyString = theKey->get(sDisplayName)->asString();
                else
                    theKeyString = theKey->get(sKey)->asString();

                if (theKeyString.length(STAFString::kChar) > maxKeyLength)
                    maxKeyLength = theKeyString.length(STAFString::kChar);
            }

            // Now print each object in the map

            for (iterPtr = mapClass->keyIterator(); iterPtr->hasNext();)
            {
                STAFObjectPtr theKey = iterPtr->next();
                STAFString theKeyString;

                if (theKey->hasKey(sDisplayName))
                    theKeyString = theKey->get(sDisplayName)->asString();
                else
                    theKeyString = theKey->get(sKey)->asString();

                if( theKeyString == "Message" )
                {
                    gMessage = objPtr->get(theKey->get(sKey)->asString())->asString();
                    cout << objPtr->get(theKey->get(sKey)->asString())->asString() << endl;
                }
                //cout << theKeyString
                //     << gSpaces.subString(0, maxKeyLength -
                //                          theKeyString.length(STAFString::kChar))
                //     << gMapKeySeparator
                //     << objPtr->get(theKey->get(sKey)->asString())->asString()
                //     << endl;
            }
        }
        else
        {
            // Determine maximum key length

            STAFObjectIteratorPtr iterPtr;
            unsigned int maxKeyLength = 0;

            for (iterPtr = objPtr->keyIterator(); iterPtr->hasNext();)
            {
                STAFString theKeyString = iterPtr->next()->asString();

                if (theKeyString.length(STAFString::kChar) > maxKeyLength)
                    maxKeyLength = theKeyString.length(STAFString::kChar);
            }

            // Now print each object in the map

            for (iterPtr = objPtr->keyIterator(); iterPtr->hasNext();)
            {
                STAFString theKeyString = iterPtr->next()->asString();

                if( theKeyString == "Message" )
                {    
                    gMessage = objPtr->get(theKeyString)->asString();    
                    cout << objPtr->get(theKeyString)->asString() << endl;
                }
                //cout << theKeyString
                //     << gSpaces.subString(0, maxKeyLength -
                //                          theKeyString.length(STAFString::kChar))
                //     << gMapKeySeparator
                //     << objPtr->get(theKeyString)->asString()
                //     << endl;
            }
        }
    }
    else
    {
        cout << objPtr->asString();
    }

    return true;
}

bool printTable(const STAFObjectPtr &objPtr, const STAFObjectPtr &context)
{
    if (!gPrintTables) return false;

    if (objPtr->type() != kSTAFListObject) return false;

    STAFObjectIteratorPtr iter = objPtr->iterate();

    if (!iter->hasNext()) return false;

    STAFObjectPtr firstObj = iter->next();

    if (firstObj->type() != kSTAFMapObject) return false;

    if (!firstObj->hasKey(sMapClassKey)) return false;

    STAFString mapClassName = firstObj->get(sMapClassKey)->asString();

    if (!context->hasMapClassDefinition(mapClassName)) return false;

    STAFMapClassDefinitionPtr mapClassObj =
        context->getMapClassDefinition(mapClassName);

    // Initialize table info from map class

    unsigned int maxSizeCount = gMaxTableWidth * gMaxLinesPerTableRecord;
    TableColumnList columnList;

    for (STAFObjectIteratorPtr mcIter = mapClassObj->keyIterator();
         mcIter->hasNext();)
    {
        TableColumn thisColumn;

        thisColumn.sizeCounts = std::vector<unsigned int>(maxSizeCount + 1, 0);
        thisColumn.cwLineCounts = std::vector<std::vector<unsigned int> >(gMaxTableWidth + 1, std::vector<unsigned int>(gMaxLinesPerTableRecord + 1, 0));
        thisColumn.cwLineCountSums = std::vector<std::vector<unsigned int> >(gMaxTableWidth + 1, std::vector<unsigned int>(gMaxLinesPerTableRecord + 1, 0));
        thisColumn.cwLineSums = std::vector<unsigned int>(gMaxTableWidth, 0);

        STAFObjectPtr thisKey = mcIter->next();

        thisColumn.key = thisKey->get(sKey)->asString();

        if (thisKey->hasKey(sDisplayName))
            thisColumn.longHeader = thisKey->get(sDisplayName)->asString();
        else
            thisColumn.longHeader = thisKey->get(sKey)->asString();

        if (thisKey->hasKey(sShortDisplayName))
            thisColumn.shortHeader = thisKey->get(sShortDisplayName)->asString();
        else
            thisColumn.shortHeader = thisColumn.longHeader;

        thisColumn.header = thisColumn.longHeader;

        thisColumn.longHeaderLength =
            thisColumn.longHeader.length(STAFString::kChar);
        thisColumn.shortHeaderLength =
            thisColumn.shortHeader.length(STAFString::kChar);

        thisColumn.width = 0;
        thisColumn.maxValueLength = 0;

        columnList.push_back(thisColumn);
    }

    // Process first object

    TableColumnList::iterator clIter;
    
    for (clIter = columnList.begin(); clIter != columnList.end(); ++clIter)
    {
        STAFObjectPtr thisValueObj = firstObj->get(clIter->key);

        if ((thisValueObj->type() != kSTAFScalarStringObject) &&
            (thisValueObj->type() != kSTAFNoneObject))
        {
            if (gStrictTables) return false;
        }

        unsigned int firstItemColumnWidth =
            thisValueObj->asString().length(STAFString::kChar);

        ++clIter->sizeCounts[STAF_MIN(firstItemColumnWidth, maxSizeCount)];

        for (unsigned int columnIndex = 0, columnWidth = 1;
             columnIndex < gMaxTableWidth;
             ++columnIndex, ++columnWidth)
        {
            // At least one line is needed even if the length of an entry
            // in the table is 0 (e.g. due to an empty string, etc.)
            unsigned int linesNeeded = STAF_MAX(
                1, firstItemColumnWidth / columnWidth);

            if (firstItemColumnWidth % columnWidth != 0)
                ++linesNeeded;

            linesNeeded = STAF_MIN(linesNeeded, gMaxLinesPerTableRecord);

            ++clIter->cwLineCounts[columnIndex][linesNeeded - 1];
            clIter->cwLineSums[columnIndex] += linesNeeded;

            for (unsigned int lineIndex = linesNeeded - 1;
                 lineIndex < gMaxLinesPerTableRecord + 1;
                 ++lineIndex)
            {
                ++clIter->cwLineCountSums[columnIndex][lineIndex];
            }
        }

        clIter->maxValueLength = STAF_MAX(clIter->maxValueLength,
                                          firstItemColumnWidth);
    }
    
    // Loop through and process the rest of the objects
    
    while (iter->hasNext())
    {
        STAFObjectPtr thisObj = iter->next();

        // Make sure we are still in a valid table

        if (thisObj->type() != kSTAFMapObject) return false;

        if (thisObj->get(sMapClassKey)->asString() != mapClassName)
            return false;

        // Update table info with this object

        for (clIter = columnList.begin(); clIter != columnList.end(); ++clIter)
        {
            STAFObjectPtr thisValueObj = thisObj->get(clIter->key);

            if ((thisValueObj->type() != kSTAFScalarStringObject) &&
                (thisValueObj->type() != kSTAFNoneObject))
            {
                if (gStrictTables) return false;
            }

            unsigned int thisItemColumnWidth =
                thisObj->get(clIter->key)->asString().length(STAFString::kChar);

            ++clIter->sizeCounts[STAF_MIN(maxSizeCount, thisItemColumnWidth)];

            for (unsigned int columnIndex = 0, columnWidth = 1;
                 columnIndex < gMaxTableWidth;
                 ++columnIndex, ++columnWidth)
            {
                // At least one line is needed even if the length of an entry
                // in the table is 0 (e.g. due to an empty string, etc.)
                unsigned int linesNeeded = STAF_MAX(
                    1, thisItemColumnWidth / columnWidth);
                
                if (thisItemColumnWidth % columnWidth != 0)
                    ++linesNeeded;

                linesNeeded = STAF_MIN(linesNeeded, gMaxLinesPerTableRecord);
                
                ++clIter->cwLineCounts[columnIndex][linesNeeded - 1];
                clIter->cwLineSums[columnIndex] += linesNeeded;

                for (unsigned int lineIndex = linesNeeded - 1;
                     lineIndex < gMaxLinesPerTableRecord + 1;
                     ++lineIndex)
                {
                    ++clIter->cwLineCountSums[columnIndex][lineIndex];
                }
            }

            clIter->maxValueLength = STAF_MAX(clIter->maxValueLength,
                                              thisItemColumnWidth);
        }
    }
    
    // Now determine appropriate column widths

    unsigned int minimumTableWidth = (columnList.size() - 1) *
                                     gColumnSeparator.length(STAFString::kChar);
    unsigned int maximumTableWidth = minimumTableWidth;

    for (clIter = columnList.begin(); clIter != columnList.end(); ++clIter)
    {
        minimumTableWidth += clIter->shortHeaderLength;
        clIter->minimumWidth = clIter->shortHeaderLength;

        if (clIter->longHeaderLength > clIter->maxValueLength)
        {
            maximumTableWidth += clIter->longHeaderLength;
            clIter->maximumWidth = clIter->longHeaderLength;
        }
        else
        {
            maximumTableWidth += clIter->maxValueLength;
            clIter->maximumWidth = clIter->maxValueLength;
        }

        clIter->width = clIter->maximumWidth;
    }

    // Check to make sure the table will fit at its minimum size
    
    if (minimumTableWidth > gMaxTableWidth) return false;

    // Adjust column sizings if necessary

    if (maximumTableWidth > gMaxTableWidth)
    {
        unsigned int remainingTableWidth = gMaxTableWidth - minimumTableWidth;

        if (gDebug)
            cout << "remainingWidth: " << remainingTableWidth << endl;

        // Initialize test width data in columns

        unsigned int index = 0;

        for (index = 0; index < columnList.size(); ++index)
        {
            columnList[index].currTestWidth = columnList[index].minimumWidth;
            columnList[index].bestTestWidth = columnList[index].minimumWidth;
            columnList[index].maxTestWidth =
                columnList[index].minimumWidth + remainingTableWidth;
        }

        // Update last column to start testing with the maximum width

        columnList[columnList.size() - 1].currTestWidth =
            columnList[columnList.size() - 1].maxTestWidth;

        // Now evaluate the different permutations

        do
        {
            evalColumnWidths(columnList);
        } while (incColumnTestWidths(columnList, remainingTableWidth));

        // Now, set width to bestTestWidth and update headers if necessary

        for (clIter = columnList.begin(); clIter != columnList.end(); ++clIter)
        {
            clIter->width = clIter->bestTestWidth;

            if (clIter->width < clIter->longHeaderLength)
                clIter->header = clIter->shortHeader;
        }
    }

    if (gDebug) dumpTableColumnList(columnList);

    // Now, print out the table header

    for (clIter = columnList.begin(); clIter != columnList.end();)
    {
        cout << clIter->header;

        unsigned int spacesNeeded =
            clIter->width - clIter->header.length(STAFString::kChar);

        while (spacesNeeded > gSpaces.length())
        {
            cout << gSpaces;
            spacesNeeded -= gSpaces.length();
        }

        cout << gSpaces.subString(0, spacesNeeded);

        if (++clIter != columnList.end())
            cout << gColumnSeparator;
    }

    cout << endl;
    
    for (clIter = columnList.begin(); clIter != columnList.end();)
    {
        unsigned int hyphensNeeded = clIter->width;

        while (hyphensNeeded > gHyphens.length())
        {
            cout << gHyphens;
            hyphensNeeded -= gHyphens.length();
        }

        cout << gHyphens.subString(0, hyphensNeeded);

        if (++clIter != columnList.end())
            cout << gColumnSeparator;
    }
    
    cout << endl;

    // Now, loop through and print out each object
    
    for (iter = objPtr->iterate (); iter->hasNext();)
    {
        STAFObjectPtr thisObj = iter->next();
        bool done = false;

        for (unsigned int lineNum = 0;
             !done && lineNum < gMaxLinesPerTableRecord;
             ++lineNum)
        {
            done = true;

            for (clIter = columnList.begin(); clIter != columnList.end();)
            {
                STAFString thisColumnFullString =
                    thisObj->get(clIter->key)->asString();

                if (thisColumnFullString.length(STAFString::kChar) >
                    (lineNum + 1) * clIter->width)
                {
                    done = false;
                }

                STAFString thisColumnString = thisColumnFullString.subString(
                    clIter->width * lineNum, clIter->width, STAFString::kChar);

                if ((lineNum == gMaxLinesPerTableRecord - 1) && !done)
                {
                    cout << "(More...)";
                }
                else
                {
                    cout << thisColumnString.replace(gCR, gSpace)
                            .replace(gLF, gSpace).replace(gTab, gSpace);
                }

                unsigned int spacesNeeded =
                    clIter->width - thisColumnString.length(STAFString::kChar);

                while (spacesNeeded > gSpaces.length())
                {
                    cout << gSpaces;
                    spacesNeeded -= gSpaces.length();
                }

                cout << gSpaces.subString(0, spacesNeeded);

                if (++clIter != columnList.end())
                    cout << gColumnSeparator;
            }

            cout << endl;
        }
    }
    
    return true;
}

void printResult(const STAFString &resultString)
{
    gMessage = ""; 

    // Update display settings

    if ((getenv("STAF_PRINT_MODE") != 0) && !gPrintModeLocked)
    {
        STAFString pMode = STAFString(getenv("STAF_PRINT_MODE")).lowerCase();

        if      (pMode == "verbose") gPrintMode = kPMVerbose;
        else if (pMode == "auto")    gPrintMode = kPMAuto;
        else if (pMode == "raw")     gPrintMode = kPMRaw;
    }

    if (getenv("STAF_PRINT_NO_TABLES") != 0)
        gPrintTables = false;

    if (getenv("STAF_NO_STRICT_TABLES") != 0)
        gStrictTables = false;

    if (getenv("STAF_IGNORE_INDIRECT_OBJECTS") != 0)
        gUnmarshallingFlags = kSTAFIgnoreIndirectObjects;

    if (getenv("STAF_INDENT_DELTA") != 0)
    {
        STAFString indentDeltaString = getenv("STAF_INDENT_DELTA");

        try { gIndentDelta = indentDeltaString.asUInt(); }
        catch (...) { /* Do nothing */ }
    }

    if (getenv("STAF_TABLE_WIDTH") != 0)
    {
        STAFString tableWidth = getenv("STAF_TABLE_WIDTH");

        try { gMaxTableWidth = tableWidth.asUInt(); }
        catch (...) { /* Do nothing */ }
    }

    if (getenv("STAF_TABLE_LINES_PER_RECORD") != 0)
    {
        STAFString linesPerRecord = getenv("STAF_TABLE_LINES_PER_RECORD");

        try { gMaxLinesPerTableRecord = linesPerRecord.asUInt(); }
        catch (...) { /* Do nothing */ }
    }

    // Now output the data

    // If requested, just dump out the literal string returned

    if (gPrintMode == kPMRaw)
    {
        cout << resultString;
        return;
    }

    // Otherwise, unmarshall the result and go from there

    STAFObjectPtr objPtr = STAFObject::unmarshall(resultString,
                                                  gUnmarshallingFlags);

    if (gPrintMode == kPMAuto)
    {
        if (!printSimple(objPtr->getRootObject(), objPtr) &&
            !printTable(objPtr->getRootObject(), objPtr))
        {
            printVerbose(objPtr->getRootObject(), objPtr, 0);
        }
    }
    else
    {
        printVerbose(objPtr->getRootObject(), objPtr, 0);
    }
                    
    cout << endl;
}

#define local "local"
#define ats "ats"

char *
atscBasename( const char *name )
{
  const char *base = name;

  while (*name)
    {
      if (*name == FILE_SEPARATOR)
        base = name + 1;
      ++name;
    }
  return (char *) base;
}

STAFString dirname( STAFString aIn )
{
    STAFString sIn = aIn;
    UInt       sCursor = 0;

    sCursor = sIn.findLastOf( FILE_SEPARATORS );

    return sIn.subString( 0, sCursor ).replace( "#", "" );
}

IDE_RC loadSkipMap( SChar                              *aFileName, 
                      std::map<STAFString, STAFString> *aMap )
{
    FILE      *sIn = NULL;
    SChar      sLine[BUFFER_SIZE];
    STAFString sData;

    sIn = fopen( aFileName, "r" );

    if( sIn != NULL )
    {
        while( 1 )
        {
            if( fgets(sLine, ID_SIZEOF(sLine), sIn) != NULL )
            {
                sData = STAFString(sLine);
                sData = sData.upperCase().strip();

                if( sData.find( "TESTSUITEDESCRIPTION" ) !=  STAFString::kNPos )
                {
                    continue;
                }
                if( sData.subString( 0, 1 ) == "#" )
                {
                    continue;
                }  
                if( sData.length() == 0 )
                {
                    continue;
                }

                (*aMap)[STAFString("TC") + STAFString(FILE_SEPARATOR2) + STAFString(sLine).subWord(0, 1).replace( "\n", "").replace("/", FILE_SEPARATOR2) ] = sLine;
                //cout << "[" << STAFString("TC") + STAFString(FILE_SEPARATOR2) + STAFString(sLine).subWord(0, 1).replace( "\n", "").replace("/", FILE_SEPARATOR2) << "]" << endl;
        }
        else
        {
            break;
        }
    }

    fclose( sIn );
    }

    return IDE_SUCCESS;
}

IDE_RC 
loadRECPOINT( SChar        * aFileName ) 
{
    //idBool         sExist;
    FILE        *  sRECPOINT;
    SChar          sFileName[512];
    SChar          sID[512];
    SChar          sBuffer[1024];
    UInt           sLineNo;
    STAFString     sRecPointID;
        
    sRECPOINT  = NULL;

    IDE_TEST( access( aFileName, F_OK ) != 0 );

    IDE_TEST( (sRECPOINT = fopen( aFileName, "r" )) == NULL );

    while ( feof(sRECPOINT) == 0 )
    {
        if ( fgets(sBuffer, 1024, sRECPOINT) != NULL )
        {
            sscanf( sBuffer, "%s %d %s",
                    sFileName,
                    &sLineNo,
                    sID );

            sRecPointID = STAFString( sID ).strip();
            gRecPtrList.push_back( sRecPointID );
        }
    }

    fclose( sRECPOINT );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}


int main(int argc, char **argv)
{
    STAFHandlePtr   sHandlePtr;
    //STAFHandle_t    sHandle;
    unsigned int    sError = 0;
    STAFResultPtr   sResult;

    STAFString      sEnv;
    STAFString      sEnvHOME;
    STAFString      sEnvNLS;
    STAFString      sEnvPORT;
#if defined(STAF_OS_NAME_WIN32)
    STAFString      sEnvIPC_PORT;
#endif
    STAFString      sEnvCASE;
    STAFString      sEnvCASE_USER;
    STAFString      sEnvRESULT;
    STAFString      sEnvSUFFIX_RE;
    STAFString      sEnvSUFFIX_OR;
    STAFString      sEnvPATH;
    STAFString      sEnvLANG;
    STAFString      sEnvLOGNAME;
    STAFString      sEnvHOSTNAME;
    STAFString      sEnvTESTCASECOUNT;
    STAFString      sEnvAll = "a=b";

    CaseManager     sCaser;
    PlatformManager sPM;
    SChar           sData1[BUFFER_SIZE];
    SChar           sData2[BUFFER_SIZE];
    SChar           sData3[BUFFER_SIZE];
    SChar           sData4[BUFFER_SIZE];
    SChar           sSuite1[BUFFER_SIZE];
    SChar           sSuite2[BUFFER_SIZE];
    SChar           sComment[BUFFER_SIZE];

    SChar           sCommonCase[SMALL_BUFFER];
    SChar           sMyCase[SMALL_BUFFER];
    SChar           sCase[SMALL_BUFFER];
    SChar           sSkipCase[SMALL_BUFFER];
    SChar           sLang[SMALL_BUFFER];
    SChar           sArgCnt[SMALL_BUFFER];

    CaseList       *sInList;
    caseInfo        sIn;
    CaseIterator    sIterator;
    UInt            sRun = 0;
    STAFString      sRequest;
    UInt            sPASS = 0;
    UInt            sFAIL = 0;
    UInt            sERROR = 0;
    UInt            sFATAL = 0;

    UInt            sBEGIN = 1;
    SChar           sPROGRESS[30];

    STAFString      sOld;
    STAFString      sLink;
    STAFString      sUnlink;

    FILE           *sFp;
    
    SInt            sCmdOpt;

    // PRJ-1552
    SChar           sTestType[SMALL_BUFFER];
    SChar           sFilePath[SMALL_BUFFER];
    
    STAFString      sRECDATAFILE;
    STAFString      sTESTTYPE;
    STAFString      sRECPOINTID;

    RecPtrListIter  sRecIterator;
    RecPtrListIter  sRemRecIterator;
    ATSTestKind     sAtsTestType;
        
    UInt            sHIT      = 0;
    UInt            sMISS     = 0;
    UInt            sCRASH    = 0;
    UInt            sIGNR     = 0;
    
    UInt            sCHKMISS  = 0;
    UInt            sTotal    = 0;
    UInt            sHitRatio = 0;
    idBool          sStop     = ID_FALSE;
    idBool          sIsArt    = ID_FALSE;
    UInt            sEndCdt   = 100; 
    UInt            sRealRunables = 0; 
    UInt            sRealRunneds = 1; 
   
    std::map<STAFString, STAFString> sMap;
 
    // parse command options
    sCmdOpt = ::getopt( argc, argv, "c:m:l:n:t:e:i:" );

    if( sCmdOpt == EOF )
    {
        cout << "Usage: atsc -c CommonCase -m MyCase -l Lang -n ArgCnt " << endl;
        cout << "       [ -t TestType ] [ -e HitRatio ]" << endl << endl;
        cout << "  -t   recovery test type [ regressive | sequential | full ]" << endl;
        cout << "  -e   recovery test end condition by hit ratio (%)" << endl << endl;

        exit(0);
    }

    memset( sCommonCase,
                   0x00,
                   ID_SIZEOF( sCommonCase ) );
    memset( sMyCase,
                   0x00,
                   ID_SIZEOF( sMyCase ) );
    memset( sSkipCase,
                   0x00,
                   ID_SIZEOF( sSkipCase ) );
    memset( sLang,
                   0x00,
                   ID_SIZEOF( sLang ) );
    memset( sArgCnt,
                   0x00,
                   ID_SIZEOF( sArgCnt ) );
    memset( sTestType,
                   0x00,
                   ID_SIZEOF( sTestType ) );
    memset( sFilePath,
                   0x00,
                   ID_SIZEOF( sFilePath ) );

    do
    {
        switch( sCmdOpt )
        {
            case 'c' : // common case
            {
#if defined(STAF_OS_NAME_WIN32)
                memset( sCase,
                               0x00,
                               ID_SIZEOF( sCase ) );

                memcpy( sCase,
                               optarg,
                               strlen( optarg ) );
                
                memcpy( sCommonCase,
                               STAFString( sCase ).replace( "/", "\\" ).buffer(),
                               STAFString( sCase ).replace( "/", "\\" ).length() );
#else
                memcpy( sCommonCase,
                               optarg,
                               strlen( optarg ) );
#endif
                break;
            }
            case 'm' : // my case
            {
#if defined(STAF_OS_NAME_WIN32)
                memset( sCase,
                               0x00,
                               ID_SIZEOF( sCase ) );

                memcpy( sCase,
                               optarg,
                               strlen( optarg ) );
                
                memcpy( sMyCase,
                               STAFString( sCase ).replace( "/", "\\" ).buffer(),
                               STAFString( sCase ).replace( "/", "\\" ).length() );
#else
                memcpy( sMyCase,
                               optarg,
                               strlen( optarg ) );
#endif
                break;
            }
            case 'l' : // language
            {
                memcpy( sLang,
                               optarg,
                               strlen( optarg ) );
                break;
            }
            case 'i' : // ignore 
            {
                memcpy( sSkipCase,
                               optarg,
                               strlen( optarg ) );
                break;
            }
            case 'n' : // number of arg
            {
                memcpy( sArgCnt,
                               optarg,
                               strlen( optarg ) );
                break;
            }
            case 't' : // test type
            {
                memcpy( sTestType,
                               optarg,
                               strlen( optarg ) );
                sTESTTYPE = STAFString( sTestType ).lowerCase();
                sIsArt = ID_TRUE; 
                break;
            }
            case 'e' : // condition of testend;
            {
                sEndCdt = atoi( optarg );
                sIsArt  = ID_TRUE; 
                break;
            }
            default :
            {
printf( "%c\n", sCmdOpt );
                cout << "Usage: atsc -c CommonCase -m MyCase -l Lang -n ArgCnt " << endl;
                cout << "       [ -t TestType ] [ -e HitRatio ]" << endl << endl;
                cout << "  -t   recovery test type [ regressive | sequential | full ]" << endl;
                cout << "  -e   recovery test end condition by hit ratio (%)" << endl << endl;

                exit(0);
            }
        }
#if defined(STAF_OS_NAME_DEC)
    } while( ( sCmdOpt = getopt( argc, 
                                 argv, 
                                 "c:m:l:n:t:e:i:" ) ) != EOF );
#else
    } while( ( sCmdOpt = getopt( argc, 
                                        argv, 
                                       "c:m:l:n:t:e:i:" ) ) != EOF );
#endif

    
    if( STAFString(sSkipCase) != "none" )
    {
        (void)loadSkipMap( sSkipCase, &sMap );
    }

    if( sCaser.initialize() != IDE_SUCCESS )
    {
        return -1;
    }

    if ( sCaser.loadcase( sCommonCase, sMyCase, atoi( sArgCnt ), &sMap ) != IDE_SUCCESS )
    {
        return -1;
    }

    sInList = sCaser.getList();

    if( getenv( "ALTIBASE_HOME" ) == NULL )
    {
        cout << "Please set environment variable ALTIBASE_HOME" << endl;
        return -1;
    }

    if( getenv( "ALTIBASE_PORT_NO" ) == NULL )
    {
        cout << "Please set environment variable ALTIBASE_PORT_NO" << endl;
        return -1;
    }

#if defined(STAF_OS_NAME_WIN32)
    if( getenv( "ALTIBASE_IPC_PORT_NO" ) == NULL )
    {
        cout << "Please set environment variable ALTIBASE_IPC_PORT_NO" << endl;
        return -1;
    }
#endif

    if( getenv( "ALTIBASE_NLS_USE" ) == NULL )
    {
        cout << "Please set environment variable ALTIBASE_NLS_USE" << endl;
        return -1;
    }

    if( getenv( "ATAF_TEST_CASE" ) == NULL )
    {
        cout << "Please set environment variable ATAF_TEST_CASE" << endl;
        return -1;
    }

    if( getenv( "ATAF_USER_TEST_CASE" ) == NULL )
    {
        cout << "Please set environment variable ATAF_USER_TEST_CASE" << endl;
        return -1;
    }

    if( getenv( "ATAF_TEST_RESULT" ) == NULL )
    {
        cout << "Please set environment variable ATAF_TEST_RESULT" << endl;
        return -1;
    }

    if( getenv( "ATAF_RESULT_SUFFIX" ) == NULL )
    {
        cout << "Please set environment variable ATAF_RESULT_SUFFIX" << endl;
        return -1;
    }
    
    if( getenv( "ATAF_ORACLE_SUFFIX" ) == NULL )
    {
        cout << "Please set environment variable ATAF_ORACLE_SUFFIX" << endl;
        return -1;
    }

    if( getenv( "PATH" ) == NULL )
    {
        cout << "Please set environment variable PATH" << endl;
        return -1;
    }

    if( getenv( "LANG" ) == NULL )
    {
        cout << "Please set environment variable LANG" << endl;
        return -1;
    }

    if( getenv( "LOGNAME" ) == NULL )
    {
        cout << "Please set environment variable LOGNAME" << endl;
        return -1;
    }

    if( getenv( "HOSTNAME" ) == NULL )
    {
        cout << "Please set environment variable HOSTNAME" << endl;
        return -1;
    }

    if( getenv( "TEST_CASE_COUNT" ) == NULL )
    {
        sEnvTESTCASECOUNT = STAFString( "FALSE" );
    }
    else
    {
        sEnvTESTCASECOUNT = getenv( "TEST_CASE_COUNT" );
    }

    sEnvHOME   = getenv( "ALTIBASE_HOME" );
    sEnvPORT   = getenv( "ALTIBASE_PORT_NO" );
#if defined(STAF_OS_NAME_WIN32)
    sEnvIPC_PORT   = getenv( "ALTIBASE_IPC_PORT_NO" );
#endif
    sEnvNLS    = getenv( "ALTIBASE_NLS_USE" );

    sEnvCASE   = getenv( "ATAF_TEST_CASE" );
    sEnvCASE_USER   = getenv( "ATAF_USER_TEST_CASE" );
    sEnvRESULT = getenv( "ATAF_TEST_RESULT" );
    sEnvSUFFIX_RE = getenv( "ATAF_RESULT_SUFFIX" );
    sEnvSUFFIX_OR = getenv( "ATAF_ORACLE_SUFFIX" );
    sEnvPATH = getenv( "PATH" );
    sEnvLOGNAME = getenv( "LOGNAME" );
    sEnvHOSTNAME = getenv( "HOSTNAME" );
    sEnvLANG = sLang;

    if( getenv( "ENV_PROPERTIES" ) != NULL )
    {
        sEnvAll = getenv( "ENV_PROPERTIES" );
    }

    /*  ATS 테스트타입 결정 */
    
    if ( sIsArt == ID_FALSE  )
    {
        sTESTTYPE = "normal";
        sAtsTestType = ATS_TEST_NORMAL;
    }
    else
    {
        /* 복구지점목록 파일의 위치
           (고정됨 $ALTIBASE_HOME/conf/recovery.dat) */
           
        sprintf( sFilePath, 
                        "%s%s%s%s%s",
                        getenv( "ALTIBASE_HOME" ),
                        FILE_SEPARATORS,
                        "conf",
                        FILE_SEPARATORS,
                        RECPOINT_FILE);
        
        sRECDATAFILE = STAFString( sFilePath );

        /*
           복구테스트타입 설정
           1) Regression Test
           2) Sequential Test
           3) Full Test
        */

        if ( sTESTTYPE.find("regressive") != STAFString::kNPos )
        {
            sAtsTestType = ATS_TEST_REGRESSIVE;
        }
        else if ( sTESTTYPE.find("full") != STAFString::kNPos )
        {
            sAtsTestType = ATS_TEST_FULL;
        }
        else if ( sTESTTYPE.find("sequential") != STAFString::kNPos )
        {
            /* Sequential Test를 위해 복구지점목록 파일을
               판독하여 STL list 구축 */
            
            if ( loadRECPOINT( sFilePath ) != IDE_SUCCESS )
            {
                return -1;
            }
            
            sAtsTestType = ATS_TEST_SEQUENTIAL;
            sTotal       = gRecPtrList.size();
            
            /* STL list의 첫번째 복구지점 선택 */
            sRecIterator = gRecPtrList.begin();
        }
        else
        {
            cout << "Usage: atsc -c CommonCase -m MyCase -l Lang -n ArgCnt " << endl;
            cout << "       [ -t TestType ] [ -e HitRatio ]" << endl << endl;
            cout << "  -t   recovery test type [ regressive | sequential | full ]" << endl;
            cout << "  -e   recovery test end condition by hit ratio (%)" << endl << endl;
            
            return -1;
        }
    }

#if defined(STAF_OS_NAME_WIN32)
    sEnvHOME       = sEnvHOME.replace( "/", "\\" );
    sEnvCASE       = sEnvCASE.replace( "/", "\\" );
    sEnvCASE_USER  = sEnvCASE_USER.replace( "/", "\\" );
    sEnvRESULT     = sEnvRESULT.replace( "/", "\\" );
#endif

    // ATAF_TEST_CASE/conf에 
    // platform.conf와 server.conf가 있는지 체크한다.
    checkConfFile( sEnvCASE, sEnvRESULT );
    
    if( sPM.initialize() != IDE_SUCCESS )
    {
        return -1;
    }
  
    sprintf( sData1, 
                    "%s%s%s%s%s",
                    getenv( "ATAF_TEST_CASE" ),
                    FILE_SEPARATORS,
                    "conf",
                    FILE_SEPARATORS,
                    PLATFORM_FILE );
  
    if( sPM.load( sData1 ) != IDE_SUCCESS )
    {
        return -1;
    }

    sEnv += " VAR";
    sEnv += " ALTIBASE_HOME=";
    sEnv += sEnvHOME;
    
    sEnv += " VAR";
    sEnv += " ALTIBASE_PORT_NO=";
    sEnv += sEnvPORT;

#if defined(STAF_OS_NAME_WIN32)
    sEnv += " VAR";
    sEnv += " ALTIBASE_IPC_PORT_NO=";
    sEnv += sEnvIPC_PORT;
#endif
    
    sEnv += " VAR";
    sEnv += " ALTIBASE_NLS_USE=";
    sEnv += sEnvNLS;

    sEnv += " VAR";
    sEnv += " ATAF_TEST_CASE=";
    sEnv += sEnvCASE;
    
    sEnv += " VAR";
    sEnv += " ATAF_USER_TEST_CASE=";
    sEnv += sEnvCASE_USER;
    
    sEnv += " VAR";
    sEnv += " ATAF_TEST_RESULT=";
    sEnv += sEnvRESULT;

    sEnv += " VAR";
    sEnv += " PATH=";
    sEnv += sEnvPATH.replace( ":", "^" );

    sEnv += " VAR";
    sEnv += " LANG=";
    sEnv += sEnvLANG;

    sEnv += " VAR";
    sEnv += " ATAF_RESULT_SUFFIX=";
    sEnv += sEnvSUFFIX_RE;
    
    sEnv += " VAR";
    sEnv += " ATAF_ORACLE_SUFFIX=";
    sEnv += sEnvSUFFIX_OR;

    // a=b;b=c;c=d 
    sEnv += " VAR";
    sEnv += " ENV_PROPERTIES=";
    sEnv += sEnvAll;

    // TS
    sSuite1[0] = '\0';
    sSuite2[0] = '\0';

    sprintf( sData1, 
                    "%s%d", 
                    "STAF/ats/atsclnt_",
                    getpid() );
    
    sError = STAFHandle::create( sData1, 
                                 sHandlePtr);

    if (sError != 0)
    {
        cout << "Error registering with ATAF, RC: " << sError << endl;
        if ( sError == 21 )
        {
            cout << "ATAF is not running on the local machine. ";
            cout << "Verify that STAFProc is running." << endl; 
        }
        return sError;
    }

    sResult = sHandlePtr->submit( local, 
                                  "var", 
                                  STAFString("SET HANDLE ") + STAFString( sHandlePtr->getHandle() ) + sEnv );

    if( sResult->rc != 0 )
    {
        cout << sResult->result << endl;

        return -1;
    }

    // All test case count
    if( sEnvTESTCASECOUNT == "TRUE" )
    {
        writeAllTestCase( &sPM, sInList, sEnvRESULT );
    }

    for( sIterator = sInList->begin();
         sIterator != sInList->end(); )
    {
        sIn = *sIterator;
        if( sIn.caseType == SQL )
        {
            if( runnable( &sPM,
                          sIn ) == ID_TRUE )
            {
                sRealRunables++;
            }
        }

        sIterator++;
    }

    for( sIterator = sInList->begin();
         sIterator != sInList->end(); )
    {
        sRun++;

        sIn = *sIterator;
        if( sIn.caseType == TS )
        {
            if( runnable( &sPM,
                          sIn ) == ID_FALSE )
            {
                sIterator++;
                continue;
            }

            copyData( sSuite1, 
                      sIn.caseName.buffer(),
                      sIn.caseName.length() );

            if( strcmp( sSuite2,
                        sSuite1 ) != 0 )
            {
                strcpy( sSuite2,
                        sSuite1 );
                
                cout << "+ " << STAFString( sSuite1 ).replace(sEnvCASE + FILE_SEPARATORS, "") << endl;
            }
        }
        else if( sIn.caseType == SQL )
        {
            if( runnable( &sPM, sIn ) == ID_FALSE )
            {
                sIterator++;
                continue;
            }

            copyData( sData1, 
                      sIn.caseName.buffer(),
                      sIn.caseName.length() );

            if( dirname( sIn.caseName ) != sOld )
            {
                sUnlink = sOld;
                sLink = dirname( sIn.caseName );
                sOld = dirname( sIn.caseName );
            }
            else
            {
                sLink = "";
                sUnlink = "";
            }

            memset( sData2,
                           '.',
                           sizeof(sData2) );

            memcpy( sData2,
                    atscBasename(sData1),
                    strlen(atscBasename(sData1)) );

            sData2[25] = '\0';

            //COMMENT
            copyData( sComment, 
                      sIn.caseComment.strip().toCurrentCodePage()->buffer(),
                      sIn.caseComment.strip().toCurrentCodePage()->length() );
                           
            sprintf( sPROGRESS, 
                     //"%3.0f%%", (float)sRun / sInList->size() * 100 );
                     "%3.0f%%", (float)sRealRunneds / sRealRunables * 100 );
            printf( "(%s) %-25s", sPROGRESS, sData2 );
            fflush( stdout );

            // printf( "\na: %s\n", atscBasename(sSuite1) );
            // printf( "b: %s\n", sComment );
            // continue;

            sRequest = "run ";
            sRequest += sIn.caseName;
            sRequest += " ts ";
            sRequest += STAFHandle::wrapData(atscBasename(sSuite1));
            sRequest += " fullts ";
            sRequest += STAFHandle::wrapData(sIn.tsName);
            sRequest += " comment ";
            sRequest += STAFHandle::wrapData(STAFString(sComment).replace("#", ""));
            sRequest += " logname ";
            sRequest += STAFHandle::wrapData(sEnvLOGNAME);
            sRequest += " hostname ";
            sRequest += STAFHandle::wrapData(sEnvHOSTNAME);
            sRequest += " link ";
            sRequest += STAFHandle::wrapData(sLink);
            sRequest += " unlink ";
            sRequest += STAFHandle::wrapData(sUnlink);
            
            if( sRun == sInList->size() )
            {
                sRequest += " unlink2 ";
                sRequest += STAFHandle::wrapData(dirname(sIn.caseName));
            }
            
            sRequest += " begin ";
            sRequest += sBEGIN;
            
            sRequest += " progress ";
            sRequest += sPROGRESS;

            // request 옵션으로 추가된 ATS 테스트타입
            sRequest += " testtype ";
            sRequest +=  STAFHandle::wrapData(sTESTTYPE);
            
            // 복구테스트 수행시 추가적으로 필요한 옵션
            if( sAtsTestType != ATS_TEST_NORMAL )
            {
                // 1) 사용할 복구지점목록 파일 경로 옵션
                sRequest += " recdatafile ";
                sRequest += STAFHandle::wrapData(sRECDATAFILE);

                if ( sAtsTestType == ATS_TEST_SEQUENTIAL )
                {
                    sRECPOINTID = *sRecIterator;

                    // 2) 테스트할 복구지점 ID 옵션 
                    sRequest += " recpointid ";
                    sRequest += STAFHandle::wrapData(sRECPOINTID.replace(":", "^"));
                }
            } 
            else
            {
                // noting to do ...
            }
            
            if( sBEGIN == 1 )
            {
                sBEGIN = 0;
            }

            sResult = sHandlePtr->submit( local, 
                                          ats, 
                                          sRequest );

            sRealRunneds++; 

            if( sResult->rc == 0 )
            {
                if( sResult->result.find( "PASS" ) 
                               != STAFString::kNPos )
                {
                    sPASS++;
                }
                else if( sResult->result.find( "FAIL" ) 
                               != STAFString::kNPos )
                {
                    sFAIL++;
                }  
                else if( sResult->result.find( "ERROR" ) 
                               != STAFString::kNPos )
                {
                    sERROR++;
                }  
                else if( sResult->result.find( "FATAL" )
                               != STAFString::kNPos )
                {
                    sFATAL++;
                
                    printResult( sResult->result );

                    printf( "\nCan't connect to Server.\n" );
                    break;
                }
                else if( sResult->result.find( "HIT" ) 
                         != STAFString::kNPos )
                {
                    // ART의 Sequential/Full 테스트 HIT 결과 
                    sHIT++;

                    if ( sAtsTestType == ATS_TEST_SEQUENTIAL )
                    {
                        /* 1. HIT된 복구지점은 STL list로부터 제거
                           2. HIT된 경우 지금까지의 MISS 누적개수 초기화 */
                        sRemRecIterator = sRecIterator;
                        sCHKMISS = 0;   
                        sRecIterator++;
                        gRecPtrList.erase( sRemRecIterator );
                    }
                 }
                 else if( sResult->result.find( "MISS" ) 
                          != STAFString::kNPos )
                 {
                    sMISS++;

                    if ( sAtsTestType == ATS_TEST_SEQUENTIAL )
                    {
                        /* MISS 누적개수를 카운트해서
                           다음 복구지점으로 넘어갈지 결정함
                           default 값 : 누적개수 1개이면 넘어감 */
                        sCHKMISS++;
                        if ( sCHKMISS % 1 == 0 )
                        {
                           sRecIterator++;
                        }
                    }
                } 
                else if( sResult->result.find( "CRASH" ) 
                         != STAFString::kNPos )
                {
                    sCRASH++;
                }
                else if ( sResult->result.find( "IGNR" ) 
                          != STAFString::kNPos )
                {
                    // nothing to do..
                    sIGNR++;
                }
                else
                {
                    printResult( sResult->result );
                    
                    break;
                }

                printResult( sResult->result );
            }
            else
            {
                if( (sResult->rc == 2) || 
                    (sResult->rc == 21) )
                {
                    printResult( sResult->result );
                    break;
                }
                else
                {
                    cout << " error: (" << sResult->rc << ") " << sResult->result << endl;
                }
            }
        }

        sIterator++; // go to next testcase

        /* Sequential Test의 경우 테스트슈트(*.ts)를
           수행하는데 있어서 무한정 반복수행할 수 있기때문에
           완료조건인 Hit Ratio를 계산하고 검사하여
           테스트를 완료시킴 */
        if ( sAtsTestType == ATS_TEST_SEQUENTIAL )
        {
            sHitRatio = (sHIT * 100 / sTotal);

            if ( sHitRatio > sEndCdt ) 
            {
                break;
            }

            if ( sIterator == sInList->end() )             
            {
                sIterator = sInList->begin();
            }
            
            if ( sRecIterator == gRecPtrList.end() )
            {
                sRecIterator = gRecPtrList.begin();
            }
        }
    }
    
    if( sFATAL == 0 )
    {
        copyData( sData1,
                  sEnvRESULT.buffer(),
                  sEnvRESULT.length() );

        sprintf( sData2,
                 "%s%s%s%s%s%s%s",
                 sData1, FILE_SEPARATORS, "work", FILE_SEPARATORS, "log", FILE_SEPARATORS, REPORT_LOG );

        copyData( sData3,
                  sEnvLOGNAME.buffer(),
                  sEnvLOGNAME.length() );

        copyData( sData4,
                  sEnvHOSTNAME.buffer(),
                  sEnvHOSTNAME.length() );

        sFp = NULL;
        sFp = fopen( sData2, "a" );
        if ( sFp == NULL )
        {
            printf( "Can't open file %s\n", sData2 );
            return -1;
        }

        if( logTimestamp( sFp ) != IDE_SUCCESS )
        {
            return -1;
        }
        fprintf( sFp,
                 "|%s|%s|%s\n",
                 "END", sData3, sData4 );

        fclose( sFp );
    }

    switch ( sAtsTestType )
    {
        case ATS_TEST_NORMAL:
        {
            printf( "\nPASS: %d FAIL: %d ERROR: %d\n", sPASS, sFAIL, sERROR );
            break;
        }
        case ATS_TEST_REGRESSIVE:
        {
            printf( "\nPASS: %d FAIL: %d CRASH: %d ERROR: %d\n", sPASS, sFAIL, sCRASH, sERROR );
            break;
        }
        defalut:
        {
            printf( "\nHIT: %d M:ISS %d CRASH: %d ERROR: %d\n", sHIT, sMISS, sCRASH, sERROR );
            break;
        }
    }

    return 0;
}

SInt writeAllTestCase( PlatformManager *aPM, CaseList *aInList, STAFString aEnvRESULT )
{
    FILE *sFp;
    caseInfo        sIn;
    CaseIterator    sIterator;
    SChar           sTestCase;
    SChar           sData1[BUFFER_SIZE];
    SChar           sData2[BUFFER_SIZE];
    SChar           sSuite[BUFFER_SIZE];

    copyData( sData1,
              aEnvRESULT.buffer(),
              aEnvRESULT.length() );

    sprintf( sData2,
             "%s%s%s%s%s%s%s",
             sData1, FILE_SEPARATORS, "work", FILE_SEPARATORS, "log", FILE_SEPARATORS, "all_count.log" );

    sFp = NULL;

    sFp = fopen( sData2, "a+" );

    if ( sFp == NULL )
    {
        printf( "Can't open file %s\n", sData2 );
        return -1;
    }

    for( sIterator = aInList->begin();
         sIterator != aInList->end();
         sIterator++ )
    {
        sIn = *sIterator;

        if( sIn.caseType == TS )
        {
            if( runnable( aPM,
                          sIn ) == ID_FALSE )
            {
                continue;
            }
        }
        else if( sIn.caseType == SQL )
        {
            if( runnable( aPM,
                          sIn ) == ID_FALSE )
            {
                if ( sIn.caseMark == RUNSKIP )
                {
                    sTestCase = 'S'; // block test case
                }
                else
                {
                    sTestCase = 'N'; // block test case
                }
            }
            else
            {
                sTestCase = 'Y'; // non-block test case
            }

            copyData( sSuite,
                      sIn.caseName.buffer(),
                      sIn.caseName.length() );

            fprintf( sFp,
                     "%c|%s\n",
                     sTestCase, sSuite );
        }
    }
    fclose( sFp );

    return 0;
}

idBool runnable( PlatformManager *aPM,
                 caseInfo         aIn )
{
    if( aIn.caseMark == NOTRUNABLE )
    {
        return ID_FALSE;
    }
    if( aIn.caseMark == RUNSKIP )
    {
        return ID_FALSE;
    }

    if( (aIn.casePlatformName.length() == 0) )
    {
        return ID_TRUE;
    }

    if( aIn.caseFlag == PLAT_ON )
    {
        if( aPM->contains(aIn.casePlatformName) == ID_TRUE )
        {
            return ID_FALSE;
        }
        else
        {
            return ID_TRUE;
        }
    }
    else if( aIn.caseFlag == PLAT_OFF )
    {
        if( aPM->contains(aIn.casePlatformName) == ID_TRUE )
        {
            return ID_TRUE;
        }
        else
        {
            return ID_FALSE;
        }
    }

    return ID_TRUE;
}

IDE_RC
logTimestamp( FILE *aTarget )
{
    time_t timet;
    struct tm  *now;

    time(&timet);
    now = localtime(&timet);

    return fprintf( aTarget,
                           "[%4"ID_UINT32_FMT
                           "/%02"ID_UINT32_FMT
                           "/%02"ID_UINT32_FMT
                           " %02"ID_UINT32_FMT
                           ":%02"ID_UINT32_FMT
                           ":%02"ID_UINT32_FMT"] ",
                           now->tm_year + 1900,
                           now->tm_mon + 1,
                           now->tm_mday,
                           now->tm_hour,
                           now->tm_min,
                           now->tm_sec) >= 0 ? IDE_SUCCESS : IDE_FAILURE;
}

SInt checkConfFile( STAFString aEnvCASE, 
                    STAFString aEnvRESULT )
{
    FILE       *sFp = NULL;
    FILE       *sFp2 = NULL;

    SChar       sData1[BUFFER_SIZE];
    SChar       sData2[BUFFER_SIZE];
    SChar       sData3[BUFFER_SIZE];
    SChar       sData4[BUFFER_SIZE];

    copyData( sData1,
              aEnvCASE.buffer(),
              aEnvCASE.length() );

    copyData( sData2,
              aEnvRESULT.buffer(),
              aEnvRESULT.length() );

    // server.conf 파일 유무 체크
    sprintf( sData3,
             "%s%s%s%s%s",
             sData1, FILE_SEPARATORS, "conf", FILE_SEPARATORS, SERVER_FILE );

    sprintf( sData4,
             "%s%s%s%s%s%s%s",
             sData2, FILE_SEPARATORS, "work", FILE_SEPARATORS, "log", FILE_SEPARATORS, EXCEPTION_LOG );

    sFp = NULL;
    sFp = fopen( sData3, "r" );
    if( sFp == NULL )
    {
        printf( "[ERROR] Can't open file %s\n", sData3 );
        
        sFp2 = NULL;
        sFp2 = fopen( sData4, "a+" );

        if( sFp2 == NULL )
        {
            printf( "[ERROR] Can't open file %s\n", sData4 );
            return -1;
        }
        fprintf( sFp2, "[ERROR] Can't open file %s\n", sData3 );
        fclose( sFp2 );
        return -1;
    }

    // platform.conf 파일 유무 체크
    sprintf( sData3,
             "%s%s%s%s%s",
             sData1, FILE_SEPARATORS, "conf", FILE_SEPARATORS, PLATFORM_FILE );

    sFp = NULL;
    sFp = fopen( sData3, "r" );
    if( sFp == NULL )
    {
        printf( "[ERROR] Can't open file %s\n", sData3 );

        sFp2 = NULL;
        sFp2 = fopen( sData4, "a+" );

        if( sFp2 == NULL )
        {
            printf( "[ERROR] Can't open file %s\n", sData4 );
            return -1;
        }
        fprintf( sFp2, "[ERROR] Can't open file %s\n", sData3 );
        fclose( sFp2 );
        return -1;
    }

    fclose( sFp );

    return 0;
}
