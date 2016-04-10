#!/bin/sh

echo "At some point, you might be prompted that you do not have the GPG/PGP key"
echo "to confirm the signature on a Debian package.  This can happen if you add"
echo "a custom repository and do not add the key for that repo."
echo "You can fetch the key (typically from the repo source web page) "
echo "and add it to your apt-key list using something like this "
echo "(assuming that the key file that you downloaded is called Release.key):"
echo
echo "   apt-key add - < Release.key"
echo
echo "and check your keys like this:"
echo
echo "   apt-key list"
echo 
echo "You might find debian keys on the web site of the source code, or the "
echo "web site of the custom repo, or here:"
echo "http://ftp-master.debian.org/keys.html"
echo
read -p "Press ENTER to continue..." junk

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
# or else the computer will sleep during install and lock you out.
#    During install, the user id is "user" and the pw is "live" for debian.
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
#       useradd -m windows -s /usr/sbin/nologin
#       passwd windows
#
# 5) Nautilus options:
#    check options for the file browser to stop creating thumbnails
#    and stop extracting text from files.
# 6) for AV, add to /etc/apt/sources.list
#    deb ftp://ftp.deb-multimedia.org jessie main non-free
# 7) create a link from /root/.cache/duplicity to a big partition.
#
# 8) There are two ways to allow root access via SSH to this computer.
#    A) use ssh-copy and RSA public key encryption (considered safer and
#       much easier to automate scripts, but if a hacker gets the remote
#       computer, then the hacker gets access to the remote unless you
#       use ssh agent and a password on the RSA key on the remote computer).
#       1) generate keys on the foreign client:
#          ssh-keygen -t rsa
#       2) copy the newly created id_rsa.pub from the client INTO the
#          $HOME/.ssh/authorized_keys file 
#         (or if you temporarily allows root access, use ssh-copy-id -i ~/.ssh/id_rsa.pub root@192.168.1.11,
#         then disable PermitRootLogin).
#    B) just allow direct ssh login from a remot computer (allows possible attack
#       if hackers guess your password).
#       To allow root login via ssh (not the safest option), edit /etc/ssh/sshd_config
#          #PermitRootLogin without-password
#          PermitRootLogin yes
#  
###############################################################################
apt-get -y update
apt-get -y upgrade

apt-get -y install cryptsetup vim lynx wget curl vsftpd parted

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
apt-get -y install make
apt-get -y install sudo
apt-get -y install screen tmux ntpdate

apt-get -y install hfsutils
apt-get -y install nfs-common
apt-get -y install tcpdump
apt-get -y install duplicity git

# random number entropy generator
apt-get -y install haveged


# I am using erlang-base-hipe as the base erlang install. It supports native code.
# For some reason the man pages were not included in the
# default erlang install:
# WARNING: AFTER INSTALLING ALL THE ERLANG PACKAGES,
#          YOU PROBABLY HAVE TO REBOOT FOR MY SERVER TO RUN.
apt-get  -y install erlang-base-hipe erlang-manpages erlang-crypto erlang-public-key
apt-get -y install erlang-ssh
apt-get -y install erlang-ssl
# erlang-rebar is no longer found:
# %%apt-get -y install erlang-rebar
apt-get -y install rebar
apt-get -y install erlang-eunit
apt-get -y install erlang-edoc
apt-get -y install erlang-mnesia
apt-get -y install erlang-inets


###############################################################################
# duplicity will put gigabytes of crap in /root/.cache/duplicity, which will
# ruin my small root partition, so attempt to avoid that by either using
# --archive-dir for duplicity or try a soft link.
if [ ! -d /root/.cache/duplicity ]; then
	echo "WARNING. remember to point /root/.cache/duplicity to another "
	echo "partition so that it does not fill my root partition."
fi
###############################################################################
yn='n'
read -p "Do you want to install support for xfs file system: " yn
if [ "${yn}" = 'y' ]; then
	apt-get -y install xfsprogs
fi
###############################################################################
yn='n'
read -p "Do you want to install libvirt for virtualization?: " yn
if [ "${yn}" = 'y' ]; then
	# this installed lots of shite libguestfs-tools

	# libvirt setup unique to my deb8 install. The other OS
	# create the default network automatically.
	if [ ! -d /etc/libvirt/qemu/networks/default.xml ]; then
		virsh net-autostart default
		# start the network
		virsh net-start default
	fi
	# yum -y install libvirt qemu virt-manager virt-viewer virt-install

	apt-get -y install libvirt0 virtinst qemu-kvm virt-manager virt-viewer virtinst
	# libosinfo has osinfo-query
	apt-get -y install  libosinfo-1.0 libosinfo-bin
fi
###############################################################################
# file system deduplicator
apt-get -y install fslint
###############################################################################
###############################################################################
###############################################################################
# Things that appear to be already installed with the DVD install (Cinamon desktop)
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

###############################################################################
yn='n'
read -p "Do you want to install nonessential graphical pgms (latex, gnucash, R, libreoffice): " yn
if [ "${yn}" = 'y' ]; then
	apt-get -y install r-base-dev libreoffice

	apt-get -y install gnucash


	apt-get -y install texlive
	apt-get -y install  gnome-disk-utility gparted
fi

###############################################################################
yn='n'
read -p "Do you want to install libimobiledevice-dev to talk to iPhone/iPod Touch: " yn
if [ "${yn}" = 'y' ]; then
	apt-get -y install libimobiledevice-dev
fi

###############################################################################
# Graphical stuff

yn='n'
read -p "Do you want to install synfig (cartoon creator)?: " yn
if [ "${yn}" = 'y' ]; then
	apt-get -y install synfig synfigstudio

	# for synfig dv output
	deb ftp://ftp.deb-multimedia.org jessie main non-free
	apt-get -y install ffmpeg2theora libavcodec-extra libavcodec-extra-56
	apt-get install libav-tools #for mod_ffmpg
fi
###############################################################################
mkdir -p /home/super

cat > /home/super/.screenrc <<EOF
shelltitle "zz%t%"
hardstatus on
hardstatus alwayslastline
hardstatus string "%{.bW}%-w%{.rW}%n %t%{-}%+w %=%{..G} %H %{..Y} %m/%d %C%a "
#hardstatus string "%t%"
EOF

cp /home/super/.screenrc /root
###############################################################################
## Install Google Chrome for testing ON A VM
## For my tiny install on the old computer, I can not afford
## to waste space in the root partition (I didnot point /opt to an
## external mount).  Run FreeBSD VM and then run
##      pkg install chromium

###############################################################################
#### Do not install jitsi meet on a server that has other web servers,
#### because it can cause complications, then the uninstall failed for me.
#### If you install jitse-meet, put it on its own machine.
##
## jitsi ## jitsi server for jitsi meet (for secure video conferencing)
## jitsi ## Derieved from https://github.com/jitsi/jitsi-meet/blob/master/doc/quick-install.md
## jitsi #
## jitsi #CheckJitsi=$(cat /etc/apt/sources.list|grep -i jitsi)
## jitsi #if [ -z "${CheckJitsi}" ]; then
## jitsi #    # The jitsi repo has not yet been configured, so
## jitsi #    # configure it...
## jitsi #    echo 'deb http://download.jitsi.org/nightly/deb unstable/' >> /etc/apt/sources.list
## jitsi #    wget -qO - https://download.jitsi.org/nightly/deb/unstable/archive.key | apt-key add -
## jitsi #fi
## jitsi #
## jitsi ## update with the new jitsi repo
## jitsi #
## jitsi #apt-get update
## jitsi #if [ $? == 0 ]; then
## jitsi #    apt-get -y install jitsi-meet
## jitsi #else
## jitsi #    echo "Error. the apt-get udate failed after adding the jitsi repo."
## jitsi #    echo "Maybe there is a problem with the GPG key."
## jitsi #    read -p "Press ENTER to continue..."
## jitsi #fi
## jitsi #
## jitsi ## the program for jitsi conferencing in jicofo.  it should be running after the install completes,
## jitsi ## and if you look at this, it tells the port and domain name:
## jitsi ## ps -Af|grep jicofo

echo "You might want to add 'contrib' at the end of two of the lines in"
echo "/etc/apt/sources.list to get some extra programs, like nyquist"
