<html>
<body>
<pre>
<h1>Build Log</h1>
<h3>
--------------------Configuration: target - Win32 (WCE ARMV4) Debug--------------------
</h3>
<h3>Command Lines</h3>
Creating temporary file "C:\DOCUME~1\altibase\LOCALS~1\Temp\RSP96.tmp" with contents
[
/nologo /W3 /Zi /Od /I "C:\work\natc\src\target_agent\include" /D "DEBUG" /D "ARM" /D "_ARM_" /D "ARMV4" /D UNDER_CE=420 /D _WIN32_WCE=420 /D "WCE_PLATFORM_STANDARDSDK" /D "UNICODE" /D "_UNICODE" /Fo"ARMV4Dbg/" /Fd"ARMV4Dbg/" /MC /c 
"C:\work\natc\src\target_agent\target\target.cpp"
"C:\work\natc\src\target_agent\target\wince.cpp"
]
Creating command line "clarm.exe @C:\DOCUME~1\altibase\LOCALS~1\Temp\RSP96.tmp" 
Creating temporary file "C:\DOCUME~1\altibase\LOCALS~1\Temp\RSP97.tmp" with contents
[
commctrl.lib coredll.lib ws2.lib /nologo /base:"0x00010000" /stack:0x10000,0x1000 /entry:"WinMainCRTStartup" /incremental:yes /pdb:"ARMV4Dbg/target.pdb" /debug /nodefaultlib:"libc.lib /nodefaultlib:libcd.lib /nodefaultlib:libcmt.lib /nodefaultlib:libcmtd.lib /nodefaultlib:msvcrt.lib /nodefaultlib:msvcrtd.lib" /out:"ARMV4Dbg/target.exe" /subsystem:windowsce,4.20 /align:"4096" /MACHINE:ARM 
.\ARMV4Dbg\target.obj
.\ARMV4Dbg\wince.obj
]
Creating command line "link.exe @C:\DOCUME~1\altibase\LOCALS~1\Temp\RSP97.tmp"
<h3>Output Window</h3>
Compiling...
target.cpp
wince.cpp
Generating Code...
Linking...




<h3>Results</h3>
target.exe - 0 error(s), 0 warning(s)
</pre>
</body>
</html>
