#!/bin/sh
####################################################################################################
#
# ABOUT
#
#   Standard functions which are imported into other scripts
#
####################################################################################################



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#
# LOGGING
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 


## Variables
logFile="/var/log/com.company.log"
alias now="/bin/date '+%Y-%m-%d %H:%M:%S'"


## Check for / create logFile
if [ ! -f "${logFile}" ]; then
    # logFile not found; Create logFile ...
    /usr/bin/touch "${logFile}"
    /bin/echo "`/bin/date +%Y-%m-%d\ %H:%M:%S`  *** Created log file via function ***" >>"${logFile}"
fi

## I/O Redirection to client-side log file
exec 3>&1 4>&2            # Save standard output (stdout) and standard error (stderr) to new file descriptors
exec 1>>"${logFile}"        # Redirect standard output, stdout, to logFile
exec 2>>"${logFile}"        # Redirect standard error, stderr, to logFile


function ScriptLog() { # Write to client-side log file ...

    /bin/echo "`/bin/date +%Y-%m-%d\ %H:%M:%S`  ${1}"

}



function jssLog() { # Write to JSS ...

    ScriptLog "${1}"              # Write to the client-side log ...

    ## I/O Redirection to JSS
    exec 1>&3 3>&- 2>&4 4>&-        # Restore standard output (stdout) and standard error (stderr)
    /bin/echo "${1}"              # Record output in the JSS

}