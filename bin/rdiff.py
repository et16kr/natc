#!/usr/bin/python

# sbjang 16/08/09 - created

import os
import string
import sys
import re

def load( file ):
    fd = open( file, 'r' )

    s = 0
    plan = 0
    desc = 0
    array = []
    lineno = 0

    while 1:
        input = fd.readline()
        lineno += 1

        if string.find( input, "PROJECT (" ) != -1 or string.find( input, "INSERT (" ) != -1 or string.find( input, "UPDATE (" ) != -1 or string.find( input, "DELETE (" ) != -1 or string.find( input, "MOVE (" ) != -1:
            plan = 1
            s = 0

        if desc == 1 and  re.search('\$[P|T][0-9]\>', input, re.I) or re.search( 'iSQL\> ', input):
            desc = 0

        if re.search( '\$[T|P][0-9]\> DESC[\t| ]', input, re.I ) or re.search( 'iSQL\> DESC[\t| ]', input, re.I ):
            desc = 1

        if desc == 0:
            if input[:10] == "----------":
                if plan == 1:
                    plan = 0
                else:
                    s = 1 
            else:
                if s == 1:
                    # blank or graph
                    if string.strip( input ) != "" and input[0:1] != "|":
                        #print input
                        #array.append( input.rstrip() )
                        array.append( ( lineno, input ) )
 
        if input == "":
            break
      
        if string.find( input, " selected." ) != -1:
            s = 0

    #array.sort()
    result = sorted( array, key=lambda x: x[1])

    return result

def wrt( file, arr ):
    f = open(file, 'w')

    out = "".join(arr);

    f.write(out)
    f.close()
    return;

def wrtln( file, arr ):
    fd = open(file, 'w')
    
    out = "".join( [ "%s\t| %s" % x for x in arr ] )

    fd.write(out)
    fd.close()
    return;

def compare( arg1, arg2 ):
    array1 = load( arg1 )
    array2 = load( arg2 )

    if cmp( [ i[1] for i in array1 ] , [ j[1] for j in  array2 ] ) == 0:
        return "PASS"
    else:
        wrt( arg1+".srt", ( i[1] for i in array1 ) )
        wrt( arg2+".srt", ( i[1] for i in array2 ) )
        wrtln( arg1+".ln", array1 )
        wrtln( arg2+".ln", array2 )
        return "FAIL"

if __name__ == "__main__":
    #print compare( "a.lst", "a.out" )

    if len( sys.argv ) != 3:
        print "chech $ATAF_TEST_CASE"
        print "chech $ATAF_TEST_RESULT"
        sys.exit()
    
    ataf_test_path = sys.argv[1]
    ataf_result_path = sys.argv[2]
    
    if ataf_result_path == "":
        print "chech $ATAF_TEST_RESULT" 
        sys.exit()

    test_work_path = ataf_result_path + "/work/"
    report_log_path = test_work_path + "log/report.log"
    result_diff_path = test_work_path+"resultdiff.tkdiff"

    fts = open( test_work_path+"TS999999.ts", 'r' )
    fs = open( result_diff_path, 'w')
    fre = open( report_log_path, 'r')
    
    firstline = (fre.readline()).split( '|' )

    fre.close()
    fr = open( test_work_path+"result.ts", 'w')

    # make header of result.ts
    header = "## DiffViewer Result ## 0 # " + report_log_path + " # " + str( os.path.getsize( report_log_path ) ) + " # " + firstline[0] + " # " + ataf_result_path
    fr.write(header)
    fr.write('\n')

    while 1:
        input = fts.readline()

        if input == "":
            break

        if string.strip( input ) == "":
            continue

        if string.find( input, "TestSuiteDescription" ) != -1:
            continue

        if input[0:1] == "#":
            continue

        format =input.split( '#' )

        tc = format[0]
        tc = tc.rstrip()
        
        natcform = format[2].split( ':' )
        natcform[0] = natcform[0].strip()
        natcform[1] = natcform[1].strip()

        lst = re.sub( "\.tc", natcform[0]+".lst", tc )
        out = re.sub( "\.tc", natcform[1]+".out", tc )
        
        lst = re.sub( "\.sql", natcform[0]+".lst", lst )
        out = re.sub( "\.sql", natcform[1]+".out", out )
        out = re.sub( ataf_test_path, ataf_result_path, out )

        #print lst + "\n" + out
        #"""
        if os.path.exists( lst ) == True and os.path.exists( out ) == True:
            if compare( lst, out ) == "PASS":
                fr.write( tc + ' # CORED # rdiff # ' + natcform[0] + ' # ' + natcform[1] +'\n' )
                print tc, "PASS"
            else:
                fr.write( tc + ' # FAIL # rdiff # ' + natcform[0] + ' # ' + natcform[1] +'\n' )
                fs.write('tkdiff '+lst+'.srt '+out+'.srt\n');
                print tc, "FAIL"
        else:
            fr.write( tc + ' # ERROR # rdiff # ' + natcform[0] + ' # ' + natcform[1] +'\n' )
            print tc, "ERROR"
        #"""
    fts.close();
    fs.close();
    fr.close();

    #print "if you want to know the file line info vim [filename].lst.ln or [filename].out.ln"
    os.system( "diffv &" )
    os.system( "sh "+ result_diff_path )

