#!/bin/bash
##############
# This is the removal script for the MMA_add.sh script.
# It will remove the user from the admin group. Then
# will disable the plist that calls this script.
##############
# Taken from https://github.com/andrina/JNUC2013
# Made 180 by Mark and TJ, 20160519
#
MOUNT_POINT="$1"
# COMPUTER_NAME="$2"
# USER_NAME="$3"

LAUNCHD_LABEL="com.company.adminremove"
LAUNCHD_PLIST="$MOUNT_POINT/Library/LaunchDaemons/$LAUNCHD_LABEL.plist"
RECEIPT_FILE="$MOUNT_POINT/Library/Application Support/JAMF/Receipts/$LAUNCHD_LABEL.plist.dmg"
LOGFILE="$MOUNT_POINT/var/log/make-me-admin.log"
STATE_FOLDER="$MOUNT_POINT/var/uits"
STATE_FILE="$STATE_FOLDER/userToRemove"
CONSOLE_USER=`who | grep console | awk '{print $1}'`

# Do not process these users, as they are sensitive accounts.
declare -a BLACKLIST_USERS
BLACKLIST_USERS=(root admin1 admin2)
BLACKLIST_END=2 # NOTE: Zero-indexed

#LDAP Group, IT department or departments with admin access already; devs, XSAN users
declare -a BLACKLIST_GROUPS
BLACKLIST_GROUPS=(ANYGROUPSTOBLACKLIST)

SHOULD_CLEANUP=1
if [[ -f "$STATE_FILE" ]]; then
    USER_NAME=`cat "$STATE_FILE"`

    if [[ -z "$USER_NAME" ]]; then
        SHOULD_CLEANUP=0
    else
        # Filter out attempts to change state for blacklisted users
        for i in $(seq 0 $BLACKLIST_END); do
            if [ "${BLACKLIST_USERS[$i]}" == "$USER_NAME" ]; then
                echo "User $USER_NAME must remain as an admin. Exiting."
                exit 2
            fi
        done

        # TODO check for group membership before attempting to remove from group
        TIME=`date "+%Y-%m-%d %H:%M:%S"`
        cat "$STATE_FILE" | tr "\n" "\0" | \
            xargs -0 -n1 -I{} echo "$TIME Removing {} from admin group" | tee -a "$LOGFILE"
        cat "$STATE_FILE" | tr "\n" "\0" | \
            xargs -0 -n1 -I{} /usr/sbin/dseditgroup -o edit -d "{}" -t user admin
        SHOULD_CLEANUP=0
    fi
else
    SHOULD_CLEANUP=0
fi

# Successful runs or missing state should trigger cleanup
# Thorough logging used when testing
echo "Disabling Daemon..." | tee -a "$LOGFILE"
/bin/launchctl disable "$LAUNCHD_PLIST"

echo "Cleaning..." | tee -a "$LOGFILE"
/bin/rm -Rf "$STATE_FILE"
echo "Deleted $STATE_FILE" | tee -a "$LOGFILE"
/bin/rm -Rf "$RECEIPT_FILE"
echo "Deleted $RECEIPT_FILE" | tee -a "$LOGFILE"
/bin/rm -Rf "$LAUNCHD_PLIST"
echo "Deleted $LAUNCHD_PLIST" | tee -a "$LOGFILE"
/bin/launchctl remove "$LAUNCHD_PLIST"
echo "$TIME $CONSOLE_USER removed from admin group" | tee -a "$LOGFILE"
/usr/local/jamf/bin/jamf displayMessage -message "You are no longer an administator."
launchctl unload "$LAUNCHD_PLIST"
exit 0