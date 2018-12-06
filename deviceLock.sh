#!/bin/bash 
#
####################################################################################################
#
# Copyright (c) 2016, JAMF Software, LLC.  All rights reserved.
#
#       This script was written by JAMF Software
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#####################################################################################################
#
# SUPPORT FOR THIS PROGRAM
#
#       This program is distributed "as is" by JAMF Software. For more information or
#		support for this script, please contact your JAMF Software Account Manager.
#
#####################################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#	
#	deviceLock.sh
#
# SYNOPSIS - How to use
#	
# 	Add this script to jamf | PRO into our script repository.  We can then add this to a policy
#	that is set to onging and scoped to all managed computers in jamf | PRO.  We will set the 
#	frequency to run at recurring check-in so we can capture computers that are sitting at the
#	login screen.
# 
# DESCRIPTION
# 	
# 	This script will look up the user asssigned to a computer in jamf | PRO.
#	If they are disabled in active directory a DeviceLock remote command is sent that computer.  
#	There will be an echoed response if the command was sent to the device or not within 
#	the device inventory record where we chose to display this extenstion attribute.  
# 
####################################################################################################
#
# HISTORY
#
#	Version: 1.0 by Lucas Vance @ Jamf 3-10-17
#	
#		Tried using md5 hashes for the variables and it did not work when ran manually as well as 
#		an automated extension attribute in jamf | PRO.  We will have to use hardcoded variables
#				- Lucas Vance 3-13-17 @ Jamf
#
#	Version: 1.1 by Lucas Vance @ Jamf 3-14-17
#		Added logic to use script parameters so we can run this within a policy on the recurring
#		check-in.  This also provides security so we dont need to store clear text variables within
#		the script.
#
####################################################################################################
#################### Variables ####################
jamfUser="" # jamf | PRO admin username; Script Parameter 4
jamfPass="" # jamf | PRO admin password; Script Parameter 5
jamfURL="" # Full jamf | PRO URL including port, please no trailing slash, example: https://jamf.com:8443; Script Parameter 6
domain="" # example dc=ad,dc=jamfsw,dc=corp; Script Paremeter 7
adminAccount="" # exampl AD\Administrator; Script Parameter 8
adminPass="" # AD admin password example jamf1234; Script Parameter 9
ldapDomain="" # example ad1.ad.jamfs.corp; Script Parameter 10
adPort="" # LDAP Port, please leave this hardcoded as we can only set 8 script parameters
serial=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
eaName="Device Lock Status" # This is the EA that we created that will show whether or not a computer received the DeviceLock command based on the logic designed in this script
#################### Please Do No Modify Below This Line ####################
#################### Script Parameters ####################
#################### jamfUser ####################
if [ -n "$4" ]; then
	jamfUser=$4
fi
#################### jamfPass ####################
if [ -n "$5" ]; then
	jamfPass=$5
fi
#################### jamfURL ####################
if [ -n "$6" ]; then
	jamfURL=$6
fi
#################### domain ####################
if [ -n "$7" ]; then
	domain=$7
fi
#################### adminAccount ####################
if [ -n "$8" ]; then
	adminAccount=$8
fi
#################### adminPass ####################
if [ -n "$9" ]; then
	adminPass=$9
fi
#################### ldapDomain ####################
if [ -n "${10}" ]; then
	ldapDomain=${10}
fi
#################### passcode ####################
if [ -n "${11}" ]; then
	adPort=${11}
fi
#################### Get User ID From Jamf | PRO ####################
set -x 
user=$(/usr/bin/curl -sk -u $jamfUser:$jamfPass -H "Accept: application/xml" $jamfURL/JSSResource/computers/serialnumber/$serial | xmllint --format - | sed -n '/<location/,/\/location>/p' | grep "<username>" | cut -f2 -d">" | cut -f1 -d"<")
uac=$(/usr/bin/ldapsearch -LLL -h "$ldapDomain" -p "$adPort" -b "$domain" -D "$adminAccount" -w "$adminPass" '(sAMAccountName='$user')' | grep "userAccountControl" | cut -f2 -d":" | sed 's/ //g')
cid=$(/usr/bin/curl -sk -u $jamfUser:$jamfPass -H "Accept: application/xml" $jamfURL/JSSResource/computers/serialnumber/$serial | xmllint --format - | sed -n '/<general/,/\/id>/p' | grep "<id>" | cut -f2 -d">" | cut -f1 -d"<")
passcode=$(/usr/bin/jot -r 1 100000 999999 2>&1)
if [ "$uac" = 66050 ] || [ "$uac" = 514 ] || [ "$uac" = 16 ] || [ "$uac" = 8388608 ]; then
	eaD="<computer><extension_attributes><extension_attribute><name>$eaName</name><value>DeviceLock Sent</value></extension_attribute></extension_attributes></computer>"
	lock="<computer_command><general><command>DeviceLock</command><passcode>$passcode</passcode></general><computers><computer><id>$cid</id></computer></computers></computer_command>"
	blank="<computer_command><general><command>BlankPush</command></general><computers><computer><id>$cid</id></computer></computers></computer_command>"
	/usr/bin/curl -sk -u $jamfUser:$jamfPass -H "Content-Type: text/xml" -o /dev/null -d "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>$lock" $jamfURL/JSSResource/computercommands/command/DeviceLock -X POST
	/usr/bin/curl -sk -u $jamfUser:$jamfPass -H "Content-Type: text/xml" -o /dev/null -d "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>$blank" $jamfURL/JSSResource/computercommands/command/BlankPush -X POST
	/usr/bin/curl -sk -u $jamfUser:$jamfPass -H "Content-Type: text/xml" -o /dev/null -d "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>$eaD" $jamfURL/JSSResource/computers/id/$cid/subset/extensionattributes -X PUT
	/usr/local/jamf/bin/jamf recon
else
    eaA="<computer><extension_attributes><extension_attribute><name>$eaName</name><value>DeviceLock Not Sent</value></extension_attribute></extension_attributes></computer>"
    /usr/bin/curl -sk -u $jamfUser:$jamfPass -H "Content-Type: text/xml" -o /dev/null -d "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>$eaA" $jamfURL/JSSResource/computers/id/$cid/subset/extensionattributes -X PUT
fi
set +x