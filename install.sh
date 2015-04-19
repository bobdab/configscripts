#!/bin/sh

rm master.tar.gz
rm master.tar

wget --no-check-certificate https://github.com/bobdab/configscripts/archive/master/tar.gz


gunzip master.tar.gz

tar -xf master.tar
cd configscripts-master

