DEF SET_ALTILINKER_PROPERTY(@aAltibaseHome, @aPropertyName, @aPropertyValue)
{
    $sPattern  = @aPropertyName || " *= *\"*[?/\a\w]*\"*";
    $sReplace  = @aPropertyName || " = " || @aPropertyValue;
    $sFilePath = @aAltibaseHome || "/conf/dblink.conf";

    NODISPLAY ON;

    IF (FEXIST $sFilePath)
    {
        FILESIZE $sFileSize $sFilePath;

        IF ($sFileSize > 0)
        {
            SED $sPattern $sReplace $sFilePath;
            NODISPLAY OFF;

            PRINT "@{aPropertyName} = @{aPropertyValue} at ${sFilePath}";
        }
        ELSE
        {
            NODISPLAY OFF;

            PRINT "\'${sFilePath}\' file size is 0 (empty)!";
        }
    }
    ELSE
    {
        NODISPLAY OFF;

        PRINT "\'${sFilePath}\' file do not exist!";
    }
}

DEF GET_ALTILINKER_PROPERTY(@aAltibaseHome, @aPropertyName)
{
    $sFilePath = @aAltibaseHome || "/conf/dblink.conf";
    $sPropertyValue;

    NODISPLAY ON;

    IF (FEXIST $sFilePath)
    {
        OPEN FILE1 $sFilePath;
        READ FILE1 $sFileContents;
        CLOSE FILE1;

        GETROW @aPropertyName $sFileContents $sProperty;
        GETCOLUMN -i 0 "${3}" $sProperty $sPropertyValue;

        NODISPLAY OFF;
    }
    ELSE
    {
        NODISPLAY OFF;

        PRINT "\'${sFilePath}\' file do not exist!";
    }

    return $sPropertyValue;
}

