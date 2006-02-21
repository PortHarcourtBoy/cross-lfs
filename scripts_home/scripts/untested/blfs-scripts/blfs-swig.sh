#!/bin/bash

### swig ###

cd ${SRC}
LOG=swig-blfs.log

set -x
set_libdirname
set +x
setup_multiarch

unpack_tarball swig-${SWIG_VER}
cd ${PKGDIR}

echo ${libdirname}

echo ${DEFAULTENV} 

sed -i "s@PYLIBDIR=\"lib\"@PYLIBDIR=\"${libdirname}\"@g" configure
echo "JAVA_HOME ${JAVA_HOME} ${BUILDENV}"

# TODO: ensure swig looks in lib64 for python libs...
# NOTE: only diff between 32 and 64 builds is the swig binary itself
#       we may need to install both -32 and -64, but I'm not too sure

max_log_init swig ${SWIG_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr \
   --with-tclconfig=/usr/${libdirname} \
   --with-java=${JAVA_HOME}/bin \
   --with-javaincl=${JAVA_HOME}/include \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

