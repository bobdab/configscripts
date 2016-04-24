#!/bin/bash

# This script allows the user to keep three separate config directories
# for google-chrome (a Bank config and a Default/Regular config, and a TOR config).
#
# I used chrome because, at one time, a particular
# add-in was not working in iceweasel, but now that add-in works in 
# ice-weasel.
#
# I set up the separate TOR settings, but Chrome uses the system proxy settings,
# so I think I wasted my time, but maybe I'll keep the logic for a third config for future use.
#
# This will not configure tor or privoxy for you.  If you install TOR and privoxy,
# then load the TOR mode and modify the settings/advance/network settings to point
# to localhost:8118 to point the proxy to privoxy (and click the buttons to use that
# for all protocals and click the other button to send DNS over that) then
# modify the privoxy settings to say this (without the leading # but with the trailing dot)
#     forward-socks5   /               127.0.0.1:9050   .
#
#
# CONSIDER MODIFYING THIS SO THAT THE BANK VERSION IS COPIED FROM
# A FROZEN SOURCE EACH TIME, AND MAYBE ADD AN OPTION TO
# USE THE CURRENT/LIVE SETTINGS AS THE FROZEN VERSION.
#
if [ $EUID == 0 ]; then
    echo "Do NOT run this as root"
    exit
fi

DSTAMP=$(date +%Y%m%d-%H%M%S)

GDIR="${HOME}/.config/google-chrome"
GBankDIR="${HOME}/.config/googleBank"
GRegDIR="${HOME}/.config/googleRegular"
GTorDIR="${HOME}/.config/googleTor"

GBankTAG="Default/bank.tag"
GRegTAG="Default/default.tag"
GTorTAG="Default/tor.tag"
# This will prompt to start either "default" or "bank" or "TOR"
# mode for google-chrome, then set the profile
# accordingly and start chrome in the background

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

echo "Select a number:"
echo " 1) chrome in default mode."
echo " 2) chrome in bank mode."
echo " 3) chrome in TOR mode."
read -p ": " choice

###############################################################################
# Initialize if need be
if [ ! -d "${GBankDIR}" ]; then
    if [ ! -d "${GRegDIR}" ]; then
        clear
        echo "WARNING: Neither the bank nor regular source directories exist."
        if confirm "Do you want to initialize the directories for bank, regular, and TOR?"; then
            # Bank
            rsync -a --delete "${GDIR}/" "${GBankDIR}/" 
            if [ ! $? = 0 ]; then
                echo "Error initializing $GBankDIR"
                exit 12
            fi
            rm "${GBankDIR}/${GRegTAG}"
            rm "${GBankDIR}/${GTorTAG}"
            touch "${GBankDIR}/${GBankTAG}"

            # Regular
            rsync -a --delete  "${GDIR}/" "${GRegDIR}/"
            if [ ! $? = 0 ]; then
                echo "Error initializing $GRegDIR"
                exit 14
            fi
            touch "${GRegDIR}/${GRegTAG}"
            rm "${GRegDIR}/${GBankTAG}"
            rm "${GRegDIR}/${GTorTAG}"


            # TOR
            rsync -a --delete "${GDIR}/" "${GTorDIR}/" 
            if [ ! $? = 0 ]; then
                echo "Error initializing $GTorDIR"
                exit 12
            fi
            rm "${GTorDIR}/${GRegTAG}"
            rm "${GTorDIR}/${GBankTAG}"
            touch "${GTorDIR}/${GTorTAG}"

            # intialize the existing config to be "regular" mode
            touch "${GDIR}/${GRegTAG}"
        fi
    fi
else
    if [ ! -d "${GBankDIR}" ]; then
        echo "It looks like the source directory for bank mode exists,"
        echo "but the source for the regular directory does not."
        echo "Something bad happened.  You might want to archive the"
        echo "config directory and then delete the $GBankDIR and"
        echo "$GRegDIR directories and run this script to reinitialize."
        exit 15
    fi
fi

###############################################################################
###############################################################################


if [ "${choice}" = "1" ]; then
    if [ -f "${GDIR}/Default/default.tag" ]; then
        echo "Already in default mode."
    else
        ##if [ -f "${GDIR}/Default/bank.tag" ]; then
        if [ -f "${GDIR}/${GBankTAG}" ]; then
            # save the current profile to  the bank profile
            echo "Saving current profile to the Bank profile before restoring the Regular profile"
            rsync -a --delete "${GDIR}/" "${GBankDIR}/"

            # put the regular profile into place
            echo "Restoring the Regular profile"
            # save the current profile to  the bank profile
            rsync -a --delete "${GRegDIR}/" "${GDIR}/"
        ##elif [ -f "${GDIR}/Default/tor.tag" ]; then
        elif [ -f "${GDIR}/${GTorTAG}" ]; then
            # save the current profile to  the TOR profile
            echo "Saving current profile to the TOR profile before restoring the regular profile"
            rsync -a --delete "${GDIR}/" "${GTorDIR}/"

            echo "Restoring the Regular profile"
            rsync -a --delete "${GRegDIR}/" "${GDIR}/"
        else
            echo "test: ${GDIR}/${GTorTAG}"
            echo "Error. I found neither the Regular nor Bank tags"
            exit
        fi
    fi
    echo "starting chrome"
    echo "Note: if the script hangs here, it could be that the Internet"
    echo "is down, or maybe you need to restart openvpn to recover"
    echo "from a recent Internet interruption.  The command on Debian 8 is:"
    echo "   sudo systemctl restart openvpn"
    /usr/bin/google-chrome

elif [ "${choice}" = "2" ]; then
    ###if [ -f "${GDIR}/Default/bank.tag" ]; then
    if [ -f "${GDIR}/${GBankTAG}" ]; then
        echo "Already in Bank mode"
    else
        ##if [ -f "${GDIR}/Default/default.tag" ]; then
        if [ -f "${GDIR}/${GRegTAG}" ]; then
            # save the current profile to  the REgular profile
            echo "Saving current profile to the Regular profile before restoring the Bank profile"
            rsync -a --delete "${GDIR}/" "${GRegDIR}/"

            echo "Restoring the Bank profile"
            rsync -a --delete "${GBankDIR}/" "${GDIR}/"
        elif [ -f "${GDIR}/${GTorTAG}" ]; then
            # save the current profile to  the TOR profile
            echo "Saving current profile to the TOR profile before restoring the Bank profile"
            rsync -a --delete "${GDIR}/" "${GTorDIR}/"

            echo "Restoring the Bank profile"
            rsync -a --delete "${GBankDIR}/" "${GDIR}/"
        else
            echo "Error. I found neither the Regular nor Bank nor TOR tags"
            exit
        fi
    fi
    echo "starting chrome"
    /usr/bin/google-chrome

elif [ "${choice}" = "3" ]; then
    if [ -f "${GDIR}/${GTorTAG}" ]; then
        echo "Already in TOR mode"
    else
        if [ -f "${GDIR}/${GRegTAG}" ]; then
            # save the current profile to  the REgular profile
            echo "Saving current profile to the Regular profile before restoring the TOR profile"
            rsync -a --delete "${GDIR}/" "${GRegDIR}/"

            echo "Restoring the TOR profile"

            rsync -a --delete "${GTorDIR}/" "${GDIR}/"
        elif [ -f "${GDIR}/${GBankTAG}" ]; then
            # save the current profile to  the bank profile
            echo "Saving current profile to the Bank profile before restoring the Tor profile"
            rsync -a --delete "${GDIR}/" "${GBankDIR}/"

            echo "Restoring the Tor profile"

            rsync -a --delete "${GTorDIR}/" "${GDIR}/"
        else
            echo "Error. I found neither the Regular, Bank, nor TOR tags"
            exit
        fi
    fi
    echo "starting chrome"
    /usr/bin/google-chrome

else 
    echo "Bad choice.  Bye."
fi
