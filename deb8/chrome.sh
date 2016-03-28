#!/bin/bash

if [ $EUID == 0 ]; then
    echo "Do NOT run this as root"
    exit
fi

DSTAMP=$(date +%Y%m%d-%H%M%S)

GDIR="${HOME}/.config/google-chrome"
GBankDIR="${HOME}/.config/googleBank"
GRegDIR="${HOME}/.config/googleRegular"
# This will prompt to start either "default" or "bank"
# mode for google-chrome, then set the profile
# accordingly and start chrome in the background

# The OLD version was set up to copy just 
# .config/google-chrome/Default, but now I copy the whole
# google directory.
#   cd ~/.config/
#   cp -R google-chrome/ googleBank
#   cp -R google-chrome/ googleRegular
#   touch googleBank/bank.tag
#   touch googleRegular/default.tag

#### first archive the existing profile
### tar -czf "${HOME}/GoogleChromeProfileBack${DSTAMP}.tgz "${GDIR}/"

echo "Select a number:"
echo " 1) chrome in default mode."
echo " 2) chrome in bank mode."
read -p ": " choice

if [ "${choice}" = "1" ]; then
    if [ -f "${GDIR}/Default/default.tag" ]; then
        echo "Already in default mode."
    else
        if [ -f "${GDIR}/Default/bank.tag" ]; then
            # save the current profile to  the bank profile
            echo "Saving current profile to the Bank profile before restoring the Regular profile"
            rsync -a --delete "${GDIR}/" "${GBankDIR}/"

            # put the regular profile into place
            echo "Restoring the Regular profile"
            # save the current profile to  the bank profile
            rsync -a --delete "${GRegDIR}/" "${GDIR}/"
        else
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
    if [ -f "${GDIR}/Default/bank.tag" ]; then
        echo "Already in Bank mode"
    else
        if [ -f "${GDIR}/Default/default.tag" ]; then
            # save the current profile to  the REgular profile
            echo "Saving current profile to the Regular profile before restoring the Bank profile"
            rsync -a --delete "${GDIR}/" "${GRegDIR}/"

            echo "Restoring the Bank profile"
            rsync -a --delete "${GBankDIR}/" "${GDIR}/"
        else
            echo "Error. I found neither the Regular nor Bank tags"
            exit
        fi
    fi
    echo "starting chrome"
    /usr/bin/google-chrome

else 
    echo "Bad choice.  Bye."
fi
