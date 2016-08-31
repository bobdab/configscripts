#!/bin/sh

# I used this for a Debian 8 basic server that I wanted to
# equip with a mimimal GUI desktop.

apt-get update && apt-get -y upgrade

apt-get install -y gdm3
apt-get install -y xorg
apt-get install -y twm



#### Optionally install GNOME, but it comes with LOTS of baggage:
#
#   ########### gnome core contains the detail packages below,
#   ########### and I removed some of them
#   #####apt-get install -y gnome-core
#   
#   
#   
#   
#   # yelp is a help system
#   # zenity displays graphical boxes from shell scripts
#   
#   
#   apt-get -y install anacron
#      # these two were odd:
#   apt-get -y install lxsession
#   apt-get -y install mate-polkit
#      # 
#   apt-get -y install adwaita-icon-theme
#   apt-get -y install at-spi2-core
#   apt-get -y install baobab
#   apt-get -y install caribou
#   apt-get -y install caribou-antler
#   apt-get -y install dconf-gsettings-backend
#   apt-get -y install dconf-tools
#   
#   
#   apt-get -y install gtk2-engines
#   
#   apt-get -y install gucharmap
#   apt-get -y install gvfs-backends
#   apt-get -y install gvfs-bin
#   apt-get -y install gvfs-fuse
#   apt-get -y install iceweasel
#   apt-get -y install libatk-adaptor
#   apt-get -y install libcanberra-pulse
#   apt-get -y install libcaribou-gtk-module
#   apt-get -y install libcaribou-gtk3-module
#   apt-get -y install libgtk-3-common
#   apt-get -y install libpam-gnome-keyring
#   
#   apt-get -y install gnome
#   
#   apt-get -y install network-manager-gnome
#   
#   apt-get -y install eog
#   apt-get -y install evince
#   apt-get -y install evolution-data-server
#   apt-get -y install fonts-cantarell
#   apt-get -y install gkbd-capplet
#   apt-get -y install glib-networking
#   
#   apt-get -y install gnome-backgrounds
#   apt-get -y install gnome-calculator
#   apt-get -y install gnome-control-center
#   apt-get -y install gnome-disk-utility
#   apt-get -y install gnome-keyring
#   apt-get -y install gnome-menus
#   apt-get -y install gnome-packagekit
#   apt-get -y install gnome-screenshot
#   apt-get -y install gnome-session
#   apt-get -y install gnome-settings-daemon
#   apt-get -y install gnome-shell
#   apt-get -y install gnome-shell-extensions
#   apt-get -y install gnome-system-log
#   apt-get -y install gnome-system-monitor
#   apt-get -y install gnome-terminal
#   apt-get -y install gnome-themes-standard
#   apt-get -y install gsettings-desktop-schemas
#   apt-get -y install mousetweaks
#   apt-get -y install nautilus
#   apt-get -y install policykit-1-gnome
#   	  
#   
#   
#   pulseaudio
#   #sound-theme-freedesktop
#   #	totem
#   #	tracker-gui
#   #	vino
#   #	yelp
#   #zenity
#     
#   # empathy
#   #gnome-bluetooth
#   #gnome-contacts
#   #gnome-dictionary
#   #gnome-font-viewer
#   #gnome-online-accounts
#   #gnome-online-miners
#   #gnome-sushi
#   #gnome-user-guide
#   #gnome-user-share
#   #gstreamer1.0-plugins-base
#   #gstreamer1.0-plugins-good
#   #gstreamer1.0-pulseaudio
#   #metacity
#   
