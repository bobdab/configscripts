#!/bin/sh

echo "At some point, you might be prompted that you do not have the GPG/PGP key"
echo "to confirm the signature on a debian package.  The path of the key might"
echo "be given, then you can fetch it and add it to your GPG like this:"
echo "   apt-key add - < Release.key"

# notes and scripts documenting my owncloud server setup
# on debian 8.1 with Cinnamon desktop.
# The Cinamon desktop seemed to have problems on my
# other computer, so I might change to GNOME if 
# a graphical desktop is needed for owncloud server.

# testing ports:
# netstat -i
# lsof -i
# lsof -i tcp:9000 #for php
#
DSTAMP=$(date +%Y%m%d-%H%M%S)

IFACE=eth0
CERT_KEY_DIR='/etc/ssl/nginx/'
POSTGRE_VER='9.4'
OWNCLOUD_MNT='/media/owncloud/OC'
WWW_ROOT="${OWNCLOUD_MNT}/www"
WWW_LOG_DIR="${OWNCLOUD_MNT}/log"
# For debian, the OwnCloud software is installed under
# the www-data user id, and nginx uses this by default too.
# These three names were from 8.1 server guide p. 23, but I made them UCASE.
OCPATH="${WWW_ROOT}/owncloud"
HTUSER='www-data'
HTGROUP='www-data'
LOG_FNAME=~/owncloudsetup${DSTAMP}.log

# PostgreSQL setup
PGUSER_HOME='/media/owncloud/OC/pgsql'
PGSQL_BIN_DIR="/usr/lib/postgresql/${POSTGRE_VER}/bin"
PGSQL_DATA="${PGUSER_HOME}/${POSTGRE_VER}/main"
PGSQL_CONF='/etc/postgresql/${POSTGRE_VER}/main/postgresql.conf'
###############################################################################
#  Installation procedures.
#
# First run this entire script, then come back and follow the instructions here.
#
# I manually downloaded the owncloud server tarball and put it in th www/owncloud direcgtory
# but because debian 8.1 had an old owncloud version.  I might have been able to 
# point to owncloud's repo like this:
#   cd /home/super
#   echo 'deb http://download.opensuse.org/repositories/isv:/ownCloud:/desktop/Debian_8.0/ /' >> /etc/apt/sources.list.d/owncloud-client.list 
#   wget http://download.opensuse.org/repositories/isv:ownCloud:desktop/Debian_8.0/Release.key
#   apt-key add - < Release.key
#   apt-get update
#   apt-get install owncloud
#   apt-get install owncloud-client
# I did the client only using that technique
#
# The script at the bottom of this file installs btrfs, and the note here
# describe some manual procedures to run.
#
# To make a two-disk RAID1 (redundant disk array) using the ENTIRE
# disk:
#   # first verify that you know which disk is which
#   # you can also use the gnome-disks command (installed via the 
#   # gnome-disk-utility package):
#   lsblk -f
#   parted /dev/sdc print
#   parted /dev/sdd print
#
#   # Encrypt two entire disks with dm-crypt/LUKS/cryptsetup:
#   cryptsetup luksFormat /dev/sdc --iter-time 3000
#   cryptsetup luksFormat /dev/sdd --iter-time 3000
#
#   cryptsetup open /dev/sdc luks-OCC
#   cryptsetup open /dev/sdd luks-OCD
#   # look for luks-OCC and luks-OCD here:
#   ls /dev/mapper
#
#   # Use the encrypted devices in /dev/mapper to install
#   # a btrfs file system.
#   # You can get help from this command: man mkfs.btrfs
#   #    -m is the method for storing file metadata.
#   #    -d is the method for storing file the main files.
#   #    -L is the new name for the btrfs disk.
#   mkfs.btrfs -m raid1 -d raid1 -L OCDisk /dev/mapper/luks-OCC /dev/mapper/luks-OCD
#
#   # Now you can run run this script again to create the mount points,
#   # and the mount command to mount any single device
#   # that was used in the RAID, and btrfs will recognize the whole RAID:
#
#   # Add a line to /etc/fstab.  Use the -L label from the mkfs.btrfs  command above.
#   LABEL=OCDisk      /media/owncloud/OC     btrfs   defaults,noatime,subvolid=0   0 0
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   # mount the main btrfs filesystem, then we will add subvolumes. 
#   mkdir -p /media/owncloud/OC
#   mount -t btrfs -o autodefrag,compress=lzo,noatime,recovery /dev/mapper/luks-OCD /media/owncloud/OC
#
#   # check it
#   btrfs filesytem show
#
#   # add subvolumes after you mount the first thing, and
#   # do not write the the root mount.
#   btrfs subvolume create /media/owncloud/OC/www
#   btrfs subvolume create /media/owncloud/OC/log
#   btrfs subvolume create /media/owncloud/OC/pgsql
#   # This one is for me
#   btrfs subvolume create /media/owncloud/OC/arch1
#
#   # Get info on the subvolumes
#   btrfs subvolume show /media/owncloud/OC/www/
#   btrfs subvolume show /media/owncloud/OC/pgsql/
#
#   # You can use the subvolumes without a mount command:
#   ls / > /media/owncloud/OC/www
#   btrfs filesystem df /media/owncloud/OC/www/
#
#   # The wiki says that mount options apply to the root btrfs partition
#   # and not to the subvolumes, so compression is either on or off
#   # for the file system.
#
#   # OPTIONALLY add the remaining entries to /etc/fstab if you want to automount
#   # I do not do this.
#   LABEL=OCDisk      /media/owncloud/OC/www btrfs   defaults,autodefrag,compress,recovery,subvolid=1   0 0
#   LABEL=OCDisk      /media/owncloud/OC/log btrfs   defaults,autodefrag,compress,recovery,subvolid=2   0 0
#   LABEL=OCDisk      /media/owncloud/OC/pgsql btrfs   defaults,subvolid=3   0 0
#
#
#   # I avoid touching fstab and run my own mount scripts:
#   mount -t btrfs -o autodefrag,compress=lzo,noatime,recovery /dev/mapper/luks-OCD
#   # I don't have to mount the subvolumes.
# 
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# An extra RAID1 on ONE DISK
#   
#   cryptsetup luksFormat /dev/sdb1 --iter-time 3000
#   cryptsetup luksFormat /dev/sdb2 --iter-time 3000
#
#   cryptsetup open /dev/sdb1 luks-BA
#   cryptsetup open /dev/sdb2 luks-BB
#   mkfs.btrfs -m raid1 -d raid1 -L BDisk /dev/mapper/luks-BA /dev/mapper/luks-BB
#   mkdir -p /media/BDisk
#   mount -t btrfs -o autodefrag,compress=lzo,noatime,recovery /dev/mapper/luks-BB /media/BDisk
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Tweak nginx settings in /etc/nginx/nginx.conf
#   Edit vim /etc/nginx/sites-available/default to point the 'location' to
#   /media/owncloud/OC/www
# Tweak PHP settings
#  Nginx will have a setting to point to either 127.0.0.1:9000 for PHP fastCGI
#  or maybe to a UNIX socket.  Check /etc/php5/cli/php.ini.
#  Also check: lsof -i
##
## Note: I did not have to reinstall any of these when I removed version 7 and installed
## version 8.1 from source:..
##
## # when I removed version 7.0 from apt-get in Debian 8.1, it said this:
## The following packages were automatically installed and are no longer required:
##   fonts-font-awesome fonts-lohit-deva fonts-sil-gentium fonts-sil-gentium-basic fonts-wqy-microhei libapache2-mod-php5
##   libjs-chosen libjs-dojo-core libjs-dojo-dijit libjs-dojo-dojox libjs-jcrop libjs-jquery-minicolors
##   libjs-jquery-mousewheel libjs-jquery-timepicker libjs-jquery-ui libjs-mediaelement libjs-pdf libonig2
##   libphp-phpmailer libqdbm14 pdf.js-common php-assetic php-aws-sdk php-crypt-blowfish php-doctrine-annotations
##   php-doctrine-cache php-doctrine-collections php-doctrine-common php-doctrine-dbal php-doctrine-inflector
##   php-doctrine-lexer php-dropbox php-getid3 php-google-api-php-client php-guzzle php-opencloud php-opencloud-doc
##   php-patchwork-utf8 php-pear php-pimple php-sabre-dav php-sabre-vobject php-seclib php-symfony-class-loader
##   php-symfony-classloader php-symfony-console php-symfony-event-dispatcher php-symfony-eventdispatcher
##   php-symfony-process php-symfony-routing php5 php5-cli php5-ldap php5-oauth php5-readline vorbis-tools zendframework
##
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## PHP setup
##  1) be sure that /usr/local/etc/php-fpm.conf sets the user id
#      user = www-data
#       group = www-data
#   2) start the service:
#      /usr/local/bin/php-fpm
#   3) edit /media/owncloud/OC/www/owncloud/config/config.php to add alternate
#      domains -- like the IP of the server vs the DNS name. Add to the
#      trusted_domains list as index 1.
#   4)  This setting worked for me and the prot 9000 did not: 
#      file name is: /etc/nginx/sites-available/default
#        	upstream php-handler {
#        	# Bob says to choose the port that PHP monitors for fastCGI, which
#        	# might be 127.0.0.1:9000 for tcp ro maybe a unix socket.
#        	#server 127.0.0.1:9000;
#        	server unix:/var/run/php5-fpm.sock;
#        }

#   5) when you visit https://localhost/owncloud,
#      in a browswer, you should see the login page, assuming that you
#      set up the database and created ssl keys and did everything above and below.
#   6) from the php-fpm man page:
#         Most options are set in the configuration file. The
#         configuration file is /etc/php-fpm.conf. By default, php-fpm
#         will respond to CGI requests listening on localhost http
#         port 9000. Therefore php-fpm expects your webserver to
#         forward all requests for '.php' files to port 9000 and you
#         should edit your webserver configuration file appropriately.
#   7) edit www/owncloud/private/mimetypes.list.php
#      to add mime types for erl, hrl, org
#      Then run this command to update:
#       cd /OC/www/owncloud
#       sudo -u www-data php occ maintenance:repair
#   8) there is a max upload setting in /etc/php5/php.ini, but I don't think
#      it affects owncloud, but check the three .htaccess files, including /OC/www/owncloud/.htaccess
#      and set max upload file size to 3000M
#      You might need to run: sudo -u www-data php occ maintenance:repair


# If you see the OwnCloud page at https://localhost/owncloud,
# refresh it once and then log in with the admin id and password used on the occ command above.
# The first screen is an advertisement to get ads... press the X in the top-right.
#

# Duplicity setup
# to avoid a crash due to duplicy overfilling my root dir,
#  replace /root/.cache/duplicity with a link to the BDisk
###############################################################################

install_it(){
	local package="$1"
	if [ -z "${package}" ]; then
		echo "Error. The package name is missing."
		return -12
	else
		apt-get -y install "${package}"
		if [ ! $? = 0 ]; then
			echo "Failed to install ${package}"
			echo "Check the package name and you Internet connection."
			exit 12
		fi
	fi
}

if [ -z "${DSTAMP}" ]; then
	echo "The datastamp is blank.  Programmer error."
	exit 23
fi
###############################################################################

## A confirmation Yes/No function with optional prompt.
gshc_confirm(){
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

gshc_continue(){
    # Tell the user to press a key to continue and wait
    # for input.  I printed the prompt in full becasue in some cases
    # the line is not output until it is complete (during some
    # redirection options).
    echo  "${MSG_PRESS_KEY}"
    read  junk
}

gshc_pause(){
    local junk=""
    echo -n "${MSG_PRESS_KEY}"
    read junk
    return 0
}
###############################################################################
# check debian version
checkV=$(cat /etc/debian_version)
if [ ! "${checkV}" = "8.1" ]; then
	echo "============================================================"
	echo "WARNING> THIS SCRIPT WAS tested for Debian 8 . 1, and this"
	echo "system is ${checkV}"
	read -p "Press ENTER to continue or CTL-c to quit." junk
fi
###############################################################################

### Debian uses the www-data ID for the web server and owncloud
## checkID=$(cat /etc/passwd|grep owncloud)
## if [ -z "${checkID}" ]; then
## 	echo "I will now add the owncloud user ID that will be used to run"
## 	echo "the server."
## 	echo "Press ENTER to continue and then set the passwd for the "
## 	read -p "owncloud user ID..." junk
## 	useradd owncloud
## 	if [ ! $? = 0 ]; then
## 		echo "Failed to add the owncloud user ID."
## 		echo "Press CTL-c to quit or ENTER to continue."
## 		read -p "Press ENTER to continue or CTL-c to quit." junk
## 	fi
## 	passwd owncloud
## else
## 	echo "The owncloud user id already exists."
## fi



###############################################################################

### nginx on debian uses the www-data user id, which exists in 
### the default install of Debian 8
## checkID=$(cat /etc/passwd|grep nginx)
## if [ -z "${checkID}" ]; then
## 	echo "I will now add the nginx user ID that will be used to run"
## 	echo "the server."
## 	echo "Press ENTER to continue and then set the passwd for the "
## 	read -p "nginx user ID..." junk
## 	useradd nginx
## 	if [ ! $? = 0 ]; then
## 		echo "Failed to add the nginx user ID."
## 		echo "Press CTL-c to quit or ENTER to continue."
## 		read -p "Press ENTER to continue or CTL-c to quit." junk
## 	fi
## 	# passwd nginx
## else
## 	echo "The nginx user id already exists."
## fi

###############################################################################
#
#   Create some directories if need be
#
mount_check=$(mount|grep " ${OWNCLOUD_MNT} type btrfs")

if [ ! -z "${mount_check}" ]; then
	if [ ! -d "${WWW_ROOT}" ]; then
		echo "The WWW root directory does not exist."
		echo "It should be a btrf subvolume."
		exit 34
		# read -p "Have you already built the encrypted RAID in ${WWW_ROOT}? (y/n): " yn_temp
		# yn=$(echo "${yn_temp}"|tr '[[:upper:]]' '[[:lower:]]')
		# if [ "${yn}" = 'y' ];then
		# 	echo "You said yes."
		# 	mkdir -p "${WWW_ROOT}"
		# else
		# 	echo "you did not say yes"
		# fi
	else
		echo "Note: ${WWW_ROOT} already exists"
	fi

	if [ ! -d "${WWW_LOG_DIR}" ]; then
		echo "The WWW root directory does not exist."
		read -p "Have you already built the encrypted RAID in ${WWW_LOG_DIR}? (y/n): " yn_temp
		echo "It should be a btrf subvolume."
		exit 34
		# yn=$(echo "${yn_temp}"|tr '[[:upper:]]' '[[:lower:]]')
		# if [ "${yn}" = 'y' ];then
		# 	echo "You said yes."
		# 	mkdir -p "${WWW_LOG_DIR}"
		# else
		# 	echo "you did not say yes"
		# fi
	else
		echo "Note: ${WWW_LOG_DIR} already exists"
	fi

	chown ${HTUSER}:${HTUSER} "${WWW_ROOT}"
	chmod 700 "${WWW_ROOT}"
	chown ${HTUSER}:${HTUSER} "${WWW_LOG_DIR}"
	chmod 700 "${WWW_LOG_DIR}"
else
	echo "===================================================================="
	echo "WARNING: Your OwnCloud disk was not mounted: ${OWNCLOUD_MNT}."
	echo "You can rerun this script after you create your encrypted RAID1."
	read -p "Press ENTER to continue..." junk
fi








#############################################################################
# get the sources list so I can get non-free or contrib software
install_it wget

check1=$(cat /etc/apt/sources.list|grep 'non[-]free')

if [ -z "${check1}" ]; then
	# archive the old sources list and get my version
	echo "getting the new sources.list"
	cp /etc/apt/sources.list  "/etc/apt/sources.list${DSTAMP}"
	wget --no-check-certificate https://raw.githubusercontent.com/bobdab/configscripts/master/deb8/sources.list -O /etc/apt/sources.list 
fi
###############################################################################
ping -c 1 www.yahoo.com
if [ ! $? = 0 ]; then
	echo "The internet seems to be down. Check the connection and try again."
	exit 5
fi
###############################################################################
#  Update the new repo lists.
#  New sources might require db fetch for subsequent installs
#
apt-get update && apt-get upgrade
if [ ! $? = 0 ]; then
	echo "Failed to upgrade.  Are you connected to the Internet?"
	exit 12
fi
#############################################################################
# Some preliminaries that might be needed for some packages.
# and send output to the log file.
# These are in the contrib section, so the new sources.list is needed
install_it dpkg-dev gpgv2  >> "${LOG_FNAME}"
###############################################################################
#  Install a few of my personal favorite tools:
# vim = editor
# gnome-disk-utility is a disk utility 
# links and lynx are text-based web browsers
# wget is a comman-line web page fetcher
echo "========================================="
echo "Install a few utilities (output will go to ${LOG_FNAME})..."
install_it vim  >> "${LOG_FNAME}"
install_it gnome-disk-utility  >> "${LOG_FNAME}"
install_it links  >> "${LOG_FNAME}"
install_it lynx  >> "${LOG_FNAME}"
install_it fslint  >> "${LOG_FNAME}"
install_it aspell  >> "${LOG_FNAME}"
install_it ispell  >> "${LOG_FNAME}"

yn='n'
read -p "Do you want to install emacs (no-X11)? (y/n): " yn
if [ "${yn}" = 'y' ]; then
	install_it emacs24-nox  >> "${LOG_FNAME}"
fi

###############################################################################
# btrfs and cryptsetup
echo "========================================="
echo "Install btrfs tools..."
install_it cryptsetup  >> "${LOG_FNAME}"
install_it btrfs-tools  >> "${LOG_FNAME}"

echo "You should probably reboot to be 100% sure that everything can run"
read -p "Press ENTER to continue..." junk

#############################################################################

yn='n'
echo "=============================================================="
read -p "Do You want to install OwnCloud (OK to rerun): " yn_temp
yn=$(echo "${yn_temp}"|tr '[[:upper:]]' '[[:lower:]]')
if [ "${yn}" = 'y' ]; then
	# First check if the data directories are mounted and ready.

	good='F'
	while [ ! "${good}" = "T" ]; do
		mount_check='xx'
		mount_check=$(mount|grep " ${OWNCLOUD_MNT} type btrfs")

		if [ ! -z "${mount_check}" ]; then
			if [ ! -d "${WWW_ROOT}" ]; then
				echo "The WWW root directory does not exist."
				echo "It should be a btrf subvolume."
				exit 34
				# read -p "Have you already built the encrypted RAID in ${WWW_ROOT}? (y/n): " yn_temp
				# yn=$(echo "${yn_temp}"|tr '[[:upper:]]' '[[:lower:]]')
				# if [ "${yn}" = 'y' ];then
				# 	echo "You said yes."
				# 	mkdir -p "${WWW_ROOT}"
				# else
				# 	echo "you did not say yes"
				# fi
			else
				good='T'
				echo "Note: ${WWW_ROOT} already exists"
			fi
		else
			echo "==============================================================="
			echo "I don't see the ${OWNCLOUD_MNT} mount."
			echo "Did you decrypt the RAID1 volumes and mount the btrfs filesystem?"
			read -p  "Mount all and then press ENTER" junk
		fi
	done


	#                             Own Cloud installs
	#
	# I will use nginx web server with PostGreSQL database.
	# The OwnCloud server install also installs lots of dependencies, including
	# many php modules.

	
	read -p "Remove Apache2 web server from ther service autostart? (y/n) : " yn
	if [ ! "${yn}" = 'y' ]; then
		update-rc.d apache2 remove
		# You should now see the minus sign
		service --status-all |grep apache
	fi
	echo "Installing nginx (output will go to ${LOG_FNAME})."
	install_it nginx  >> "${LOG_FNAME}"
	# check status:
	systemctl status nginx.service


	install_php='y'
	yn='y'
	if [ -f /usr/bin/php ]; then
		yn='n'
		echo "PHP is already installed. Do you want to reinstall it"
		read -p "along with related dependencies? (y/n): " yn
		if [ ! "${yn}" = 'y' ]; then
			install_php='n'
		fi
	fi
	if [ "${install_php}" = 'y' ]; then
		echo "Installing PGP (output will go to ${LOG_FNAME})."
		install_it php5-gd  >> "${LOG_FNAME}"
		install_it php5-json  >> "${LOG_FNAME}"
		install_it php5-pgsql  >> "${LOG_FNAME}"
		install_it php5-curl  >> "${LOG_FNAME}"
		install_it php5-intl  >> "${LOG_FNAME}"
		install_it php5-mcrypt  >> "${LOG_FNAME}"
		# Bob added this:
		install_it php5-fpm   >> "${LOG_FNAME}"

	fi

	# ###############################################################################
	#
	#  PostgreSQL
	#
	install_p="FALSE"
	if [ -z "${POSTGRE_VER}" ]; then
		echo "the postgre version is missing."
		exit 15
	fi

	if [ -f "${PGSQL_BIN_DIR}/pg_ctl" ]; then
		echo
		echo
		echo "Postgres appears to be installed already."
		if (gshc_confirm "Do you want to re-install PostgreSQL? (y/n): "); then
			install_p="TRUE"
		fi
	else
		if (gshc_confirm "Do you want to install PostgreSQL? (y/n): "); then
			install_p="TRUE"
		fi
	fi

	if [ "${install_p}" = 'TRUE' ]; then
		echo "postgre install log will be in ${LOG_FNAME}"
		install_it postgresql-server-dev-all  >> "${LOG_FNAME}"
		install_it postgresql postgresql-client  >> "${LOG_FNAME}"
		apt-get source postgresql-server-dev-all  >> "${LOG_FNAME}"
		# gpg to verify file sigs 
		# for libpq-fe.h, install the devel version of libpqxx
		install_it libpqxx3-dev  >> "${LOG_FNAME}"
		echo "" | tee -a "${LOG_FNAME}"
		
		echo  ""
		echo "When prompted, enter the password for the postgres user ID"
		passwd postgres


		chown -R postgres:postgres "${PGUSER_HOME}"
		sudo -u postgres ${PGSQL_BIN_DIR}/pg_ctl -D ${PGSQL_DATA} initdb
		if [ $? = 0 ]; then
			# result of starting postgreSQL:
			ps -A|grep postgres
			echo "postgre has been started"
			# SEction 4.3.3.3 of the 8.1 server guide says that OwnCloud will
			# create the database and users, but PHP needs the right drivers
			# # sudo -u postgres psql -c "create database owncloud;"
			# # sudo -u postgres psql -c "CREATE USER admin;" owncloud
			# # sudo -u postgres psql -c "ALTER USER admin WITH PASSWORD '5bbb2ec6b6404d0a26ee5dbd35ffdb38ac655c16';" owncloud

		fi

		## Success. You can now start the database server using:
		## 
		##     sudo -u postgres /usr/lib/postgresql/9.4/bin/postgres -D /media/owncloud/OC/pgsql/9.4/main
		## or
		##     sudo -u postgres /usr/lib/postgresql/9.4/bin/pg_ctl -D /media/owncloud/OC/pgsql/9.4/main -l logfile start

	else
		echo "skipping postgre install"
	fi
			
	install_owncloud='y'
	yn='y'
	if [ -f /usr/bin/owncloud ]; then
		yn='n'
		echo "The OwnCloud program from apt-get are already installed. Do you want to reinstall it"
		read -p "along with related dependencies? (y/n): " yn
		if [ ! "${yn}" = 'y' ]; then
			install_owncloud='n'
		fi
	fi
	if [ "${install_owncloud}" = 'y' ]; then
		echo "Installing owncloud server (output will go to ${LOG_FNAME})."
		echo "(This will get the programs but not execute the install/configure"
		echo "step until the next block of code runs)"
		echo "debian has old versions of owncloud so I won't install them."
		echo "I will install the tarball to /media/owncloud/OC/www/owncloud"
		## install_it owncloud  >> "${LOG_FNAME}"
		## install_it owncloud-client  >> "${LOG_FNAME}"
		## install_it owncloud-client-cmd  >> "${LOG_FNAME}"
		## install_it owncloud-client-doc  >> "${LOG_FNAME}"
		## install_it owncloud-doc  >> "${LOG_FNAME}"
	fi

	# git is required for cowboy to fetch dependencies
	apt-get -y install git
	###############################################################################
	# Chapter 4.2 of OwnCloud 8.1 server manner
	# Also see postgreSQL not in 7.5.2
	if [ -z "${OCPATH}" ]; then
		echo "OCPATH is blank"
		exit 35
	fi

	if [ ! -d "${OCPATH}" ]; then
		mkdir -p "${OCPATH}"
	fi

	chown    ${HTUSER}:${HTUSER} ${WWW_ROOT}/

else
	echo "skipping owncloud server install."
fi
###############################################################################
yn='n' echo "=============================================================="
read -p "Do You want generate self-signed ssl keys? (y/n) " yn_temp
yn=$(echo "${yn_temp}"|tr '[[:upper:]]' '[[:lower:]]')
if [ "${yn}" = 'y' ]; then
	mkdir -p /etc/ssl/nginx/

    #     #
    if [ ! -d /root/noarch/keytemp ]; then
        mkdir -p /root/noarch/keytemp
    fi
    chmod 700 /root/noarch/keytemp
    cd /root/noarch/keytemp

	# Generate the key
	echo "===== You can enter a temporary password here because I will remove it"
    openssl genrsa -aes256 -out owncloud.key 2048
	if [ ! $? = 0 ]; then
		echo "Error. Failed to generate the ssl key."
	fi

    # remove the password if need be (and store files on ecryptfs)
    openssl rsa -in owncloud.key -out owncloud.key
    openssl req -new -inform PEM -outform PEM -key owncloud.key -out owncloud.csr

   # Do the next openssl commands ONLY FOR SELF-SIGNED CERTIFICATE.
    # create the self-signed certificate
    echo "When the X509 certificate request is being created,"
    echo "you need to enter the correct domain name or IP in the"
    echo "Common Name field (do not include 'http://')"
    ##openssl x509 -req -inform PEM -outform PEM -days 63 \
    openssl x509 -req -inform PEM -outform PEM  -days 400 \
        -in owncloud.csr -signkey owncloud.key -out owncloud.crt
	if [ ! $? = 0 ]; then
		echo "Error. Failed to create the self-signed certificate."
	fi

    # You can run this to get information from your crt file:
    openssl x509 -text -in owncloud.crt # get info
    if [ ! -d "${CERT_KEY_DIR}" ]; then
        mkdir -p "${CERT_KEY_DIR}"
    fi
    chown -R ${HTUSER}:${HTUSER} "${CERT_KEY_DIR}"
    chmod 700 "${CERT_KEY_DIR}"

    # Make a copy of any old keys, and append a date-stamp to the file name:
	if  [ -f "${CERT_KEY_DIR}/owncloud.key" ]; then
		if ! (cp \
				"${CERT_KEY_DIR}/owncloud.key" \
				"${CERT_KEY_DIR}/${DSTAMP}.owncloud.key" ); then
			echo "Error. Failed to archive a key file"
			exit 239
		fi
	fi
	if  [ -f "${CERT_KEY_DIR}/owncloud.crt" ]; then
		if ! (cp \
				"${CERT_KEY_DIR}/owncloud.crt" \
				"${CERT_KEY_DIR}/${DSTAMP}.owncloud.crt" ); then
			echo "Error. Failed to archive a key file"
			exit 239
		fi
	fi

	cp owncloud.* "${CERT_KEY_DIR}"

fi
###############################################################################
yn='n' echo "=============================================================="
read -p "Do You want to configure OwnCloud Server? (y/n) ." yn_temp
yn=$(echo "${yn_temp}"|tr '[[:upper:]]' '[[:lower:]]')
if [ "${yn}" = 'y' ]; then
	if [ -z "${OCPATH}" ]; then
		echo "OCPATH is blank"
		exit 35
	fi

	cd "${OCPATH}"

	echo "Now running the occ configuration..."
	sudo -u www-data php occ maintenance:install --database "pgsql" --database-name "owncloud" --database-user "admin" --admin-pass "5bbb2ec6b6404d0a26ee5dbd35ffdb38ac655c16"
	if [ ! $? = 0 ]; then
		echo "=============================================================================="
		echo "Error.  The php occ maintenance:install command failed.  The path was ${OCPATH}"
		echo "Be sure that your database is running and that you created the owncloud database"
		echo "and ran the database command to set the admin password?"
	fi
fi
###############################################################################
yn='n'
echo "=============================================================="
read -p "Do You want set permisions for owncloud directories." yn_temp
yn=$(echo "${yn_temp}"|tr '[[:upper:]]' '[[:lower:]]')
if [ "${yn}" = 'y' ]; then

	mkdir -p ${OCPATH}/apps/
	mkdir -p ${OCPATH}/config/
	mkdir -p ${OCPATH}/data/
	mkdir -p ${OCPATH}/themes/
	mkdir -p ${OCPATH}/.htaccess/
	mkdir -p ${OCPATH}/data/
	mkdir -p ${OCPATH}/data/.htaccess


	# Bob added this one:
	chown    ${HTUSER}:${HTUSER} ${WWW_ROOT}/
	## from page 23 of the 8.1 server manual:
	#find ${OCPATH}/ -type f -print0 | xargs -0 chmod 0640
	#find ${OCPATH}/ -type d -print0 | xargs -0 chmod 0750
	find ${OCPATH}/ -type f -exec chmod 0640 {} \;
	find ${OCPATH}/ -type d -exec chmod 0750 {} \;
	chown -R root:${HTUSER} ${OCPATH}/
	chown -R ${HTUSER}:${HTGROUP} ${OCPATH}/apps/
	chown -R ${HTUSER}:${HTGROUP} ${OCPATH}/config/
	chown -R ${HTUSER}:${HTGROUP} ${OCPATH}/data/
	chown -R ${HTUSER}:${HTGROUP} ${OCPATH}/themes/
	chown root:${HTUSER} ${OCPATH}/.htaccess
	chown root:${HTUSER} ${OCPATH}/data/.htaccess
	chmod 0644 ${OCPATH}/.htaccess
	chmod 0644 ${OCPATH}/data/.htaccess
	echo "OCPATH was ${OCPATH}"
fi

echo "postgre install log will be in ${LOG_FNAME}"
#  set local time zone using: dpkg-reconfigure tzdata
