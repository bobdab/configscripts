#!/bin/sh
pkg_check

## add to /etc/mk.conf
#USE_SYSTRACE=YES

export PKG_PATH=ftp://ftp.openbsd.org/pub/OpenBSD/5.6/packages/`machine -a`/

pkg_add wget

pkg_add lynx
