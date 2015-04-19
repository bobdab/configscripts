#!/bin/sh

chk_id=$(id -u)

yn_python='n'
yn_git='n'
yn_seamonkey='n'
yn_R='n'
yn_texlive='n'
yn_duplicity='n'

read -p "Setup type (twm or fluxbox): " dm

if [ "${chk_id}" = "0" ]; then

	if [ -f /usr/local/etc/lynx.cfg ]; then
		lynx_tst=$(cat /usr/local/etc/lynx.cfg|grep '^FORCE_COOKIE_PROMPT[:]yes'| head -n 1)

		if [ -n "${lynx_tst}" ]; then
			# my custom options are not in the lynx config file, 
			# so add them.
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
		
		else
			echo "I did not see the /usr/local/etc/lynx.cfg file where I was "
			echo "going to put some options to reduce prompts from lynx browser."
		fi
	fi

	# --------------------
	read -p "You are root.  Do you want to install the base set of packages? (y/n): " yn

	if [ "${yn}" = "y" ]; then
		# run the installs
		if [ ! -d /usr/ports/security ]; then
			echo "The ports library is not installed.  This is used to install programs "
			echo "from source files (as opposed to binary installs)."
			read -p "Do you want to install the ports library." yn
			yn_ports=$(echo "${yn}"|tr "[[:upper:]]" "[[:lower:]]")
		fi

		read -p "Do you want to install the initial programs using PORTS source code (y/n): " yn
		yn_use_ports=$(echo "${yn}"|tr "[[:upper:]]" "[[:lower:]]")
		if [ "${yn_use_ports}" = 'y' ]; then
			USE_PORTS='y'
		else
			USE_PORTS='n'
		fi


		read -p "Do you want to xorg (graphical desktop)? (y/n): " yn
		yn_xorg=$(echo "${yn}"|tr "[[:upper:]]" "[[:lower:]]")
		echo "You said ${yn_xorg}"

		read -p "Do you want to install natural message command line client? (y/n): " yn
		yn_natmsg=$(echo "${yn}"|tr "[[:upper:]]" "[[:lower:]]")
		echo "You said ${yn_natmsg}"

		read -p "Do you want to install texlive base? (y/n): " yn
		yn_texlive=$(echo "${yn}"|tr "[[:upper:]]" "[[:lower:]]")
		echo "You said ${yn_texlive}"

		read -p "Do you want to install seamonkey web browser? (y/n): " yn
		yn_seamonkey=$(echo "${yn}"|tr "[[:upper:]]" "[[:lower:]]")
		echo "You said ${yn_seamonkey}"

		read -p "Do you want to install Python 3? (y/n): " yn
		yn_python=$(echo "${yn}"|tr "[[:upper:]]" "[[:lower:]]")
		echo "You said ${yn_python}"

		read -p "Do you want to install git? (y/n): " yn
		yn_git=$(echo "${yn}"|tr "[[:upper:]]" "[[:lower:]]")
		echo "You said ${yn_git}"

		read -p "Do you want to install duplicity (also needs python 2.7)? (y/n): " yn
		yn_duplicity=$(echo "${yn}"|tr "[[:upper:]]" "[[:lower:]]")
		echo "You said ${yn_duplicity}"
		

		## These are not needed in PC-BSD:
		#  ## fix /etc/machine-id file:
		#  ## without the machine-id file, seamonkey and other graphics apps won't work
		#  dbus-uuidgen --ensure
		#  pkg install xorg # comes with mousepad

		# you do NOT need to install xfce - twm will work good enough for seamonkey

		if [ "${USE_PORTS}" = 'n' ]; then
			echo "Using binary installs..."
			# log in as root
			pkg upgrade

			if [ "${yn_xorg}" = 'y' ]; then
				echo "y"|pkg install xorg
			fi
			echo "y"|pkg install wget
			echo "y"|pkg install xpdf # a tiny pdf reader (PC-BSD also has mupdf installed)
			echo "y"|pkg install geeqie # tiny image viewer
			echo "y"|pkg install mousepad 
			echo "y"|pkg install aspell 
			if [ "${dm}" = 'twm' ]; then
				echo "y"|pkg install seamonkey
				echo "y"|pkg install vim-lite # or vim.tiny?
			else
				echo "y"|pkg install vim-lite # or vim.tiny?
			fi
		else:
			# use ports/source code to install
			cd /usr/ports/ftp/wget
			make
			make install

			cd /usr/ports/graphics/xpdf
			make
			make install

			cd /usr/ports/graphics/geeqie
			make
			make install

			cd /usr/ports/editors/mousepad
			make
			make install

			cd /usr/ports/textproc/aspell
			make
			make install

			if [ "${dm}" = 'twm' ]; then
				cd /usr/ports/www/seamonkey
				make
				make install

				cd /usr/ports/editors/vim
				make
				make install
			else
				# vim tiny
				cd /usr/ports/editors/vim
				make
				make install
			fi

			# Refresh the package
			#wget https://github.com/bobdab/configscripts/archive/master.tar.gz
			curl -L https://github.com/bobdab/configscripts/archive/master.tar.gz -O
			rm ../../master.tar.gz
			mv master.tar.gz ../..
			#unzip master.tar.gz
			#tar -xf master.tar

			# ----------------------------------
			ntp_tst=$(cat /etc/rc.conf|grep '^ntpd_enable"'| head -n 1)
			if [ -z "${ntp_tst}" ]; then
				echo 'ntpd_enable="YES"' >> /etc/rc.conf
			fi
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
		# I do not set the group ID due to the possibility that
		# it is different from the user, and I want to avoid a 
		# complete failure.
		chown "${usr_id}" "${src_dir}/twm/xinitrc" 
		chown "${usr_id}" "${src_dir}/common/.vimrc" 
		cp "${src_dir}/twm/xinitrc" /usr/local/etc/X11/xinit
		cp "${src_dir}/common/.vimrc" "/usr/home/${usr_id}"
		cp "${src_dir}/common/*" "/usr/home/${usr_id}"
	fi

	if [ "${dm}" = "fluxbox" ]; then
		# src_dir is the directory from which this script runs
		chown "${usr_id}" "${src_dir}/fluxbox/xtermgo.sh" /usr/local/etc/X11/xinit
		chown "${usr_id}" "${src_dir}/fluxbox/.profile" "/usr/home/${usr_id}"
		cp "${src_dir}/fluxbox/xtermgo.sh" /usr/local/etc/X11/xinit
		cp "${src_dir}/fluxbox/.profile" "/usr/home/${usr_id}"
		cp "${src_dir}/common/*" "/usr/home/${usr_id}"
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

if [ "${yn_seamonkey}" = "y" ]; then
	echo "Installing seamonkey..."
	echo "y"|pkg install seamonkey
fi

if [ "${yn_R}" = "y" ]; then
	echo "Installing R"
	echo "y"|pkg install R
fi

if [ "${yn_python}" = "y" ]; then
	echo "Installing Python 3..."
	# the python3 install gets two versions, but the extra
	echo "y"|pkg install python3
fi

if [ "${yn_git}" = "y" ]; then
	echo "Installing git..."
	echo "y"|pkg install git
fi

if [ "${yn_duplicity}" = "y" ]; then
	echo "Installing duplicity ..."
	# the duplicity install gets two versions, but the extra
	echo "y"|pkg install duplicity
fi

if [ "${yn_texlive}" = "y" ]; then
	echo "Installing texlive base..."
	echo "y"|pkg install texlive-base
fi
## tweak the 'dot-files'


# the dbus-uuidgen program is not in the minimal
# Freebsd install, but it should be here after the 
# the programs above have been installed.
# Without the UUID that this program creates,
# graphical programs like web browsers won't work.
dbus-uuidgen --ensure

#


usr_id='super'

dir=$(dirname "$0")
src_prefs="${dir}/common/seamonkey-prefs.js"

prefs=$(find /usr/home/${usr_id}/.mozilla -name 'prefs[.]js')
echo "list of mozilla prefs.js files to be updated is: ${prefs}"

for f in $(echo "${prefs}"); do
	d=$(dirname "${f}")
	echo "Copying mozilla/firefox/seamonkey prefs from ${f} to ${d}"
done
