#!/bin/bash
##############
# This script will make a user a local admin until the removal script runs.
# At the end of the 30 minutes it will then call a jamf policy with a manual trigger.
# Remove the users admin rights and disable the plist file this creates and activites.
# The removal script is MMA_remove.sh
##############
# Taken from https://github.com/andrina/JNUC2013
# Made 180 by Mark and TJ, 20160519

MOUNT_POINT="$1"
# COMPUTER_NAME="$2"
# USER_NAME="$3"

# Core parameters
# Duration in seconds, 1800 being 30mins
ADMIN_DURATION=1800
# See Andrian github for her HTML
#WEBPAGE="https://your.jss.com:8443"

# Construct user and path information
CONSOLE_USER=`who | grep console | awk '{print $1}'`
LAUNCHD_LABEL="com.company.adminremove"
LAUNCHD_PLIST="$MOUNT_POINT/Library/LaunchDaemons/$LAUNCHD_LABEL.plist"
RECEIPT_FILE="$MOUNT_POINT/Library/Application Support/JAMF/Receipts/$LAUNCHD_LABEL.plist.dmg"
LOGFILE="$MOUNT_POINT/var/log/make-me-admin.log"
STATE_FOLDER="$MOUNT_POINT/var/uits"
STATE_FILE="$STATE_FOLDER/userToRemove"


# Do not process these users, as they are sensitive accounts.
declare -a BLACKLIST_USERS
BLACKLIST_USERS=(root admin1 admin2 admin3 admin4)
BLACKLIST_END=2 # NOTE: Zero-indexed

# Filter out attempts to change state for blacklisted users
for i in $(seq 0 $BLACKLIST_END); do
    if [ "${BLACKLIST_USERS[$i]}" == "$CONSOLE_USER" ]; then
        echo "User $CONSOLE_USER is not eligible for becoming admin. Exiting."
        exit 2
    fi
done

if /usr/sbin/dseditgroup -o checkmember -m "$CONSOLE_USER" -t user admin; then
    echo "User $CONSOLE_USER is already an admin. Exiting"
    exit 1
else
    echo "User $CONSOLE_USER is eligible to become admin."
fi


# Open the webpage and allow the user to start filling in details
#sudo -u "$CONSOLE_USER" open "$WEBPAGE"

# Construct Launchd plist in-place
defaults write "$LAUNCHD_PLIST" Label -string "$LAUNCHD_LABEL"
defaults write "$LAUNCHD_PLIST" ProgramArguments -array /usr/local/bin/jamf policy -trigger adminremove
defaults write "$LAUNCHD_PLIST" StartInterval -integer $ADMIN_DURATION
defaults write "$LAUNCHD_PLIST" LaunchOnlyOnce -bool YES
chmod 644 "$LAUNCHD_PLIST"
chown root:wheel "$LAUNCHD_PLIST"

# Ensure that user state is stored
mkdir "$STATE_FOLDER"
TIME=`date "+%Y-%m-%d %H:%M:%S"`
echo "$TIME Adding $CONSOLE_USER to admin group" | /usr/bin/tee -a "$LOGFILE"

echo $CONSOLE_USER >> "$STATE_FILE"

# Create a reciept file to prove that software has been installed
touch "$RECEIPT_FILE"
chown root:admin "$RECEIPT_FILE"

# Load and enable the removal plist timer
launchctl load -w "$LAUNCHD_PLIST"

# Finally, attempt to grant local admin rights.
/usr/sbin/dseditgroup -n . -o edit -a "$CONSOLE_USER" -t user admin

exit $?