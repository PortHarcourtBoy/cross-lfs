#!/bin/bash

### gnome-mime-data ###

cd ${SRC}
LOG=gnome-mime-data-gnome-platform.log

set_buildenv
set_libdirname
setup_multiarch
# *sigh* doing this just so we end up with 2 .pc files...
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=${GNOME_PREFIX}/${libdirname}"
fi

if [ "${GNOME_PREFIX}" = "/usr" ]; then
   extra_conf="${extra_conf} --sysconfdir=/etc/gnome"
fi

# override TARBALLS to point at gnome/platform tree
GNOME_REL_MAJ=`echo ${GNOME_REL} | sed 's@\([0-9]*\.[0-9]*\).*@\1@g'`
export TARBALLS=${GNOME_TARBALLS}/platform/${GNOME_REL_MAJ}/${GNOME_REL}/sources

unpack_tarball gnome-mime-data-${GNOME_MIME_DATA_VER}
cd ${PKGDIR}

# TODO: does this use g++
max_log_init gnome-mime-data ${GNOME_MIME_DATA_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
./configure --prefix=${GNOME_PREFIX} ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

