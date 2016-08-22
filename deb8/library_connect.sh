#!/bin/sh
#
# This will connect to an unprotected wifi
# from the command line.
# I use this at my local library.

WIFI_DEV='wlan0'

ID1="$EUID"
if [ -z "${ID1}" ]; then
    ID1=$(id -u)
fi
if [ ! "${ID1}" = "0" ]; then
    echo "ERROR. You must run this as root."
    exit 15
fi
############################################################
confirm(){
  local tmp_FIN="N"
  local yn=''
  local MY_PROMPT="$1"
  if (test -z "${MY_PROMPT}"); then
    local MY_PROMPT="${MSG_CONTINUE}"
  fi
  while (test "${tmp_FIN}" = "N"); do
    read -p "$MY_PROMPT" yn

    case "${yn}" in
      # Note: there can be many commands inside the "case"
      # block, but the last one in each block must end with
      # two semicolons.
      'y'|'Y')
        tmp_FIN="Y";;
      'n'|'N')
        tmp_FIN="Y";
        return 12;;
    esac
  done;
  return 0
}


############################################################
clear
echo "I am checking WIFI device ${WIFI_DEV}..."
if [ -z "$1" ]; then
    MY_ESSID='Unfiltered Access - Over 18'
    echo "You did not specify an ESSID on the command line."
    echo "Be sure to use quotes around the ESSID name if it"
    echo "contains embedded spaces."
    echo 
    echo "I will use the default ESSID value of:"
    echo 
    echo "${MY_ESSID}"
    echo 
    if confirm "Do you want to use a different wifi name/ESSID? (y/n): "; then
				ip link set ${WIFI_DEV} up 
        ip link set ${WIFI_DEV} up # allegedly this will bring up the device
        # ifconfig ${WIFI_DEV} up # redundant command to bring up the device
        # The next command helps you to find the ESSID if your device name
        # starts with 'wlan'
        iwlist scan|grep 'ESSID\|Address\|wlan'  
        echo "The list above shows ESSIDs." 
        echo "This sript is not designed to set up hidden wifi."
        read -p "Enter a new ESSID (USUALLY A TEXT STRING): " MY_ESSID
        echo ""
        echo "Press ENTER to see a list of your client leases.  look for one"
        echo "that looks like your desired wifi, and press :q to finish..."
        read -p "Press ENTER to continue..." junk
        less /var/lib/dhcp/dhclient.leases
        if confirm "Do you want to use the wifi called ${MY_ESSID}? (y/n): "; then
            echo "You might have to manually update your /etc/resolv.conf file"
            echo "If your name server is not in the expected place, such as"
            echo "198.162.0.1."
            echo
            echo "My /etc/resolv.conf file at the library looks like this."
            echo "   domain LVCCLD.INT"
            echo "   search LVCCLD.INT"
            echo "   nameserver 204.62.68.15"
            echo "   nameserver 204.62.68.16"
            echo "Press ENTER to keep the current resolv.conf file, otherwise:"
            echo "  1) Edit the /etc/resolv.conf file using the information from"
            echo "     the /var/lib/dhcp/dhclient.leases file"
            echo "  3) Press Ctl-c to quit this script."
            echo "  4) Run this script again, from the command line, and"
            echo "     include the ESSID in quotes as an argument."
            read -p "Press ENTER to continue or Ctl-c to quit" junk
				else
						echo "bye."
						exit 37
        fi
    fi
    
else
    MY_ESSID="$1"
    echo "I will use the default ESSID value of:"
    echo 
    echo "${MY_ESSID}"
    echo 
fi

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

echo "killing the old dhclient and wpa_supplicant..." > /dev/stderr
# release, kill, and double kill the old dhclient
dhclient -v -r
dhclient -x ${WIFI_DEV}
killall -w dhclient # double sure that dhclient is dead
killall -w wpa_supplicant

###ifconfig ${WIFI_DEV} down
###ifconfig ${WIFI_DEV} up

ip link set ${WIFI_DEV} down 

# select the ESSID above... i hard-coded one below
/sbin/iwconfig ${WIFI_DEV} essid 'Unfiltered Access - Over 18'
echo "running key open"
/sbin/iwconfig ${WIFI_DEV} key open
echo "running dhclient"
/sbin/dhclient ${WIFI_DEV} # get IP from DHCP
/sbin/iw ${WIFI_DEV} link # show connection info
# You now have to set the /etc/resolv.conf file to point to DNS.
# You have a couple options for doing this.
# Option 1)  Try looking in this file (or other files in or near 
# the same directory):
# You can tell from the IP addresses in there and the other information
# which lease applies to the current connection.  You can then
# put that information into /etc/resolv.conf.
# Option 2) TRY LOOKING AT THE DNS AND 'SEARCH DOMAINS'
# ON A WORKING COMPUTER THEN PUT THAT INFO INTO /etc/resolv.conf.
#

TEST_WIFI=$(/sbin/iw wlan1 link|grep -i 'not connected')
if [ -n "${TEST_WIFI}" ]; then
		echo -n "The wifi does not appear to be up.  Attempting to fix it... "
		date
		
		echo "if you are not connected, try running:"
		echo "  sudo systemctl restart networking"
		echo "  sudo $0"
else
		echo "The network is ready.  If you need to authenticate to"
		echo "get to the Internet, do that now and then come back"
		echo "here and hit ENTER to double-check the connection."
		read -p "Press ENTER to continue..." junk
		ping -c 2 -W 40 yahoo.com
		if [ "$?" = "0" ]; then
		   good='y'
		   echo "The Internet seem to be functioning OK."
		else
		    echo "The Internet connection seems broken."
		    exit 55
		fi
fi
