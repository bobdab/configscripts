#!/bin/sh

# Get notes from these sources:
# https://openvpn.net/howto.html
# https://wiki.debian.org/OpenVPN
# http://www.techrepublic.com/blog/linux-and-open-source/how-to-set-up-an-openvpn-server

# A1) The regular setup will make a fake/local IP address for the server visible
#    to the client, but if you want to tunnel all traffic to the VPN server,
#    you have to add something to the SERVER config file:
#      push "redirect-gateway def1"
#    or if all clients and server are on the same wireless network:
#      push "redirect-gateway local def1"
#    THEN you have to use masquerading on the server to POSTROUTE the 
#    VPN traffic to eth0 and push DNS to the VPN server.  see https://openvpn.net/howto.html
#    and search for POSTROUTING.  A risk is that the local client will need
#    to talk to the local DNS for some reason, and the DNS push will obstruct
#    that (does a static IP solve the problem?).
# A2) The clocks on client and server need to be approximately in sync, or there will
#    be an error.
# A3) The client will need the ca.crt, clientXXXX.crt, clientXXX.key.  The ca.key is
#    secret, so don't email it.  consider adding a password to the ca.key.
# A4) send signal SIGUSR2 to dump statistics to a log file (log filename is
#    in the server.conf file, but the default does not specify the directory).
# A5) I will need static IP addresses like 10.8.0.2-10 for my erlang nodes,
#    so that means I will need a client configuration directory on the server
#    (where clients are assigned to IP). see https://openvpn.net/howto.html
#    and search for client-config-dir.  The name of the file in the ccd
#    subdirectory (no file extension) is probably the same as the name
#    for the client key files??  Read the help page because the IPs
#    must be set in special pairs.
# B) The example server.conf file
#    from /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz 
#    says that I should generate a file with --genkey --secret and that
#    can help prevent udp flooding and DOS.
# C) The example server.conf file has an entry to drop privileges after the
#    daemon starts, and this is probably a good idea.  Create
#    a user/group called openvpn
# D) I uncomment the mute option in server.conf to print no more than 10 
#    repeated err messages.
# e) run the long command from the client:
#        openvpn --remote 192.168.1.11 --dev tun1 --ifconfig 10.8.0.2 10.8.0.1 --comp-lzo yes --tls-client --ca /etc/openvpn/ca.crt --cert /etc/openvpn/client_slave01.crt --key /etc/openvpn/client_slave01.key --reneg-sec 60 --verb 6
#    or create the client.conf file from the easy-rsa examples and run
#        openvpn --config /etc/openvpn/client.conf
# f)  STOP the openvpn server through systemctl and run it manually or it won't work:
#        sudo systemctl stop openvpn
#        sudo openvpn --config /etc/openvpn/server.conf
# g) I had an error msg on the server saying that the client did not have the lzo compression option, so
#    I added it to the manual string above (my client.conf has the lzo and it works).
# m) what happens when the main erlang node VPN fails---the foreign nodes are not reachable.
#    OpenVPN does have a failover, but I'm not sure what can be done for erlang nodes.
#    I could have all erlang nodes connect to a separate server and add route info
#    so that all nodes can access all other nodes in a star configuration.
# n) use tls-auth and the --secret option shown below.  This adds a layer of security and
#    protects against various attacks.
# o) I could add this to client and server config files:
#        cipher AES-256-CBC
# p) move the ca.key off the server after client keys are signed.  It can be an offline key.

# The general procedure is...
#  1) Install openvpn and easy-rsa using apt-get.
#  2) Copy example files from easy-rsa.
#  3) Edit the easy-rsa/vars file to define the info for
#     the certificate (this is optional because you
#     will be prompted when you generate the certificates).
#  4?) Build the final server.conf file and point to
#     the dh keys and IP and routing info.
#  5) Build the certificate authority keys (this will be 
#     used to sign the server and client keys -- the ca.key
#     file can be stored offline after all keys are signed, or
#     perform the key-creation process on an offline coputer.
#  6) Build the server certificate and sign it with the CA key.
#  7) Build one or more client certificates and sign them with the CA key.
#  8) Distribute the ca.crt file to all clients and also
#     send the appropriate clientXXXX.crt, clientXXX.key files
#     to the client /etc/openvpn directory.
#  9) connect from client to server.
#

# BE sure to open UDP 1194 on the firewall on the server.
# BE sure to open UDP 1194 on the firewall on the server.
# BE sure to open UDP 1194 on the firewall on the server.

apt-get install openvpn easy-rsa

SERVER_IP=shard03.naturalmessage.com
CLIENT_IP=192.168.1.51
# Note: if your local IP is in 192.168...., then it is safest to 
# put the fake IP on a different subnet, such as 10.9.....
FAKE_SERVER_IP=10.8.0.1
FAKE_CLIENT_IP=10.8.0.2


cd /etc/openvpn
if [ ! -f /etc/openvpn/bobsharedsecret.key ]; then
	# generate a static server key,
	# then copy this to each client's /etc/openvpn directory 
	# via a secure channel.
	echo "Generating an OpenVPN key..."
	openvpn --genkey --secret bobsharedsecret.key
fi

echo "Remember to add a line to the server and client conf files"
echo "to refer to the secret key."
echo
echo "   secret /etc/openvpn/bobsharedsecret.key"
echo
read -p "Press ENTER to continue..." junk
## 
## if [ ! -f /etc/openvpn/tun0.conf ]; then
## cat > /etc/openvpn/tun0.conf <<EOF
## dev tun0
## ifconfig 10.8.0.1 10.8.0.2
## secret /etc/openvpn/bobsharedsecret.key
## EOF
## fi
## 
## if [ ! -f /etc/openvpn/client-tun0.conf ]; then
## # this file should be MOVED to the client /etc/openvpn directory
## # and call the file 'tun0.conf'.
## cat > /etc/openvpn/client-tun0.conf <<EOF
## remote shard03.naturalmessage.com
## dev tun0
## ifconfig 10.8.0.1 10.8.0.2
## secret /etc/openvpn/bobsharedsecret.key
## EOF
## fi

####
cd /etc/openvpn
mkdir -p easy-rsa

# copy, but do not clobber:
cp -nR /usr/share/easy-rsa/* easy-rsa

echo "now edit the country, city, etc in /etc/openvpn/easy-rsa/vars"
echo "and check the dh key size (2048)"

cd /etc/openvpn/easy-rsa
touch keys/index.txt
echo 01 > keys/serial
. ./vars
./clean-all

###############################################################################
cd /etc/openvpn/easy-rsa
clear
echo "==== I will now build the certificate authority key for my VPN."
# Consider building two CA files: one to sign all the clients and
# one to sign just the server.  The clients get the public CRT for the
# key that signed the server, and the server uses the public CRT for 
# the key that signed the clients.
./build-ca

clear
echo "==== I will now build the certificate for my server."
# This uses an extra attribute that designates the certificate as being
# a server certificate, then the client should add "remote-cert-tls server"
# to the conf file to ensure that it is connecting to a cert marked
# as a server (as opposed to another client cert!). This is in
# the example conf file from easy-rsa.
./build-key-server server

clear
echo "==== I will now build the certificate for slave01 ip 51."
echo "I don't think the common name or any other field matters"
echo "as long as the key is signed by the CA."
./build-key client_slave01

clear
echo "==== I will now build the certificate for slave02 ip 06."
./build-key client_slave02

clear
echo "==== I will now build the diffie helman key."
./build-dh

### Files created during a test run
## 01.pem  client_slave01.crt  client_slave02.csr  index.txt.attr      serial.old
## 02.pem  client_slave01.csr  client_slave02.key  index.txt.attr.old  server.crt
## ca.crt  client_slave01.key  dh2048.pem          index.txt.old       server.csr
## ca.key  client_slave02.crt  index.txt           serial              server.key

cd /etc/openvpn
cp easy-rsa/keys/ca.crt .
cp easy-rsa/keys/server.key .
cp easy-rsa/keys/server.crt .
cp easy-rsa/keys/dh2048.pem .

###############################################################################
# create the server.conf file
cd /etc/openvpn

if [ ! server.conf ]; then
	# copy but do not clobber the example server.conf
	cp -n /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz ./ 
	gunzip server.conf.gz
fi

echo "at this point, stop and edit the /etc/openvpn/server.conf file"


###############################################################################

# # cleartext example, must be run as root
# openvpn --remote ${CLIENT_IP}  --dev tun1 --ifconfig ${FAKE_SERVER_IP} ${FAKE_CLIENT_IP}
# 
# 
# # cleartext example FROM THE CLIENT SIDE where fake IPs are 100+
# # openvpn --remote 192.168.1.11 --dev tun1 --ifconfig 192.168.1.101 192.168.1.100

