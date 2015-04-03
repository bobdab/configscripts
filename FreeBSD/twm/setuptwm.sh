#!/bin/sh

chk_id=$(id -u)

if [ "${chk_id}" = "0" ]; then
	echo "You are root, so I will install the browswer, pdf reader, etc."

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
	pkg install geequie # tiny image viewer
	pkg install mousepad 
	pkg install aspell  # for the spell-checker in the browswer and libreoffice
else
	echo "You are not root, so I will not install the browswer, pdf reader, etc."

fi

read -p "Do you want to install Python 3? (y/n): " yn
yn_python=$(echo "${yn}"|tr "[[:upper:]]" "[[:lower:]]")
echo "You said ${yn_python}"

# 3.3 GB so far
read -p "Do you want to install git? (y/n): " yn
yn_git=$(echo "${yn}"|tr "[[:upper:]]" "[[:lower:]]")
echo "You said ${yn_git}"


src_dir=$(dirname "$0")
cp "${src_dir}/xinitrc" /usr/local/etc/X11/xinit

read -p "enter the user ID to configure: " usr_id
echo "You entered: ${usr_id}"
read -p "Do you want to continue? (y/n): " yn

# .vimrc
yn=$(echo "${yn}"|tr "[[:upper:]]" "[[:lower:]]")
echo "You said ${yn}"
if [ "${yn}" = "y" ]; then
	echo "configuring user.. "
	cp "${src_dir}/.vimrc" "/usr/home/${usr_id}"
fi

## seamonkey/firefox prefs

dir=$(dirname "$0")
src_prefs="${dir}/seamonkey-prefs.js"

prefs=$(find /usr/home/${usr_id}/.mozilla -name 'prefs[.]js')
echo "flist is ${prefs}"

for f in $(echo "${prefs}"); do
	d=$(dirname "${f}")
	echo "copy from ${f} to ${d}"
done


## tweak the 'dot-files'
if [ -f /usr/local/etc/lynx.cfg ]; then
lynx_tst=$(cat /usr/local/etc/lynx.cfg|grep '^FORCE_COOKIE_PROMPT[:]yes'| head -n 1)
if [ -z "${lynx_tst}" ]; then
# I am not indenting because I want my 'here document' to be correct.
read -p "===== I will now append options to /usr/local/etc/lynx.cfg..."
lynx_opts="`cat <<EOF
# Settings added by Bob to reduce all the prompts.
# Do not use lynx for secure communication with 
# these settings.
#
ALERTSECS:0
INFOSECS:0
MESSAGESECS:0
ALWAYS_RESUBMIT_POSTS:TRUE
FORCE_COOKIE_PROMPT:yes
FORCE_SSL_PROMPT:yes
MAX_COOKIES_DOMAIN:0
NO_PAUSE:TRUE
SEND_USERAGENT:OFF
SET_COOKIES:FALSE
USE_MOUSE:FALSE
EOF
`"
echo "${lynx_opts}" >> /usr/local/etc/lynx.cfg

fi
else
	echo "I did not see the /usr/local/etc/lynx.cfg file where I was "
	echo "going to put some options to reduce prompts from lynx browser."
fi

# python install (the prompt was up top)
if [ "${yn_python}" = "y" ]; then
	echo "Installing Python 3..."
	# the python3 install gets two versions, but the extra
	pkg install python3
fi

# Install git (the prompt was up top).
if [ "${yn_git}" = "y" ]; then
	echo "Installing git..."
	pkg install git
fi
