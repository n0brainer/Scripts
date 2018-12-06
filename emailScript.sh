#!/bin/bash

jamfUser="" # jamf | PRO admin account
jamfPass="" # jamf | PRO admin password
jamfURL="" # Full jamf | PRO URL including port, please not trailing slash ex. https://jamf.com:8443
emailSubject="" # Email subject 
computerIDFileLocation="/Users/<username>/Desktop/computerids.txt" # Please update <username> with the appropriate username

loop=$(/bin/cat "${computerIDFileLocation}" | awk -F, '{print $1}')

for i in $loop
do
	email=$(/usr/bin/curl -sk -u $jamfUser:$jamfPass -H "Accept: application/xml" $jamfURL/JSSResource/computers/id/$i | xmllint --format - | sed -n '/<location/,/\/location>/p' | grep "<email_address>" | cut -f2 -d">" | cut -f1 -d"<")

	mail -s "$emailSubject" "$email" <<EOF
	# Your message will go here to the end users.  Please delete this line and put in your message with the passcode
	# Delete this line and press return and put your signature here to make this email legit
EOF
done