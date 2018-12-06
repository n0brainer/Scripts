#!/bin/bash
####################################################################################################
#
# ABOUT
#
#   Creates a Launch Daemon to run a Recon at next Reboot
#
####################################################################################################
#
# HISTORY
#
#   Version 1.0, 10-Nov-2016, Dan K. Snelson
#
####################################################################################################
# Import client-side functions
source /Library/Scripts/functions.sh
####################################################################################################

# Variables
plistDomain="com.company"                     # Hard-coded domain name (i.e., "com.company")
plistLabel="reconAtReboot"                        # Unique label for this plist (i.e., "reconAtReboot")
plistLabel="$plistDomain.$plistLabel"             # Prepend domain to label

ScriptLog "##############################"
ScriptLog "### Recon at Reboot Create ###"
ScriptLog "##############################"


# Create launchd plist to call a shell script
ScriptLog "* Create the LaunchDaemon ..."

/bin/echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
    <dict>
        <key>Label</key>
        <string>${plistLabel}</string>
        <key>ProgramArguments</key>
        <array>
            <string>sh</string>
            <string>/Library/Scripts/reconAtReboot.sh</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
    </dict>
</plist>" > /Library/LaunchDaemons/$plistLabel.plist



# Set the permission on the file
ScriptLog "* Set LaunchDaemon file permissions ..."

/usr/sbin/chown root:wheel /Library/LaunchDaemons/$plistLabel.plist
/bin/chmod 644 /Library/LaunchDaemons/$plistLabel.plist
/bin/chmod +x /Library/LaunchDaemons/$plistLabel.plist



# Create reboot script
ScriptLog "* Create the script ..."
/bin/echo "#!/bin/sh
####################################################################################################
#
# ABOUT
#
#   Recon at Reboot
#
####################################################################################################
#
# HISTORY
#
#   Version 1.0, 10-Nov-2016, Dan K. Snelson
#
####################################################################################################
# Import logging functions
source /Library/Scripts/functions.sh
####################################################################################################

ScriptLog \"### Recon at Reboot ###\"

ScriptLog \" \" # Blank line for readability

# Sleeping for 300 seconds to give Wi-Fi time to come online.
ScriptLog \"* Pausing Recon at Reboot for five minutes to allow Wi-Fi and DNS to come online ...\"
/bin/sleep 300
ScriptLog \"* Resuming Recon at Reboot ...\"

ScriptLog \"* Updating inventory ...\"
/usr/local/bin/jamf recon

ScriptLog \"* Running FirstBoot ...\"
/usr/local/bin/jamf policy -event 1013fb

# Delete launchd plist
ScriptLog \"* Delete $plistLabel.plist ...\"
/bin/rm -fv /Library/LaunchDaemons/$plistLabel.plist

# Delete script
ScriptLog \"* Delete script ...\"
/bin/rm -fv /Library/Scripts/reconAtReboot.sh

exit 0" > /Library/Scripts/reconAtReboot.sh

# Set the permission on the file
ScriptLog "* Set script file permissions ..."
/usr/sbin/chown root:wheel /Library/Scripts/scripts/reconAtReboot.sh
/bin/chmod 644 /Library/Scripts/reconAtReboot.sh
/bin/chmod +x /Library/Scripts/reconAtReboot.sh

ScriptLog "* LaunchDaemon and Script created."

exit 0