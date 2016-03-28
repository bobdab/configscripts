exit
these are notes, not a script

After running the letsencrypt-auto command at the bottom, look in
/etc/letsencrypt/live/ for keys.

# 
# Notes for installing SSL certificates through EFF's "Let's Encrypt"
# service.
#
# I will not be using the "auto" install for the certs because I am
# not using the typical web server.
#
# pre-install checklist:
#  1) if behind a router, is port 443 forwarded to the server?
#  2) is the firewall open on port 443?
#  3) does your server work with a self-signed certificate or a real cert?
#
# This is based on the initial set of instructions during the open Beta 
# test. See https://letsencrypt.org/howitworks/
# The explanation of how the process works is:
#    https://letsencrypt.org/howitworks/technology/
#
###############################################################################
ID1="$EUID"
if [ -z "${ID1}" ]; then
    ID1=$(id -u)
fi
if [ ! "${ID1}" = "0" ]; then
    echo "ERROR. You must run this as root."
    exit 15
fi
###############################################################################
cd /root
if [ ! -f /root/letsencrypt/letsencrypt/validator.py ]; then
	echo "Cloning the lets encrypt directory..."
	git clone https://github.com/letsencrypt/letsencrypt
fi

cd letsencrypt
###############################################################################
apt-get install nginx-full

mkdir -p /root/keys/letsencrypt
cd /root/keys/letsencrypt

# generating private keys
openssl genrsa -des3 -out example.key 2048

# generating a Certificate Signing Request
openssl req -new -key example.key -out example.csr

# removing passphrase from key

cp example.key example.key.org
openssl rsa -in example.key.org -out example.key
rm example.key.org

# lets generate certificate
openssl x509 -req -days 365 -in example.csr -signkey example.key -out example.crt

# okay lets copy this certificate and key to `/etc/nginx/ssl`

mkdir -p /etc/nginx/ssl/cert/
mkdir -p /etc/nginx/ssl/private/

sudo cp example.crt /etc/nginx/ssl/cert/
sudo cp example.key /etc/nginx/ssl/private/
###############################################################################
cd /root/letsencrypt
# I could have done this without installing nginc using the "standalone server"
# ./letsencrypt --standalone-supported-challenges tls-sni-01

# send the cert 
mkdir -p /root/keys/letsencrypt
cd /root/keys/letsencrypt
/root/letsencrypt/letsencrypt-auto certonly --webroot-path /var/www/html  -d shard05.naturalmessage.com


###############################################################################
# Verify the content of your certificate using a command like this
# (where my cert is in the shard05 directory):
openssl x509 -text -in  /etc/letsencrypt/live/shard05.naturalmessage.com/cert.pem |less

