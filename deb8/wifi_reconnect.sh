#!/bin/sh

# This will make exactly one attempt to connect to the Internet

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

