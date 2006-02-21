#!/bin/bash

# cross-lfs cross-gcc w static libgcc (no threads) build
# ------------------------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}

LOG="gcc-cross-static-no-threads.log"

if [ "Y" = "${MULTIARCH}" ]; then
   vendor_os=`echo ${TARGET} | sed 's@\([^-]*\)-\(.*\)@\2@'`
   case ${TGT_ARCH} in
      x86_64 )
      ;;
      sparc* )
         TARGET=sparc64-${vendor_os}
      ;;
      powerpc* | ppc* )
         TARGET=powerpc64-${vendor_os}
      ;;
      s390* )
         TARGET=s390x-${vendor_os}
      ;;
      mips*el* )
         TARGET=mips64el-${vendor_os}
      ;;
      * )
         # TODO: add some error messages etc
         barf
      ;;
   esac

else
   # If we are not bi-arch, disable multilib
   extra_conf="--enable-multilib=no"

   # HACK: this sets abi to n32 with mips... this should be handled
   # by the multiarch funcs somehow... and set according to DEFAULTENV
   case ${TGT_ARCH} in
      mips* )
         extra_conf="${extra_conf} --with-abi=${DEFAULTENV}"
      ;;
   esac
fi

# if target is same as build host, adjust host slightly to
# trick configure so we do not produce native tools
if [ "${TARGET}" = "${BUILD}" ]; then
   althost=`echo ${BUILD} | sed 's@\([_a-zA-Z0-9]*\)\(-[_a-zA-Z0-9]*\)\(.*\)@\1\2x\3@'`
   extra_conf="--host=${althost} ${extra_conf}"
fi

unpack_tarball gcc-${GCC_VER}

#3.0 20030427
# Cannot trust ${GCC_VER} to supply us with the correct
# gcc version (especially if cvs).
# Grab it straight from version.c
cd ${SRC}/${PKGDIR}
target_gcc_ver=`grep version_string gcc/version.c | \
                sed 's@.* = \(\|"\)\([0-9.]*\).*@\2@g'`
# As of gcc4, the above doesn't cut it... check gcc/BASE-VER
if [ -z "${target_gcc_ver}" -a -f gcc/BASE-VER ]; then
   target_gcc_ver=`cat gcc/BASE-VER`
fi

# Apply linkonce patch for gcc (should be fixed come gcc 3.4.4)
cd ${SRC}/${PKGDIR}
case ${target_gcc_ver} in
   3.4.3 ) apply_patch gcc-3.4.3-linkonce-1
           apply_patch gcc-3.4.0-arm-bigendian
           apply_patch gcc-3.4.0-arm-nolibfloat
           apply_patch gcc-3.4.0-arm-lib1asm
           apply_patch gcc-3.4.3-clean_exec_and_lib_search_paths_when_cross-1
   ;;
   4.0.0 ) apply_patch gcc-4.0.0-fix_tree_optimisation_PR21173
           apply_patch gcc-4.0.0-reload_check_uninitialized_pseudos_PR20973
           apply_patch gcc-4.0.0-clean_exec_and_lib_search_paths_when_cross-1
   ;;
esac

# if we are using gcc-3.4x, set libexecdir to */${libdirname}
case ${target_gcc_ver} in
   3.4* | 4.* )
      extra_conf="${extra_conf} --libexecdir=${HST_TOOLS}/${libdirname}"
   ;;
esac

# for some reason the build breaks in the absence of any target glibc headers if
# a sysroot is used. 
if [ ! "${USE_SYSROOT}" = "Y" ]; then
   # LFS style build
   #----------------

   # source functions for required gcc modifications
   . ${SCRIPTS}/funcs/cross_gcc-funcs.sh

   # Alter the generated specs file to 
   #  o set dynamic linker to be under ${TGT_TOOLS}/lib{,32,64}
   #  o set startfile_prefix_spec so we search for startfiles
   #    under ${TGT_TOOLS}/lib/lib{,32,64}
   gcc_specs_mod

   # Set cpp's default include search path, and the header search path 
   # used by fixincludes to be ${TGT_TOOLS}/include
   cpp_set_cross_system_header_dir
fi

test -d ${SRC}/gcc-${GCC_VER}-cross-static-no-threads &&
   rm -rf ${SRC}/gcc-${GCC_VER}-cross-static-no-threads

mkdir -p ${SRC}/gcc-${GCC_VER}-cross-static-no-threads &&
cd ${SRC}/gcc-${GCC_VER}-cross-static-no-threads

# initial run does not produce a libgcc_eh.a, nor 
# libgcc_s.so, gcc_eh objects are packed into the standard libgcc.a .
# We'd need crt[i1n].o to build these.
#
# Unfortunately glibc requires we have libgcc_eh.a for building against
# 

# NOTE:
# Some errors occur on solaris where bash syntax is used with a
# standard /bin/sh ( ie: expecting $(command) to be evaluated )
# To avoid this issue we override make's default shell with
# /bin/bash
# This is done via passing CONFIG_SHELL=/bin/bash to
# configure, which uses this when it specifies SHELL in 
# the Makefiles.
 
max_log_init Gcc ${GCC_VER} cross-pt1 ${CONFLOGS} ${LOG}
#CONFIG_SHELL=/bin/bash \
CFLAGS="-O2 ${HOST_CFLAGS} -pipe" \
../${PKGDIR}/configure --prefix=${HST_TOOLS} \
   --target=${TARGET} ${extra_conf} \
   --with-local-prefix=${TGT_TOOLS} --enable-languages=c \
   --disable-nls --disable-shared --disable-threads \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf

min_log_init ${BUILDLOGS} &&
#make ${PMFLAGS} BOOT_CFLAGS="-O2 ${HOST_CFLAGS} -pipe" \
 #  STAGE1_CFLAGS="-O ${HOST_CFLAGS} -pipe" all-gcc \
make all-gcc \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${INSTLOGS} &&
make install-gcc \
   >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

