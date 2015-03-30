#!/bin/sh

usr_id='super'

dir=$(dirname "$0")
src_prefs="${dir}/seamonkey-prefs.js"

prefs=$(find /usr/home/${usr_id}/.mozilla -name 'prefs[.]js')
echo "flist is ${prefs}"

for f in $(echo "${prefs}"); do
	d=$(dirname "${f}")
	echo "copy from ${f} to ${d}"
done
