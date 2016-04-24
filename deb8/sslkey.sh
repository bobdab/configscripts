#!/bin/sh
clear
u=$(id -u)
if [ ! "${u}" = "0" ]; then
    echo "You must be root to run this.  Try:"
    echo "   sudo $0"
    exit
fi

echo "If you are trying to create Natural Message keys, see the sslNatMsg.sh script"
read -p "Press ENTER to continue " junk


# key format is PEM or DER
KEY_FORMAT=PEM
##WORKING_DIR=/root/noarch/keytemp
WORKING_DIR=/mnt/D/boblock/keytemp

KEYNAME_PREFIX=""
echo "This will create a new SSL key that you can either self-sign or have signed by an official certificate authority."
read -p "Enter the first part of the filename (NO path) for the new ssl key: " KEYNAME_PREFIX
###############################################################################
yn='n'
echo "=============================================================="
echo "Do You want to create an ssl key with the filename"
read -p "prefix of: ${KEYNAME_PREFIX}? (y/n): " yn_temp
yn=$(echo "${yn_temp}"|tr '[[:upper:]]' '[[:lower:]]')
if [ "${yn}" = 'y' ]; then
    
    #     #
    if [ ! -d ${WORKING_DIR} ]; then
        mkdir -p ${WORKING_DIR} 
    fi
    chmod 700  ${WORKING_DIR}
    cd  ${WORKING_DIR}

    # Make a copy of any old keys, and append a date-stamp to the file name:
	if  [ -f "${KEYNAME_PREFIX}.key" ]; then
		if ! (cp \
				"${KEYNAME_PREFIX}.key" \
				"${DSTAMP}.${KEYNAME_PREFIX}.key" ); then
			echo "Error. Failed to archive a key file"
			exit 239
		fi
	fi
	# Generate the key
	echo "===== You can enter a temporary password here because I will remove it"
    openssl genrsa -aes256   -out "${KEYNAME_PREFIX}.key" 2048
	if [ ! $? = 0 ]; then
		echo "Error. Failed to generate the ssl key."
        read -p "Press ENTER to continue" junk
	fi

    # remove the password if need be (and store files on ecryptfs)
    echo "======= removing the password"
    openssl rsa -in "${KEYNAME_PREFIX}.key" -outform  PEM   -out "${KEYNAME_PREFIX}.key"


    echo "======= creating the CSR file (did not like a DER input file)"
    openssl req -inform PEM -outform ${KEY_FORMAT}  -key "${KEYNAME_PREFIX}.key" -out "${KEYNAME_PREFIX}.csr" -new -sha256
    if [ ! $? = 0 ]; then
        echo "Error. Failed to create the CSR file."
        read -p "Press ENTER to continue" junk
    fi

    # check the output
    echo "============================== here is some info about the request. check for sha256 or better"
    openssl req -inform ${KEY_FORMAT} -in "${KEYNAME_PREFIX}.csr" -noout -text
    read -p "Press ENTER to continue" junk
    

    echo
    echo  "You now have a private SSL key called: ${WORKING_DIR}/${KEYNAME_PREFIX}.key"
    echo  "and a certificate signing request (CSR) called: ${WORKING_DIR}/${KEYNAME_PREFIX}.csr."
    yn='n'
    read -p "Do you want to sign this yourself?  (y/n) " yn_temp
    yn=$(echo "${yn_temp}"|tr '[[:upper:]]' '[[:lower:]]')
    if [ "${yn}" = 'y' ]; then
       # Do the next openssl commands ONLY FOR SELF-SIGNED CERTIFICATES.
        # create the self-signed certificate
        echo "When the X509 certificate request is being created,"
        echo "you need to enter the correct domain name or IP in the"
        echo "Common Name field (do not include 'http://')"
        ##openssl x509 -req -inform PEM -outform PEM -days 63 \
        openssl x509 -req  -outform  ${KEY_FORMAT} -days 400 \
            -in ${KEYNAME_PREFIX}.csr -signkey ${KEYNAME_PREFIX}.key -out ${KEYNAME_PREFIX}.crt
        if [ ! $? = 0 ]; then
            echo "Error. Failed to create the self-signed certificate."
            read -p "Press ENTER to continue" junk
        fi

        # You can run this to get information from your crt file:
        echo "====== some info about the new CRT file:"
        openssl x509 -text -in ${KEYNAME_PREFIX}.crt # get info
    fi
fi

echo "Remember that your keys are in the working directory: ${WORKING_DIR}"
