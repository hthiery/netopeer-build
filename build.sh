#!/bin/bash


LIBYANG_VERSION="v2.0.194"
SYSREPO_VERSION="v2.1.64"
LIBNETCONF2_VERSION="v2.1.11"
NETOPEER2_VERSION="v2.1.23"

export SYSROOT=$(pwd)/sysroot
export PKG_CONFIG_PATH=${SYSROOT}/lib/pkgconfig
export LD_LIBRARY_PATH=${SYSROOT}/lib


echo "SYSROOT=${SYSROOT}"
echo "PKG_CONFIG_PATH=${PKG_CONFIG_PATH}"
echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"

export SYSREPOCFG=${SYSROOT}/bin/sysrepocfg
export PATH=${SYSROOT}/bin/:${PATH}

checked () {
    CMD=$*
    $CMD
    if [ $? -ne 0 ]; then
        echo "$CMD: error"
        exit 1
    fi
}

mkdir -p sources
pushd sources

if [ ! -d "libyang" ]; then
    git clone https://github.com/CESNET/libyang.git
    pushd libyang
    checked git checkout ${LIBYANG_VERSION}
    popd
fi

if [ ! -d "sysrepo" ]; then
    git clone https://github.com/sysrepo/sysrepo.git
    pushd sysrepo
    checked git checkout ${SYSREPO_VERSION}
    popd
fi

if [ ! -d "libnetconf2" ]; then
    git clone https://github.com/CESNET/libnetconf2.git
    pushd libnetconf2
    checked git checkout ${LIBNETCONF2_VERSION}
    popd
fi

if [ ! -d "Netopeer2" ]; then
    git clone https://github.com/CESNET/Netopeer2.git
    pushd Netopeer2
    checked git checkout ${NETOPEER2_VERSION}
    popd
fi

#if [ ! -d "sysrepo-plugin-module-versions" ]; then
#    git clone https://github.com/kontron/sysrepo-plugin-module-versions.git
#fi

echo "############################################################"

popd # sources

# This is required for temporarily installation process
# The files in /dev/shm/ are automatically created and will conflict with other
# instances. So create these one with a prefix and do a cleanup later on.
SHM_PREFIX=$(mktemp -uq)
echo "SHM_PREFIX=$SHM_PREFIX"
SHM_PREFIX=$(basename ${SHM_PREFIX})
echo "SHM_PREFIX=$SHM_PREFIX"
export SYSREPO_SHM_PREFIX=${SHM_PREFIX}

mkdir -p build
pushd build

echo "############################################################"
echo "#### build libyang .. $(pwd)"
mkdir -p libyang
pushd libyang
checked cmake \
    -DCMAKE_INSTALL_PREFIX=${SYSROOT} \
    -DENABLE_VALGRIND_TESTS=OFF \
	-DENABLE_TESTS=OFF \
    ../../sources/libyang
checked make
#checked make doc
checked make install
popd # libyang

echo "############################################################"
echo "#### build sysrepo .. $(pwd)"
mkdir -p sysrepo
pushd sysrepo
checked cmake \
	-DCMAKE_INCLUDE_PATH=${SYSROOT}/include \
	-DCMAKE_LIBRARY_PATH=${SYSROOT}/lib \
    -DCMAKE_INSTALL_PREFIX=${SYSROOT} \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_CPP_EXAMPLES=OFF \
    -DENABLE_TESTS=OFF \
    -DGEN_PYTHON_BINDINGS=OFF \
    -DENABLE_NACM=ON \
    -DNACM_RECOVERY_UID=0 \
    -DREPOSITORY_LOC=${SYSROOT}/etc/sysrepo \
    -DSUBSCRIPTIONS_SOCKET_DIR=${SYSROOT}/var/run/sysrep-subscriptions \
    -DDAEMON_PID_FILE=${SYSROOT}/var/run/sysrepod.pid \
    -DDAEMON_SOCKET=${SYSROOT}/var/run/sysrepod.sock \
	-DENABLE_TESTS=OFF \
    ../../sources/sysrepo
checked make
#checked make doc
checked make install
popd # sysrepo

echo "############################################################"
echo "#### build libnetconf2 .. $(pwd)"
mkdir -p libnetconf2
pushd libnetconf2
checked cmake \
	-DCMAKE_INCLUDE_PATH=${SYSROOT}/include \
	-DCMAKE_LIBRARY_PATH=${SYSROOT}/lib \
    -DCMAKE_INSTALL_PREFIX=${SYSROOT} \
    -DENABLE_VALGRIND_TESTS=OFF \
    -DENABLE_TLS=ON \
	-DENABLE_SSH=ON \
	-DENABLE_TESTS=OFF \
    ../../sources/libnetconf2
checked make
#checked make doc
checked make install
popd # libnetconf2


#    -DREDBLACK_INCLUDE_DIR=${SYSROOT}/usr/local/include \
#    -DREDBLACK_LIBRARY=${SYSROOT}/usr/local/lib/libredblack.so \



echo "############################################################"
echo "#### build netopeer2-server .. $(pwd)"


mkdir -p netopeer2
pushd netopeer2
checked cmake \
	-DCMAKE_INCLUDE_PATH=${SYSROOT}/include \
	-DCMAKE_LIBRARY_PATH=${SYSROOT}/lib \
    -DCMAKE_INSTALL_PREFIX=${SYSROOT} \
    -DENABLE_BUILD_TESTS=OFF \
    -DENABLE_VALGRIND_TESTS=OFF \
	-DENABLE_TESTS=OFF \
    -DBUILD_CLI=ON \
    -DPIDFILE_PREFIX=${SYSROOT}/var/run \
    ../../sources/Netopeer2
checked make
checked make install
rm -f /dev/shm/$(SHM_PREFIX)*
popd # netopeer2

#echo "############################################################"
#echo "#### build sysrepo-plugin-module-versions .. $(pwd)"
#mkdir -p sysrepo-plugin-module-versions
#pushd sysrepo-plugin-module-versions
#checked cmake \
#    -DCMAKE_INSTALL_PREFIX=${SYSROOT} \
#    -DCMAKE_INSTALL_LIBDIR=lib \
#    -DCMAKE_LIBRARY_PATH=${SYSROOT}/lib \
#    -DSYSREPO_INCLUDE_DIR=${SYSROOT}/include \
#    -DSYSREPO_LIBRARY=${SYSROOT}/lib/libsysrepo.so \
#    ../../sources/sysrepo-plugin-module-versions
#checked make
#checked make install
#popd # sysrepo-plugin-module-versions

popd # build


#echo "############################################################"
#echo "#### Server configuration"
#echo "############################################################"
#checked ${SYSREPOCFG} -d startup -m sources/Netopeer2/server/configuration/load_server_certs.xml ietf-keystore
#checked ${SYSREPOCFG} -d startup -m sources/Netopeer2/server/configuration/tls_listen.xml ietf-netconf-server
#checked cp sources/Netopeer2/server/configuration/tls/server.key ${SYSROOT}/etc/keystored/keys/test_server_key.pem
#checked chmod 600 ${SYSROOT}/etc/keystored/keys/test_server_key.pem


# Do the cleanup
checked mkdir -p ${SYSROOT}/var/run

echo "############################################################"
echo "#### SUCCESS"
echo "############################################################"
