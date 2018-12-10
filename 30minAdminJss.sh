#!/bin/bash
##############
# This script will give a user 30 minutes of Admin level access, from Jamf's self service.
# At the end of the 30 minutes it will then call a jamf policy with a manual trigger. 
# Remove the users admin rights and disable the plist file this creates and activites.
# The removal script is 30minAdminjssRemoved.sh
#
# This was writen by
# Kyle Brockman
# While working for Univeristy Information Technology Servives
# at the Univeristy of Wisconsin Milwaukee
##############
LOGPATH='/private/var/log'
LOGFILE=/private/var/log/tempadmin-$(date +%Y%m%d-%H%M).logging
U=`who |grep console| awk '{print $1}'`

## Setup logging
# mkdir $LOGPATH
set -xv; exec 1> $LOGPATH/tempadmin.txt 2>&1

/bin/echo "notifying user of admin rights..."
/bin/date
TODAY=`date +"%Y-%m-%d"`

# Message to user they have admin rights for 30 min. 
/usr/bin/osascript <<-EOF
			    tell application "System Events"
			        activate
			        display dialog "You now have admin rights to this machine for 30 minutes" buttons {"Let Me at it."} default button 1
			    end tell
			EOF

/bin/echo "placing launchD plist to call JSS policy to remove admin rights..."
/bin/date
TODAY=`date +"%Y-%m-%d"`
# Place launchD plist to call JSS policy to remove admin rights.
#####
echo "<?xml version="1.0" encoding="UTF-8"?> 
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"> 
<plist version="1.0"> 
<dict>
	<key>Disabled</key>
	<true/>
	<key>Label</key> 
	<string>com.company.adminremove</string> 
	<key>ProgramArguments</key> 
	<array> 
		<string>/usr/sbin/jamf</string>
		<string>policy</string>
		<string>-trigger</string>
		<string>adminremove</string>
	</array>
	<key>StartInterval</key>
	<integer>1800</integer> 
</dict> 
</plist>" > /Library/LaunchDaemons/com.company.adminremove.plist
#####
/bin/echo "set permission on file to read only..."
/bin/date
TODAY=`date +"%Y-%m-%d"`
#set the permission on the file just made.
chown root:wheel /Library/LaunchDaemons/com.company.adminremove.plist
chmod 644 /Library/LaunchDaemons/com.company.adminremove.plist
defaults write /Library/LaunchDaemons/com.company.adminremove.plist disabled -bool false

/bin/echo "load removal plist timer..."
/bin/date
TODAY=`date +"%Y-%m-%d"`
# load the removal plist timer. 
launchctl load -w /Library/LaunchDaemons/com.company.adminremove.plist

/bin/echo "build log files in shc..."
/bin/date
TODAY=`date +"%Y-%m-%d"`
# build log files in var/shc
mkdir /var/shc
TIME=`date "+Date:%m-%d-%Y TIME:%H:%M:%S"`
echo $TIME " by " $U >> /var/shc/30minAdmin.txt

echo $U >> /var/shc/userToRemove
/bin/echo "giving user admin..."
/bin/date
TODAY=`date +"%Y-%m-%d"`
# give current logged user admin rights
/usr/sbin/dseditgroup -o edit -a $U -t user admin
exit 0