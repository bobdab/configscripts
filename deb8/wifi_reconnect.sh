#!/bin/sh

# This will make exactly one attempt to connect to the Internet
# This is based on the assumption that your wifi is protected
# with WPA.

# IF THERE IS NO SECURITY ON THE WIFI, YOU MIGHT BE ABLE TO CONNECT 
# TO THE WIFI USING SOMETHING LIKE THIS (assuming that your device is called
# wlan0):
#
#    sudo ip link set wlan0 up # allegedly this will bring up the device
#    # sudo ifconfig wlan0 up # redundant command to bring up the device
#    # The next command helps you to find the ESSID if your device name
#    # starts with 'wlan'
#    sudo iwlist scan|grep 'ESSID\|Address\|wlan'  
#    sudo /sbin/iwconfig wlan0 essid 'Unfiltered Access - Over 18'
#    sudo /sbin/iwconfig wlan0 key open
#    sudo /sbin/dhclient wlan0 # get IP from DHCP
#    sudo /sbin/iw wlan0 link # show connection info
#    # You now have to set the /etc/resolv.conf file to point to DNS.
#    # You have a couple options for doing this.
#    # Option 1)  Try looking in this file (or other files in or near 
#    # the same directory):
#    cat   /var/lib/dhcp/dhclient.leases
#    # You can tell from the IP addresses in there and the other information
#    # which lease applies to the current connection.  You can then
#    # put that information into /etc/resolv.conf.
#    # Option 2) TRY LOOKING AT THE DNS AND 'SEARCH DOMAINS'
#    # ON A WORKING COMPUTER THEN PUT THAT INFO INTO /etc/resolv.conf.
#    #
#    # My resolv.conf at the library looks like this:
#       domain LVCCLD.INT
#       search LVCCLD.INT
#       nameserver 204.62.68.15
#       nameserver 204.62.68.16
###############################################################################

# (without running a loop).
# This might be called by a cron job every few minutes
# in an attempt to keep the Internet up without Network Manager
# (which is installed when GNOME desktop is installed).


# See if you are connectd to the Internet
#    (it will return a text status message)
/sbin/iw wlan0 link



#dhclient -v -r; dhclient -x wlan0; ifconfig wlan0 down; ifconfig wlan0 up; systemctl restart networking; wpa_supplicant -B -D wext -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf

##good='n'
##while [ "${good}" = 'n' ]; do
    # echo "I will test the Internet using a ping... This could take 40 seconds..."
    ##ping -c 2 -W 40 yahoo.com
    ##if [ ! "$?" = "0" ]; then

    TEST_WIFI=$(/sbin/iw wlan1 link|grep -i 'not connected')
    if [ -n "${TEST_WIFI}" ]; then
        echo -n "The wifi does not appear to be up.  Attempting to fix it... "
        date

        echo "killing the old dhclient and wpa_supplicant..."
        # release, kill, and double kill the old dhclient
        dhclient -v -r
        dhclient -x wlan0
        killall -w dhclient # double sure that dhclient is dead
        killall -w wpa_supplicant

        ifconfig wlan0 down
        ifconfig wlan0 up

        # not sure which is needed when the official Network Manager app is 
        # not installed
        #systemctl restart network-manager
        systemctl restart networking

        iwlist scan|grep 'ESSID\|Address\|wlan'
        # echo "================= here is some info about wlan0 wifi connection:"
        # the wpa_supplicant command was NOT WORKING, so I
        # added the killall command to see what happens when I reconnect
        echo "Running wpa_supplicant now..."
        wpa_supplicant -B -D wext -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf
        if [ $? = 0 ]; then
            echo "I will run dhclient, and that can take a minute..."
            dhclient -v wlan0
        else
            echo "wpa_supplicant failed."
            exit 44
        fi
    else
        echo -n "The ping test indicates that the Internet is working. "
        date
    fi
    sleep 15
    echo "Double-checking the functionality of the Internet connection with another ping:"
    ping -c 2 -W 40 yahoo.com
    if [ "$?" = "0" ]; then
       good='y'
       echo "The Internet seem to be functioning OK."
    else
        echo "Internet seem broken."
        exit 55
    fi
##done

