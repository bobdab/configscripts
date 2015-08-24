#!/bin/sh

# Archive to my server connected on the local wire: 10.0.0.8

# !!!!!!!!!!!!!!!!!
# I need to keep some things archived without duplicity because the 
# standard debian 8 does not have duplicity, and my notes for setup
# were encrypted inside a duplicity archive.
#   quich archive without duplcicyt:
#     * setup scripts (and on github)
#     * extra copy of PGPList
#     * gshc scripts
#     * erlang and python projects:

# RECOVERY TIPS ARE AT THE BOTTOM.
# RECOVERY TIPS ARE AT THE BOTTOM.
# RECOVERY TIPS ARE AT THE BOTTOM.

MY_IF='eth0' # hard-coded, local network interfact name from ifconfig
MY_IP='10.0.0.9' # hard-code IP
SERVER_IP='10.0.0.8'

u=$(id -u)
if [ ! "${u}" = "0" ]; then
	echo "You must be root to run this.  Try:"
	echo "   sudo $0"
	exit
fi

ping -c 1 "${SERVER_IP}"
if [ ! $? = 0 ]; then
    echo "Could not ping the server."
    exit 12
fi
############################################################
#	    Verify that my hard-coded IP is working
#
#chk=$(ifconfig |grep '10[.]0[.]0[.]9')
# this test is slightly vague, but should work:
chk=$(ifconfig |grep "${MY_IP}")
if [ -z "${chk}" ]; then
	echo "${MY_IP} network is not ready, trying now..."
	ifconfig "${MY_IF}" "${MY_IP}" up
	sleep 3
fi

# check again
chk=$(ifconfig |grep "${MY_IP}")
if [ -z "${chk}" ]; then
	echo "10.0.0.9 network is not ready."
	echo "Quitting now."
	exit
fi

############################################################
#
#   1) Archive sherd on the encrypted bob300 drive
#
#
echo "archiving bob300/sherd"
if [ -d /mnt/D/bob300/sherd ]; then

    duplicity  --full-if-older-than 2M  --ssh-askpass \
	/mnt/D/bob300/sherd/ ssh://root@10.0.0.8//arch1/duplicity/bob300/bkdeb8.sherd
    if [ ! $? = 0 ]; then
	echo "Error.  Duplicity archive of sherd failed."
	read -p "Press ENTER to continue."
    fi
else
	echo "Error. /mnt/D/bob300 does not exist"
	read -p "..."
fi

############################################################
#
#   2) Archive /mnt/D/super 
#
#
read -p "Press Enter to procede with archive of /mnt/D/super." junk
SOURCE='/mnt/D/super'
if [ -d "${SOURCE}" ]; then

    ##duplicity  --full-if-older-than 2M  --ssh-askpass \
    ## /mnt/D/super/ ssh://root@10.0.0.8//arch1/duplicity/bob300/bk.super

    duplicity  --full-if-older-than 2M  --ssh-askpass \
	 "${SOURCE}"  ssh://root@10.0.0.8//arch1/duplicity/deb8/bk.super
    if [ ! $? = 0 ]; then
	echo "Error.  Duplicity archive of ${SOURCE} failed."
	read -p "Press ENTER to continue."
    fi
else
	echo "Error. ${SOURCE} does not exist"
	read -p "..."
fi

############################################################
#
#   2) Archive /
#
#
SOURCE='/'
read -p "Press Enter to procede with archive of  ${SOURCE}." junk

# The ssh protocol uses a "backend" (on the client?) that 
# is based in python (paramiko), so rever to shell calls:
## --ssh-backend pexpect
echo "archiving root"
echo "First enter the password for the MAc pro,"
echo "then enter the one for gpg (receipt 366)"
duplicity   --full-if-older-than 2M  \
	--include /usr \
	--include /var \
	--include /home \
	--include /root \
	--include /boot \
	--include /etc --exclude '**'   \
	--ssh-askpass \
	"${SOURCE}" ssh://root@10.0.0.8//arch1/duplicity/deb8/bk.root

if [ ! $? = 0 ]; then
    echo "Error.  Duplicity archive of ${SOURCE}  failed."
    read -p "Press ENTER to continue."
fi

if [ -f /home/super/.bash_history ]; then
	shred -u /home/super/.bash_history
fi

if [ -f /root/.bash_history ]; then
	shred -u /root/.bash_history
fi
################################################################################
#### Recovery info

## connect to hard-coded wire network
# # For the hard-coded ip for wired connectio nto the mac pro:
# ip address show dev eth0
# # To clear an old address on eth0:
# # ip address flush eth0
# ip address add 10.0.0.9/24 dev eth0
#
## list the files in the archive:
# duplicity  list-current-files --ssh-askpass ssh://root@10.0.0.8//arch1/duplicity/MBPF21/bk.root
#
# duplicity  list-current-files --ssh-askpass ssh://root@10.0.0.8//arch1/duplicity/deb8/bk.root

# Restore one file called /etc/libvirt/qemu/S01.xml and put
# it in /home/super/recov (remove the '/' in front of the /etc):
#duplicity restore --file-to-restore etc/libvirt/qemu/S01.xml  \
#	--ssh-askpass \
#	ssh://root@10.0.0.8//arch1/duplicity/deb8/bk.root /home/super/recov
#duplicity restore --file-to-restore etc/libvirt/qemu/ --ssh-askpass  ssh://root@10.0.0.8//arch1/duplicity/deb8/bk.root recov_libvirt_qemu

 
