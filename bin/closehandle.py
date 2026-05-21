#!/usr/bin/python
import sys, os, re

def closeOSHandle(targetHandle):
    userName = "%s\\\\%s" % (os.getenv("HOSTNAME").upper(),os.getenv("LOGNAME"))

    l = os.popen('handle.exe -u %s' % (targetHandle)).readlines()[5:]
    if len(l) == 1 and 'No matching handles found' in l[0]:
        print l[0]; return

    #from pprint import pprint; pprint(l)

    handles = []
    for e in l:
    	found = re.findall(r'''(.+?) * pid: ([0-9a-zA-Z].+?) * %s .* ([0-9a-zA-Z].+?): (.*)''' % (userName), e.strip())
	if len(found) > 0: handles.append(found[0])

    for procName, pid, handleId, handleName in handles:
        print "close handle : %s[%s] : %s[%s]" % (handleName, handleId, procName, pid)
        cmd = 'handle.exe -c %s -p %s -y' % (handleId, pid) 
        print cmd
        os.system(cmd)

if __name__=="__main__":
    try: targetHandle = sys.argv[1]
    except: targetHandle = "altibase_home"  
    closeOSHandle(targetHandle)

