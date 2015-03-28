#!/bin/sh

chk_id=$(id)
if [ "${chk_id}" != "0" ]; then
	echo "Error. You must run this as root"
	exit
fi

# log in as root
pkg upgrade
## fix /etc/machine-id file:
## without the machine-id file, seamonkey and other graphics apps won't work
dbus-uuidgen --ensure
pkg install xorg # 321MB install, and it comes with twm and mousepad (graphical text editor)

# you do NOT need to install xfce - twm will work good enough for seamonkey

pkg install seamonkey
pkg install vim-lite
pkg install xpdf # a tiny pdf reader
pkg install geeqie # tiny image viewer

read -p "Do you want to install Python 3? (y/n): " yn
yn=$(tr "[[:upper:]]" "[[:lower:]]")
echo "You said ${yn}"
if [ "${yn}" = "y" ]; then
	echo "Installing Python 3..."
	# the python3 install gets two versions, but the extra
	pkg install python3
fi

# 3.3 GB so far
read -p "Do you want to install git? (y/n): " yn
yn=$(tr "[[:upper:]]" "[[:lower:]]")
echo "You said ${yn}"
if [ "${yn}" = "y" ]; then
	echo "Installing git..."
	pkg install git
fi

## tweak the 'dot-files'




src_dir=$(dirname "$0")
cp "${src_dir}/xinitrc" /usr/local/etc/X11/xinit

read -p "enter the user ID to configure: " usr_id
echo "You entered: ${usr_id}"
read -p "Do you want to continue? (y/n): " yn
yn=$(tr "[[:upper:]]" "[[:lower:]]")
echo "You said ${yn}"
if [ "${yn}" = "y" ]; then
	echo "configuring user.. "
	cp "${src_dir}/.vimrc" "/usr/home/${usr_id}"
fi
