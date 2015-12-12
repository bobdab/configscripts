#!/bin/sh

# I use this to mount disk volumes (OpenBSD 5.6)
# on my OpenBSD server (4 internal disks),
# some of which have encrypted partitions
# and some have encrypted software RAID devices).
# This contains hard-coded UUIDs for my disks.
#
# The main function is enc_raid_setup(), which is
# used to take two disk partitions and build
# a raw RAID device, then overay the encrypted
# device using bioctl. 
#

############################################################
# check if my hard-coded, local network is ready
chk=$(ifconfig |grep '10[.]0[.]0[.]8')
if [ -z "${chk}" ]; then
	echo "I do not see the 10.0.0.8 network anywhere"
	echo "trying now..."
	ifconfig em1 10.0.0.8 up
	sleep 5
fi

## look again
chk=$(ifconfig |grep '10[.]0[.]0[.]8')
if [ -z "${chk}" ]; then
	echo "I do not see the 10.0.0.8 network anywhere"
	echo "quitting now"
	exit
fi
############################################################
############################################################
# Mount my disk that holds virtual machines.
# I don't need this on my OpenBSD machine. This was
# from the Fedora version---OpenBSD does not support
# virtualization and does not have libvirtd within 
# the libvirt package, so I don't need this.
#
gshc_disk='0e6214584970073e'
gshc_mnt_pt='/gshcmnt'
gshc_partition_letter=g

if [ ! -d "${gshc_mnt_pt}" ]; then
	mkdir "${gshc_mnt_pt}"
fi
mount  "${gshc_disk}.${gshc_partition_letter}" "${gshc_mnt_pt}"
############################################################
# This is for part 2: (encrypted partitions, no RAID)
# my_enc_uuid is the encrypted device after loading by bioctl
my_enc_uuid='652c77bbc1cb3aac'
enc_mnt_pt='/mnt/enc1'
my_enc_source_dev='3408926e3c0619c3.b'

# a second encrypted partition (no RAID)
my_enc2_uuid='d02e2e744e3a600c'
enc_mnt2_pt='/arch1'
my_enc2_source_dev='c6631e0258971066.g'

############################################################
############################################################
############################################################
############################################################
############################################################
enc_raid_setup(){
	# Given two disk UUIDs, a RAID UUID, an encrypted
	# RAID UUID, a mount point, and one disk partition letter
	# (both raid partitions must have the same partittion letter),
	# this will verify that the software RAID device exists
	# (if not, create it using bioctl)
	# then this will check if the encrypted device exists
	# (the encrypted device is created over the RAID using 
	# bioctl).  If the encrypted device is not available, it
	# will be created.
	# 
	# You get the UUIDs for each device by running the process
	# manually and making note of the UUIDs as you do it,
	# then you call this function to reproduce your efforts.
	# 
	# You may rerun this safely at any time, and if any
	# part of the device overlay is not ready, it will
	# be prepared and brought online.
	#
	
	local raid_disk1="$1"
	local raid_disk2="$2"
	local my_raid_uuid="$3"
	local my_enc_raid_uuid="$4"
	local enc_raid_mnt_pt="$5"
	local raid_partition_letter="$6"
		
	echo "==============================================="
	chk=$(disklabel "${my_raid_uuid}"|grep "${my_raid_uuid}")
	echo "assembled_raid check: ${chk}"

	if [ -z "${chk}" ]; then
		# The device associated with the assembled raid
		# was not found. 
		echo "Assembling the RAID1 now..."
		bioctl -c 1 -l "${raid_disk1}.${raid_partition_letter},${raid_disk2}.${raid_partition_letter}" softraid0
	fi

	# Check again for the raid
	chk=$(disklabel "${my_raid_uuid}"|grep "${my_raid_uuid}")
	if [ -n "${chk}" ]; then
		# The underlying RAID is ready, now overlay
		# with the encryption thing.
		chk_e=$(disklabel "${my_enc_raid_uuid}"|grep "${my_enc_raid_uuid}")
		echo "encrypted device check: ${chk_e}"
		if [ -z "${chk_e}" ]; then
			# The encrypted device does not exist,
			# so load it
			# The next line will create device my_enc_raid_uuid = e6abc86faed411ee
			bioctl -c C -l "${my_raid_uuid}.a" softraid0
		else
			echo "The encrypted device already exists."
		fi
		
		# Mount the encrypted device that resides over the RAID 1
		if [ ! -d "${enc_raid_mnt_pt}" ]; then
			mkdir  "${enc_raid_mnt_pt}"
		fi

		# convert DUID to a device name, such as sd2
		dest_dev_name=$(disklabel  "${my_enc_raid_uuid}"|grep '^[#] \/dev\/r'|cut -b 9-11)
		echo "dest device name: ${dest_dev_name}"
		if [ -z "${dest_dev_name}" ]; then
			echo "Error dev name was not found (I was looking for somehting like sd0 or sd1)"
			echo "The value that I parsed from disklabel was: ${dest_dev_name}"
			echo "while examining device ${my_enc_raid_uuid}"
			return 33
		fi

		chk_e_mnt=$(mount|grep "${dest_dev_name}")
		if [ -z "${chk_e_mnt}" ]; then
			echo "Mounting the encrypted disk by UUID"
			mount "${my_enc_raid_uuid}.a" "${enc_raid_mnt_pt}"
		else
			echo "The encrypted disk is already mounted: ${chk_e_mnt}"
		fi
		############################################################
	else
		echo "Error. The RAID1 device has not been assembled."
	fi

	# show disk names
	sysctl hw.disknames
	echo "==============================================="
	return 0
}
### end of enc_raid_setup()


############################################################
#              Prepare and mount encrypted disk

prep_enc_dev(){
	# This is used to prepare and mount a single partition
	# as an encrypted device using bioctl.
	#
	# This can be rerun without breaking anything.
	#
	local my_enc_uuid="$1"
	local my_enc_source_dev="$2"
	local enc_mnt_pt="$3"

	echo "==============================================="
	# see if the encrypted disk is already loaded
	chk_e=$(disklabel "${my_enc_uuid}"|grep "${my_enc_uuid}")
	echo "Encrypted device check: ${chk_e}"
	if [ -z "${chk_e}" ]; then
		# The encrypted device does not exist,
		# so load it
		bioctl -c C -l "${my_enc_source_dev}" softraid0
	else
		echo "The encrypted device already exists."
	fi

	echo "checkpoint a"

	#my_enc_uuidd
	dest_dev_name=$(disklabel  "${my_enc_uuid}"|grep '^[#] \/dev\/r'|cut -b 9-11)
	echo "dest dev name is ${dest_dev_name}"
	if [ -z "${dest_dev_name}" ]; then
		echo "error dev name was not found"
		return 33
	fi

	if [ ! -d "${enc_mnt_pt}" ]; then
		mkdir  "${enc_mnt_pt}"
	fi

	echo "checkpoint b"

	chk_e_mnt=$(mount|grep "${dest_dev_name}")
	if [ -z "${chk_e_mnt}" ]; then
		echo "Mounting the encrypted disk by UUID"
		if(mount "${my_enc_uuid}.a" "${enc_mnt_pt}"); then
			echo "mount looks OK"
		else
			echo "the mount failed. Did you remember to fdisk, disklabel (add partition), newfs the partition?"
		fi
	else
		echo "The encrypted disk is already mounted: ${chk_e_mnt}"
	fi
	echo "==============================================="
	return 0
}

############################################################
############################################################
############################################################
############################################################
############################################################
############################################################
############################################################

# run the macros described above:
#enc_raid_setup "${raid_disk1}"  "${raid_disk2}" "${my_raid_uuid}" "${my_enc_raid_uuid}" "${enc_raid_mnt_pt}"

## 50G junk encrypted raid
raid_disk1='0e6214584970073e'
raid_disk2='c6631e0258971066'
my_raid_uuid='55a68f85bd1ecb82'
my_enc_raid_uuid='91cb003eea0308b6'
enc_raid_mnt_pt='/RD/junk'
raid_partition_letter='d'
enc_raid_setup "${raid_disk1}"  "${raid_disk2}" "${my_raid_uuid}" "${my_enc_raid_uuid}" "${enc_raid_mnt_pt}" "${raid_partition_letter}"



## 150G enc raid
## enc raid dev 8028b418b37ecc00
raid_disk1='0e6214584970073e'
raid_disk2='c6631e0258971066'
my_raid_uuid='cd5bdcec6e4f28af'
my_enc_raid_uuid='8028b418b37ecc00'
enc_raid_mnt_pt='/RD/SILOS'
raid_partition_letter='e'
enc_raid_setup "${raid_disk1}"  "${raid_disk2}" "${my_raid_uuid}" "${my_enc_raid_uuid}" "${enc_raid_mnt_pt}" "${raid_partition_letter}"


## 200G enc raid
## enc raid dev 8028b418b37ecc00
raid_disk1='0e6214584970073e'
raid_disk2='c6631e0258971066'
my_raid_uuid='bb115069cf4bdfc3'
my_enc_raid_uuid='6e5964dc5f3c5148'
enc_raid_mnt_pt='/RD/home'
raid_partition_letter='f'
enc_raid_setup "${raid_disk1}"  "${raid_disk2}" "${my_raid_uuid}" "${my_enc_raid_uuid}" "${enc_raid_mnt_pt}" "${raid_partition_letter}"




############################################################

prep_enc_dev "${my_enc_uuid}" "${my_enc_source_dev}" "${enc_mnt_pt}"
prep_enc_dev "${my_enc2_uuid}" "${my_enc2_source_dev}" "${enc_mnt2_pt}"
############################################################
# run nfsd

/etc/rc.d/portmap start
/etc/rc.d/mountd start
/etc/rc.d/nfsd start

echo "If there are problems with the /etc/exports file or nfsd does not work,"
echo "look in /var/log/deamon for errors related to /etc/exports."

########################################
# if this fails, check /var/log/daemon
/etc/rc.d/rsyncd start

#####
# check nfs pgms 
rpcinfo -p 10.0.0.8
echo " "
# show available nfs mounts
showmount -e 10.0.0.8

nfsstat -s

netstat -A
