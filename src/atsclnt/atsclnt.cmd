/*****************************************************************************/
/* Software Testing Automation Framework (STAF)                              */
/* (C) Copyright IBM Corp. 2001                                              */
/*                                                                           */
/* This software is licensed under the Common Public License (CPL) V1.0.     */
/*****************************************************************************/

/* The STAFClnt program written in REXX */
OPTIONS "ETMODE EXMODE"

SIGNAL ON HALT NAME STAFABORT

parse arg where service request

if request = "" then
do
    say
    say "Usage: STAF <Where> <Service> <Request>"
    say
    say "where,"
    say
    say "<Where> is either LOCAL or the name of the machine to which you wish"
    say "to submit the request."
    say
    say "<Service> is the name of the service to which you wish to submit the"
    say "request."
    say
    say "<Request> is the actual request you wish to submit to the <Service>"
    say
    say "For example:"
    say
    say "STAF LOCAL VAR LIST"
    say "STAF Client1 PROCESS START COMMAND d:\testcase\tc1.exe"

    RETURN 1
end

call RxFuncAdd 'STAFLoadFuncs', 'RXSTAF', 'STAFLoadFuncs'
call STAFLoadFuncs

call STAFRegister "STAF_REXX_Client", "STAFHandle"
if RESULT \= 0 then
do
    say "Error registering with STAF, RC:" RESULT
    RETURN RESULT
end

STAFRC = STAFSubmit(STAFHandle, where, service, request)
if STAFRC \= 0 then
do
    say "Error submitting request, RC:" STAFRC
    if STAFResult \= "" then
        say "Additional info:" STAFResult
end
else
do
    say "Response"
    say "--------"
    say STAFResult
end

call STAFUnRegister STAFHandle

RETURN STAFRC


/* Make sure to unregister */

STAFABORT:

    call STAFUnRegister STAFHandle
    EXIT 1
