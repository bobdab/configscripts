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

PRIV_CONFIG_FILE=/etc/privoxy/config
###############################################################################
# My personal setup script for Debia 8 desktop.
# Setup and installation on Debian 8.1 AMD-64 with Cinamon desktop.
#
#
#   wget --no-check-certificate \
#https://raw.githubusercontent.com/bobdab/configscripts/master/deb8/setupDeb8.sh
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
###############################################################################

apt-get -y install bash

SRC_CHECK=$(cat /etc/apt/sources.list|grep -v '^[#]' |grep -i cdrom)
if [ -n "${SRC_CHECK}" ]; then
  clear
  echo "==========================================================="
  echo "Warning.  You still refer to the install CDROM in your"
  echo "/etc/apt/source.list file."
  echo "You probably want to comment that out by inserting a # character"
  echo "at the start of the line that refers to the cdrom."
  echo
fi


INST_XFS='n'
if confirm "Do you want to install support for xfs file system: "; then
  INST_XFS='y'
fi

INST_LIBVIRT='n'
if confirm "Do you want to install libvirt for virtualization?: "; then
  INST_LIBVIRT='y'
fi

INST_OPTIONAL_GUI_APPS='n'
MY_PROMPT="Do you want to install nonessential graphical pgms (latex, gnucash, R, libreoffice): "
if confirm "${MY_PROMPT}"; then
  INST_OPTIONAL_GUI_APPS='y'
fi



LIB_MOBILE_DEV='n'
MY_PROMPT="Do you want to install libimobiledevice-dev to talk to iPhone/iPod Touch: "
if confirm "${MY_PROMPT}"; then
  LIB_MOBILE_DEV='y'
fi


INST_SYNFIG='n'
if confirm "Do you want to install synfig (cartoon creator)?: "; then
  INST_SYNFIG='y'
fi


INST_TOR='n'
if confirm "Do you want to install tor and privoxy?: "; then
  INST_TOR='y'
fi

INST_LOC_NET='n'
if confirm "Do you want to make the local network point to a static address of 10.0.0.5 in /etc/network/interfaces?: "; then
  INST_LOC_NET='y'
fi

NM_INST='n'
if confirm "Do you want to install Network Manager to simplify wifi connections (do this only if you have GNOME, in which case it should be installed automatically)?: "; then
  NM_INST='y'
fi


###############################################################################
apt-get -y update
apt-get -y upgrade

apt-get -y install cryptsetup vim lynx wget curl vsftpd parted

# disable the driver for my apple touchpad because
# it disconnects every second and floods my log file
# with shite
rmmod bcm5974
echo "# Remove the Macbook Pro mousepad functinality"
echo "# because it constantly hangs and tries to reset itself."
echo "Also add this to /etc/rc.local"
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
if [ "${INST_XFS}" = 'y' ]; then
  apt-get -y install xfsprogs
fi

###############################################################################
if [ "${INST_LIBVIRT}" = 'y' ]; then
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

cat > /etc/apt/sources.list <<EOF
# dvd for libdvdcss2:
# Add videolan.org to your sources.list file, then run:
#
#   wget -O - http://download.videolan.org/pub/debian/videolan-apt.asc|sudo apt-key add -
#   sudo apt-get update
#   sudo apt-get install libdvdcss2
#   reboot now
#
deb http://download.videolan.org/pub/debian/stable/ /
EOF

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
TESTBELL=$(grep '^set bell[-]style' /etc/inputrc)
if [ -n "${TESTBELL}" ]; then
    # if there is no setting for the bell that sounds
    # from the command line, set it to 'visible
    echo "set bell-style visible" >> /etc/inputrc
    
fi
###############################################################################

if [ "${INST_OPTIONAL_GUI_APPS}" = 'y' ]; then
	apt-get -y install r-base-dev libreoffice

	apt-get -y install gnucash


    # dvd/cd burner:
    apt-get -y install xfburn

	apt-get -y install texlive
	apt-get -y install  gnome-disk-utility gparted
fi

###############################################################################
if [ "${LIB_MOBILE_DEV}" = 'y' ]; then
	apt-get -y install libimobiledevice-dev
fi


###############################################################################
yn='n'
read -p "Do you want to install libimobiledevice-dev to talk to iPhone/iPod Touch: " yn
if [ "${yn}" = 'y' ]; then
    echo "This appears to work automatically when I install GNOME desktop and then"
    echo "run the installs here.   The result is that the iPod appears as a hard drive."
    echo "This setup does not allow import/export to iTunes, but other programs might"
    echo "do that."
    echo "I do not need to do any of the manual setup"
    echo "steps that are mentioned here: work but see https://wiki.debian.org/iPhone."
    echo "GNOME will automount newly attached devices, but other desktops, like"
    echo "Cinamon or XFCE will not."
    echo "the iPhone will be automounted to a funny name, like:"
    ehco "/run/user/1000/gvfs/afc\:host\=123456abc61384681236481326ffffdddee11111/"
	apt-get -y install libimobiledevice-dev libimobiledevice-utils gvfs-backends gvfs-bin gvfs-fuse
fi

###############################################################################
# Graphical stuff

if [ "${INST_SYNFIG}" = 'y' ]; then
	apt-get -y install synfig synfigstudio

	# for synfig dv output
	deb ftp://ftp.deb-multimedia.org jessie main non-free
	apt-get -y install ffmpeg2theora libavcodec-extra libavcodec-extra-56
	apt-get install libav-tools #for mod_ffmpg
fi


if [ "${INST_TOR}" = 'y' ]; then
    apt-get -y install tor privoxy
    if [ -f "${PRIV_CONFIG_FILE}" ]; then
        PTEST=$(cat ${PRIV_CONFIG_FILE} | grep '^forward[-]socks5 ')
				echo "test of ptest ${PTEST}"
        if [ -z "${PTEST}" ]; then
            # append the socks5 setting to the privoxy config file
            echo "Note: adding socks5 setting to privoxy config file..."
            echo "forward-socks5   /               127.0.0.1:9050   ." >> "${PRIV_CONFIG_FILE}"
        else
            echo "Note: privoxy already has a socks5 setting"
        fi
    else
        echo "OOPS. I did not find the privoxy config file in the correct place."
        echo "quitting now"
        exit 9834
    fi
    
fi

###############################################################################
if [ "${INST_LOC_NET}" = 'y' ]; then


TST_NET=$(grep '10[.]0[.]0[.]' /etc/network/interfaces)

if [ -z "${TST_NET}"]; then
# I don't see my hack in the interfaces file, try adding a setting
cat > /etc/network/interfaces <<EOF
# bob added this to bring up local network automaticaly
auto eth0
iface eth0 inet static
   address 10.0.0.5
   netmask 255.255.255.
EOF
fi

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
#### If you install jitsi-meet, put it on its own machine.
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
###############################################################################
#    add a script that can be used to automate reconnection of a downed 
#    internet connection


if [ -z "${NM_INST}"]; then
echo "Installing Network Manager"

# Note that without GNOME, it might be better to install wicd instead of NetworkManager.
#
# Note that some network interfaces are handled by ifupdown
# and you would have to make a change to let network manager handle them
# Here are some notes during install
#   The following network interfaces were found in /etc/network/interfaces
#   which means they are currently configured by ifupdown:
#   - eth0
#   - wlan0
#   - wlan1
#  If you want to manage those interfaces with NetworkManager instead
#  remove their configuration from /etc/network/interfaces.


apt-get -y install network-manager

cat > /usr/bin/wifi_reconnect.sh <<EOF
#!/bin/sh

# This will make exactly one attempt to connect to the Internet
# (without running a loop).
# This might be called by a cron job every few minutes
# in an attempt to keep the Internet up without Network Manager
# (which is installed when GNOME desktop is installed).


# See if you are connectd to the Internet
#    (it will return a text status message)
/sbin/iw wlan0 link

##good='n'
##while [ "${good}" = 'n' ]; do
    # echo "I will test the Internet using a ping... This could take 40 seconds..."
    ping -c 2 -W 40 yahoo.com
    if [ ! "$?" = "0" ]; then
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

EOF

chmod 555 /usr/bin/wifi_reconnect.sh
fi
###############################################################################
