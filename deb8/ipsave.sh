#!/bin/bash
#
# This is an attempt to allow for safe changes to the firewall
# on a VPS machine or other sensitive machine.
# It will first stage current iptables rules to a test file,
# then prompt the user to modify that file with new rules,
# then it will use iptables-apply to test the modified test rules.
# On success, the modified test rules will be written to the
# official file that is used on reboot (or on device restart).
#
# The logic implies that your source file for iptables rules
# is in the same format of rules that are created by
# iptables-save (or are systematically modififed).
###############################################################################
# To make the rules active at device up/down,
# add the 'pre-up' and 'pre-down' rules to the 
# /etc/network/interfaces file for the associated device.
#
# For my example, my main internet connection is a wifi device,
# so my /etc/network/interfaces example below includes the wpa line
# (for details on the wpa_supplicant file, see the file 
# pi-wifi-setup.sh in my natmsgshargbig github folder):
#
#   allow-hotplug wlan0
#   iface wlan0 inet dhcp
#       pre-up iptables-restore < /etc/network/iptables.rules
#       post-down iptables-save > /etc/network/iptables.rules
#       wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
#
# Then be sure permissions are set:
#     chmod 0600 /etc/network/interfaces
###############################################################################

TEST_RULES_FILE=/etc/network/test.rules
STAGED_GOOD_RULES_FILE=/etc/network/staged_good.rules
OFFICIAL_RULES_FILE=/etc/network/iptables.up.rules
###############################################################################
ID1="$EUID"
if [ -z "${ID1}" ]; then
    ID1=$(id -u)
fi
if [ ! "${ID1}" = "0" ]; then
    echo "ERROR. You must run this as root."
    exit 15
fi
###############################################################################
# Tentatively save rules to a file that will
# not affect the rules upon reboot or upon
# bringing the device up or down.
iptables-save > ${TEST_RULES_FILE}
chmod 755 ${TEST_RULES_FILE}
echo "The current iptables rules have been written to the TEST file:"
echo "${TEST_RULES_FILE}."
echo "Add some rules to the bottom or otherwise modify"
echo "that file, then come back and hit enter here to proceed."
read -p "Press ENTER after you modify the test file..." junk

# set permissions (the x-bit has to be set)
chmod 755 ${TEST_RULES_FILE}

# Read the (modified) rules from the TEST_RULES_FILE and
# save the good (non-error) rules to the STAGED_GOOD
# file:
iptables-apply  -t 60 -w  ${STAGED_GOOD_RULES_FILE} ${TEST_RULES_FILE}
if [ $? = 0 ]; then
    echo "The iptables-apply command succeded."
    echo "I will put the staged good rules"
    echo "in the OFFICIAL file that is used on reboot."
    echo "Copying rules to ${OFFICIAL_RULES_FILE}"
    cp ${STAGED_GOOD_RULES_FILE} ${OFFICIAL_RULES_FILE} 
    if [ ! $? = 0 ]; then
        echo "ERROR.  Failed to copy to ${OFFICIAL_RULES_FILE}."
    fi
    chmod 755 ${OFFICIAL_RULES_FILE}
else
    echo "Error. The iptables-apply command failed."
fi
#       

