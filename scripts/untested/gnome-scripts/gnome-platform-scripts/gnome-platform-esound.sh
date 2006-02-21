#!/bin/bash

### esound ###

cd ${SRC}
LOG=esound-gnome-platform.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

# override TARBALLS to point at gnome/platform tree
GNOME_REL_MAJ=`echo ${GNOME_REL} | sed 's@\([0-9]*\.[0-9]*\).*@\1@g'`
export TARBALLS=${GNOME_TARBALLS}/platform/${GNOME_REL_MAJ}/${GNOME_REL}/sources

unpack_tarball esound-${ESOUND_VER}
cd ${PKGDIR}

max_log_init esound ${ESOUND_VER} "gnome-platform (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
LDFLAGS="-L/usr/${libdirname}" \
./configure --prefix=/usr --sysconfdir=/etc ${extra_conf} \
   --with-libwrap \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

# TODO: need to patch generated libtool...
#      $max_cmd_len doesn't appear to be defined...
#      proper fix would be to patch ltmain.sh
apply_patch  esound-0.2.35-libtool_skip_max_cmd_len-1

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

if [ "Y" = "${MULTIARCH}" ]; then
   use_wrapper /usr/bin/esd-config
fi
