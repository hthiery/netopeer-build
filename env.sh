P=$(realpath ${BASH_SOURCE})
P=$(dirname "${P}")
SYSROOT=${P}/sysroot

export PATH=${SYSROOT}/bin:${PATH}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${SYSROOT}/lib
export PKG_CONFIG_PATH=${PKG_CONFIG_PATH}:${SYSROOT}/lib/pkgconfig
