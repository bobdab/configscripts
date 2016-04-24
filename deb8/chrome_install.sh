#!/bin/bash


# This will install chrome from the Google repository.
# For info on the repository, see https://www.google.com/linuxrepositories/
#
if [ ! $EUID = 0 ]; then
    echo "You must run this as root."
	  echo "bye."
    exit
fi


# check sources
CHK=$(cat /etc/apt/sources.list|grep -v '^#'|grep google)

if [ -z "${CHK}" ]; then
	# Google software repository
	echo "appending the Google repository to /etc/apt/sources.list"
	echo    "#"  >> /etc/apt/sources.list
	echo    "# Google repo for chrome"  >> /etc/apt/sources.list
	###echo "deb http://dl.google.com/linux/deb/ stable non-free main" >> /etc/apt/sources.list
	echo    "deb http://dl.google.com/linux/chrome/deb/ stable main"  >> /etc/apt/sources.list

fi


#wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
if [ ! $? = 0 ]; then
	echo "wget failed."
	exit 14
fi


apt-get update
if [ ! $? = 0 ]; then
	echo "apt update failed."
	exit 15
fi

# dependencies that chrome does not install:
apt-get -y install libpango1 libappindicator1

# if you daring, use the beta:
#sudo apt-get install google-chrome-beta

sudo apt-get install google-chrome-stable
if [ ! $? = 0 ]; then
	echo "apt-get install failed"
	exit 15
fi

# this might grab unmet dependencies
apt-get -f install
