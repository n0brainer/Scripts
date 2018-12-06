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
#	ADBind.sh
#
# SYNOPSIS - How to use
#	
# 	Add this script to the JSS so we can use it within a policy.  Please create a policy that we can	
# 	run this script to bind computers to AD.  If we have a policy already, we can remove the directory
#	binding payload and configure the script payload and add this script to the same policy. 
#
# DESCRIPTION
# 	
# 	This script is designed to bind machines to Active Directory.
# 
####################################################################################################
#
# HISTORY
#
#	Version: 2.0 by Lucas Vance @ JAMF Software 10-7-16
#
####################################################################################################
########## Active Directory Variables ##########
adAdmin="" # Active Directory account used to authenticate the bind
adPass="" # Password for the above user account
adDomain="" # Active Directory Domain; ex. ad.jamfsw.corp
ou="" # OU where the computers are found; ex. CN=computers,DC=ad,DC=jamfsw,DC=corp
########## Get Computer Name Of Device ##########
computerName=$(/usr/sbin/scutil --get ComputerName)
########## Create Function For Automated Keystroke ##########
function keystroke (){
    keystroke=`/usr/bin/osascript << EOT
    tell application "System Events"
    keystroke "y"
    keystroke return
    end tell
EOT`
}
########## Bind Computer To Active Directory ##########
/usr/bin/sudo -i /usr/sbin/dsconfigad -force -a $computerName -u $adAdmin -p $adPass -ou "$ou" -domain $adDomain -mobile enable -mobileconfirm disable -localhome enable -useuncpath disable -alldomains enable
keystroke &> /dev/null