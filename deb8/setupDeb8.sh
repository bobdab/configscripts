#!/bin/sh

###############################################################################
# My personal setup script for Debia 8 desktop.
# Setup and installation on Debian 8.1 AMD-64 with Cinamon desktop.
#
#
#   wget --no-check-certificate https://raw.githubusercontent.com/bobdab/configscripts/master/deb8/setupDeb8.sh
###############################################################################
# To find programs and files in debian
# apt-cache search PROGRAM_NAME
#
# find which package provides a file:
# dpkg -S /usr/include/sys/types.h

###############################################################################
# Manual setup things:
# 0) disable power settings and lock screen and set a password for user
# or else the computer will sleep during install and lock you out
# 1) install
# manually format hard drive with MBR
# boot vol = 500MB
# root vol (mounted as /) is 1.5GB
# add mount for /usr, /var, /home on separate partitions
#
# 2) create LUKS encryption for VG01 and D using gnome-disks
#    (installed from apt-get install gnome-disk-utility)
#    or run manually (verify the parition nbr)
#      cryptsetup luksFormat /dev/sda11 --iter-time 3000
#      cryptsetup luksFormat /dev/sda12 --iter-time 3000
#
#      cryptsetup open /dev/sda11 luks-VG01
#      cryptsetup open /dev/sda12 luks-D
#      # look for luks-VG01 and luks-D here:
#      ls /dev/mapper
#
#     # format D
#     apt-get install xfsprogs
#     mkfs -t xfs /dev/mapper/luks-D
#     lsblk -f
#
#     # convert VG01 to LVM
#     pvcreate /dev/mapper/luks-VG01 
#     pvscan
#     # now use the gshc menu to create lvm logical volumes
# 3) create the LVM partition for use with gshc virtal machines.
#    Use gnome-disks to create an LVM partition, or manually
#    create the encrypted drive as shown above and then manuall
#    convert luks-VG01  to an LVM physical volume.
#    After unlocking the luks-VG01 volume using 'cryptsetup open...'
#    as shown in #2 above:
#       pvcreate /dev/mapper/luks-VG01
#       vgcreate VG01 /dev/mapper/luks-VG01
#       vgdisplay VG01
#       # create a backup of the LVM structure into /etc/lvm/backup
#       vgcfgbackup
# 4) Recover binary archives of virtual machines.
#    a) Follow guidelines gshc_vmpool_creat.sh to initialize LVM Pool.
#    b) Find an archive copy of /mnt/D/bob300/kvmimg that has images
#       and backup XML files.
#    c) Create an LVM LV of the same size as the archived version.
#       (use gshc menu 1.1).
#    d) Save a copy of the new/temp xml from /etc/libvirt/qemu
#    e) Copy the binary image to the LVM pool using gshc 3.11.
#    f) Put the archives XML in /etc/libvirt/qemu
#       and verify that the UUID (and volume group???) is still correct,
#        then run somethinglike this:
#        virsh define /etc/libvirt/qemu/KVM05edu.xml
# 5) create the windows user id
#       useradd -m windows
#       passwd windows
#
# 5) Nautilus options:
#    check options for the file browser to stop creating thumbnails
#    and stop extracting text from files.
# 6) for AV, add to /etc/apt/sources.list
#    deb ftp://ftp.deb-multimedia.org jessie main non-free
# 7) create a link from /root/.cache/duplicity to a big partition.
###############################################################################
apt-get -y update
apt-get -y upgrade

apt-get -y install cryptsetup vim emacs lynx wget curl vsftpd

# disable the driver for my apple touchpad because
# it disconnects every second and floods my log file
# with shite
rmmod bcm5974
echo "rmmod bcm5974" >> ~/.profile
echo "rmmod bcm5974" >> /home/super/.profile
# ## I do not use recordmydesktop any more because it won't
# ## see my Edirol USB microphone, so I use vokoscreen and kdenlive vid editor,
# ## (note that kdenlive is a giant install)
# ##
# ## gtk-recordmydesktop is a python front-end for the command-line
# ## recordmydesktop -- it is a screen capture program.
# ## pitivi is a movie editor that can edit theora video
# ## from recordmydesktop
# #apt-get -y install gtk-recordmydesktop pitivi

# screen and tmux split a window into panes
apt-get -y install screen tmux ntpdate
apt-get -y install  gnome-disk-utility gparted

apt-get -y install hfsutils
apt-get -y install nfs-common
apt-get -y install tcpdump
apt-get -y install duplicity git
# file system deduplicator
apt-get -y install fslint

# random number entropy generator
apt-get -y install haveged

apt-get -y install xfsprogs

# yum -y install libvirt qemu virt-manager virt-viewer virt-install

apt-get -y install libvirt0 virtinst qemu-kvm virt-manager virt-viewer virtinst
# libosinfo has osinfo-query
apt-get -y install  libosinfo-1.0 libosinfo-bin

# I am using erlang-base-hipe as the base erlang install. It supports native code.
# For some reason the man pages were not included in the
# default erlang install:
apt-get  -y install erlang-base-hipe erlang-manpages erlang-crypto erlang-public-key
apt-get -y install erlang-ssh

# this installed lots of shite libguestfs-tools

# libvirt setup unique to my deb8 install. The other OS
# create the defaul network automatically.
if [ ! -d /etc/libvirt/qemu/networks/default.xml ]; then
	virsh net-autostart default
	# start the network
	virsh net-start default
fi

###############################################################################
# Things that appear to be already installed with the DVD install:
#  python3,
#  gpg 1.4 (no elliptic curve)
#  inkscape, gimp, imagemagick
#  evince, shotwell
#  iceweasel, icedove (instead of firefox)
#  games and GNOME bloatware.
###############################################################################
# # #   one time setup for firmware
# # #
# # #  Find these packages on debian.org under the packages:
# # cd ~/deb8/initialpackages
# # 
# # dpkg -i b43-fwcutter_019-2_amd64.deb
# # # this pointed to a dead site:
# # dpkg -i firmware-b43-installer_019-2_all.deb
# # # this downloaded something:
# # firmware-b43legacy-installer_019-2_all.deb
# # 
# # # i did this, not sure what it did:
# # dpkg -i broadcom-sta-dkms_6.30.223.248-3_all.deb
# # 
# # dpkg -i firmware-atheros_0.43_all.deb
# # dpkg -i firmware-atheros_0.44_all.deb
# # 
# # dpkg -i wireless-tools_30~pre9-8_amd64.deb
###############################################################################
echo "after installing the wifi firmware, reboot"

apt-get -y install r-base-dev libreoffice

apt-get -y install gnucash


apt-get -y install texlive

###############################################################################
# get the infrastructure to verify GPG sigs of repos

apt-get install debian-keyring
#gpg --keyserver pgp.mit.edu --recv-keys 1F41B907
#gpg --armor --export 1F41B907 | apt-key add -

# This one appeared in an error message for one of the media repos for debian 8:
gpg --keyserver pgp.mit.edu --recv-keys 977C43A8BA684223
gpg --armor --export 977C43A8BA684223 | apt-key add -


gpg --keyserver pgp.mit.edu --recv-keys 5C808C2B65558117
gpg --armor --export 5C808C2B65558117| apt-key add -
###############################################################################
apt-get -y install synfig synfigstudio

# for synfig dv output
deb ftp://ftp.deb-multimedia.org jessie main non-free
apt-get -y install ffmpeg2theora libavcodec-extra libavcodec-extra-56
apt-get install libav-tools #for mod_ffmpg
###############################################################################
## Install Google Chrome for testing ON A VM
## For my tiny install on the old computer, I can not afford
## to waste space in the root partition (I didnot point /opt to an
## external mount).  Run FreeBSD VM and then run
##      pkg install chromium

###############################################################################
# duplicity will but gigabytes of crap in /root/.cache/duplicity, which will
# ruin my small root partition, so attempt to avoid that by either usnig
# --archive-dir for duplicity or try a soft link.
if [ ! -d /root/.cache/duplicity ]; then
	echo "WARNING. remember to point /root/.cache/duplicity to another "
	echo "partition so that it does not fill my root partition."
fi



###############################################################################
# jitsi server for jitsi meet (for secure video conferencing)
# Derieved from https://github.com/jitsi/jitsi-meet/blob/master/doc/quick-install.md

CheckJitsi=$(cat /etc/apt/sources.list|grep -i jitsi)
if [ -z "${CheckJitsi}" ]; then
    # The jitsi repo has not yet been configured, so
    # configure it...
    echo 'deb http://download.jitsi.org/nightly/deb unstable/' >> /etc/apt/sources.list
    wget -qO - https://download.jitsi.org/nightly/deb/unstable/archive.key | apt-key add -
fi

# update with the new jitsi repo

apt-get update
if [ $? == 0 ]; then
    apt-get -y install jitsi-meet
else
    echo "Error. the apt-get udate failed after adding the jitsi repo."
    echo "Maybe there is a problem with the GPG key."
    read -p "Press ENTER to continue..."
fi

