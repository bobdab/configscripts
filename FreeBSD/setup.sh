#!/bin/sh

chk_id=$(id -u)

yn_python='n'
yn_git='n'

read -p "Setup type (twm or fluxbox): " dm

if [ "${chk_id}" = "0" ]; then
	read -p "You are root.  Do you want to install the base set of packages? (y/n): " yn

	if [ "${yn}" = "y" ]; then
		# run the installs
		
		# log in as root
		pkg upgrade

		## These are not needed in PC-BSD:
		#  ## fix /etc/machine-id file:
		#  ## without the machine-id file, seamonkey and other graphics apps won't work
		#  dbus-uuidgen --ensure
		#  pkg install xorg # comes with mousepad

		# you do NOT need to install xfce - twm will work good enough for seamonkey

		pkg install wget
		pkg install xpdf # a tiny pdf reader (PC-BSD also has mupdf installed)
		pkg install geequie # tiny image viewer
		pkg install mousepad 
		pkg install aspell 
		if [ "${dm}" = 'twm' ]; then
			pkg install seamonkey
			pkg install vim # or vim.tiny?
		else
			pkg install vim-lite # or vim.tiny?
		fi

		# refresh the package
		wget https://github.com/bobdab/configscripts/archive/master.tar.gz
		rm ../../master.tar.gz
		mv master.tar.gz ../..
		#unzip master.tar.gz
		#tar -xf master.tar

		read -p "Do you want to install Python 3? (y/n): " yn

		yn_python=$(echo "${yn}"|tr "[[:upper:]]" "[[:lower:]]")
		echo "You said ${yn_python}"

		read -p "Do you want to install git? (y/n): " yn
		yn_git=$(echo "${yn}"|tr "[[:upper:]]" "[[:lower:]]")
		echo "You said ${yn_git}"

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
	
	fi


fi



################################# configure user
read -p "enter the user ID to configure: " usr_id
echo "You entered: ${usr_id}"
read -p "Do you want to continue? (y/n): " yn
yn=$(echo "${yn}"|tr "[[:upper:]]" "[[:lower:]]")
echo "You said ${yn}"
if [ "${yn}" = "y" ]; then
	echo "configuring user ${usr_id}... "
	src_dir=$(dirname "$0")

	if [ "${dm}" = "twm" ]; then
		# src_dir is the directory from which this script runs
		cp "${src_dir}/twm/xinitrc" /usr/local/etc/X11/xinit
		cp "${src_dir}/common/.vimrc" "/usr/home/${usr_id}"
	fi

	if [ "${dm}" = "fluxbox" ]; then
		# src_dir is the directory from which this script runs
		cp "${src_dir}/fluxbox/xtermgo.sh" /usr/local/etc/X11/xinit
		cp "${src_dir}/fluxbox/.profile" "/usr/home/${usr_id}"
	fi
	# - - -  seamonkey prefs
	dir=$(dirname "$0")
	src_prefs="${dir}/common/H1seamonkeyprefs.js"

	prefs=$(find /usr/home/${usr_id}/.mozilla -name 'prefs[.]js')
	echo "flist is ${prefs}"

	for f in $(echo "${prefs}"); do
		d=$(dirname "${f}")
		echo "copy from ${src_prefs} to ${d}"
		cp "${src_prefs}" "${d}"
	done

	# - - -  
fi


if [ "${yn_python}" = "y" ]; then
	echo "Installing Python 3..."
	# the python3 install gets two versions, but the extra
	pkg install python3
fi

if [ "${yn_git}" = "y" ]; then
	echo "Installing git..."
	pkg install git
fi

## tweak the 'dot-files'


