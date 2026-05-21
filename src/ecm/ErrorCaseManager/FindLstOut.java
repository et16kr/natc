package ErrorCaseManager;

import java.io.*;
import java.util.*;

/* public class FindPathName
{
    private String t_case;

    FindPathName( String str )
    {
        this.t_case = str;
        System.out.println( this.t_case );
    }

    public static void main( String args[] )
    {
        FindLstOut findFile = new FindLstOut( t_case );
        
        findFile.getAllEnv();

        // altibase.info 파일을 읽어서
        // lst, out의 파일 이름과 path를 구성하는 정보를 가져온다.
        findFile.readFile();

        findFile.findPathName();
    }
} */

public class FindLstOut
{
    public String lstName = "";
    public String outName = "";
    public String tdxName = "";

    private char altibaseVer = 0;
    private String platformName = "";
    private String bitNumber = "";

    private String homeDir = "";
    private String workDir = "";

    private String testOraclePath = "";
    private String testResultPath = "";
    private String testOracleSuffix = "";
    private String testResultSuffix = "";

    private String t_case = "";
    private String pathSeparator;

    String mOsTarget = "";
    String temp = "";
    String temp2 = "";

    // private String t_case = "/home2/copyrei2/work/atc4/TC/Server/qp4/Basic/1.sql";
    // private String t_case = "/home2/copyrei2/1.sql";

    FindLstOut()
    {
        // this.t_case = str;
        // System.out.println( t_case );
        mOsTarget = System.getProperty( "OS_TARGET" );
    }

    void findPathName( String t_case )
    {
        pathSeparator = "/";

        String[] strToken = null; 
        String[] lstKind = null;

        String fileName = "";
        String onlyFileName = "";
        String path ="";

        String lstPath = pathSeparator;
        String outPath = "";
        String afterPath = pathSeparator;
        String driveName = "";

        boolean isAfterTC = false;
        strToken = t_case.split( pathSeparator );
        driveName = strToken[0];

	BufferedReader bufReaderOut = null;
	StringTokenizer stok;
	String str, regExp; 
	String[] pathToken = null;
	String[] subStr = null;
	boolean isAfterPathTC = false;

        int i = 0;

        while( true )
        {
            try
            {
                // System.out.println( "!! " + strToken[i] );
                fileName = strToken[i];
            }
            catch ( Exception e )
            {
                // Array Out of Bounds
                break;
            }
            i++;
        }
        // System.out.println( "!!! " + fileName );
        // System.out.println( "!!! " + strToken.length );

        for ( i = 0; i < strToken.length - 1; i++ )
        {
            path += strToken[i];
            path += pathSeparator;
        }
        // System.out.println( "!!! " + path );

        strToken = fileName.split( ".sql" );
        onlyFileName = strToken[0];

        // System.out.println( "!!! " + onlyFileName );

        // lst의 종류 결정
        strToken = testOracleSuffix.split( "," );

	int tokenLen = strToken.length;
        boolean findLstFile = false;

        i = 0;

        // lst의 종류 결정하기 위한 while loop
        while( tokenLen > 0 )
        {
            try
            {
                lstName = path + onlyFileName + strToken[tokenLen-1] + ".lst";
                
                File file = new File( lstName );
                if ( file.exists() )
                {
                    // System.out.println( "!!!Exist!!" );
                    findLstFile = true;
                    break;
                }
            }
            catch ( Exception e )
            {
                // Array Out of Bounds
                break;
            }
            tokenLen--;
        }

        if ( findLstFile == false )
        {
            System.out.println( "[ERROR] No LST File Exist!!" );
            // System.exit(1);
        }

        i = 0;

        // atc4/TC에 있는 sql이므로 ATAF_TEST_RESULT로 경로를 바꿔줘야 한다.
        if ( path.matches( ".*atc.*TC.*" ) )
        {
            // System.out.println( "!!! It's ATC/TC" );

            strToken = path.split( pathSeparator );

            while( true )
            {
                try
                {
                    if ( strToken[i].equals( "TC" ) || isAfterTC )
                    {
                        afterPath += strToken[i];
                        afterPath += pathSeparator;
                        isAfterTC = true;
                    }
                }
                catch ( Exception e )
                {
                    // Array Out of Bounds
                    break;
                }
                i++;
            }
            outPath += testResultPath + afterPath;
            isAfterTC = false;
        }
        else
        {
            outPath = path;
        }

        outName = outPath + onlyFileName + testResultSuffix + ".out";
        tdxName = outPath + onlyFileName + testResultSuffix + ".tdx";

	/* 
	   fix for BUG-31576
	   병렬 테스트의 경우 outName 안의 패스를 수정해야한다.
	   natc_result -> natc_result/result_p[0-13]
	*/

        File file = new File( outName );

	// outName의 파일을 열어 보고 존재하지 않다면 lstout.log를 이용해서 다시 찾아본다.
	if ( !file.exists() )
        {
	    File lstoutFile = new File( testResultPath + pathSeparator + "work" + pathSeparator + "log" + pathSeparator + "lstout.log" );
            try
            {
                bufReaderOut = new BufferedReader( new FileReader( lstoutFile ) );
            }
            catch( Exception e )
            {
                System.err.println(e);
            }

	    // lstout.log 파일이 있다면 실패한 테스트 케이스의 lst 파일과 out 파일의 전체 패스를 한 줄씩 읽는다.
            if ( lstoutFile.canRead() )
            {
                while( true )
                {
                    // get line
                    try
                    {
                        // String Tokenizer
                        stok = new StringTokenizer( bufReaderOut.readLine(), " ");

			str = stok.nextToken();

            		pathToken = path.split( pathSeparator );

			outPath = "";

			// lstout.log에서 읽은 테스트 케이스의 전체 path중 TC 이후의 path만 잘라냄.
			for ( i=0; i<pathToken.length; i++ )
			{
			    if ( isAfterPathTC == false )
			    {
			        if ( pathToken[i].matches( ".*TC.*" ) )
			        {
			            isAfterPathTC = true;
			        }
			    }
			    else
			    {
			    	outPath += pathToken[i] + pathSeparator;
			    }
			}

			// 잘라낸 path와 outName을 찾아야할 테스트 케이스의 path와 비교함.
			regExp = ".*" + outPath + onlyFileName + ".*";

			// matching이 된다면 output file의 path를 구함
			if ( str.matches( regExp ) )
			{

			    str = stok.nextToken();
			    // System.out.println("Matching" + str);

			    subStr = str.split(".out$"); 

			    outName = subStr[0] + ".out";
			    tdxName = subStr[0] + ".tdx";

   		      	    break;

			}
			else
			{
			    // System.out.println("Fail matching" + str + " " + onlyFileName);
			    isAfterPathTC = false;
			}
    
                    }
                    catch (Exception e)
                    {
                        // Stop readLine if null EOF same == null
                        break;
                    }
	        }
            }
	    else
	    {
                System.err.println( "Error: I can't read file: lstout.log" );
	    }
        }

        System.out.println( "TEST_ORACLE_NAME: " + lstName );
        System.out.println( "TEST_RESULT_NAME: " + outName );
    }

    void getAllEnv()
    {
        this.homeDir  = System.getProperty("ATC_HOME");
        workDir  = System.getProperty("ATC_WORK");

        testOraclePath  = System.getProperty("ATAF_TEST_CASE");
        testResultPath  = System.getProperty("ATAF_TEST_RESULT");
        testOracleSuffix = System.getProperty("ATAF_ORACLE_SUFFIX");
        testResultSuffix = System.getProperty("ATAF_RESULT_SUFFIX");

        // System.out.println( "ATC_HOME: " + homeDir );
        // System.out.println( "ATC_WORK: " + workDir );

        System.out.println( "ATAF_TEST_CASE: " + testOraclePath );
        System.out.println( "ATAF_TEST_RESULT: " + testResultPath );
        System.out.println( "ATAF_ORACLE_SUFFIX: " + testOracleSuffix );
        System.out.println( "ATAF_RESULT_SUFFIX: " + testResultSuffix );
    }

    void readFile()
    {
        String strToken;
        StringTokenizer stok;

        String[] strToken2;

        BufferedReader bufReader = null;
        StringBuffer strBuf = null;
        strBuf = new StringBuffer();

        pathSeparator = "/";


        File file = new File( testResultPath + pathSeparator + "work" + pathSeparator +  "altibase.info" );

        try
        {
            bufReader = new BufferedReader( new FileReader( file ) );
        }
        catch( Exception e )
        {
            System.err.println(e);
        }

        if ( !file.canRead() )
        {
            System.err.println( "Error: I can't read file: altibase.info" );
            System.exit(1);
        }

        while( true )
        {
            // get line
            try
            {
                // String Tokenizer
                stok = new StringTokenizer( bufReader.readLine(), " ");

                for (int index = 0; stok.hasMoreTokens(); index++ )
                {
                    strToken =  stok.nextToken();

                    switch ( index )
                    {
                        case 0:
                        {
                            break;
                        }
                        case 1:
                        {
                            altibaseVer = strToken.charAt(0);
                            // System.out.println( "!!! " + altibaseVer );
                            break;
                        }
                        case 2:
                        {
                            strToken2 = strToken.split ( "_" );

                            platformName = strToken2[0];
                            platformName += "_";
                            platformName += strToken2[1];
    
                            // System.out.println( "!!! " + platformName );
                            break;
                        }
                        default :
                        {
                            break;
                        }
                    }
                }
            }
            catch (Exception e)
            {
                // Stop readLine if null EOF same == null
                break;
            }
        }
    } // end of readFile()
}
