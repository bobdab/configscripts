#!/bin/sh

echo "This is for the Mac Pro Only"

#  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   Must be root user
#
ID1="$EUID"
if [ -z "${ID1}" ]; then
    ID1=$(id -u)
fi
if [ ! "${ID1}" = "0" ]; then
    echo "Error.  You must be root to run this."
    exit 12
fi
#  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# mount the drives if need be
/home/super/go.sh

if [ ! -d /media/BDisk/duplicity/MacPro ]; then
	echo "error. the tartget directory is not ready."
	exit 15
fi

echo "super login pw for duplicty of macpro root"
duplicity \
	--exclude-device-files \
	--exclude-other-filesystems \
	--include /usr \
	--include /var \
	--include /lib \
	--include /lib64 \
	--include /opt \
	--include /sbin \
	--include /boot \
    --include /etc \
	--exclude '**' \
	--full-if-older-than 2M \
  	/ file:///media/BDisk/duplicity/MacPro/bk.root

echo "super login pw for duplicty of macpro home archive"
duplicity \
	--exclude-device-files \
	--exclude-other-filesystems \
	--include /home \
	--exclude '**' \
	--full-if-older-than 2M \
  	/home/ file:///media/BDisk/duplicity/MacPro/bk.home
