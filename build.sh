#!/bin/bash

export SYSROOT=$(pwd)/sysroot
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:${SYSROOT}/lib/pkgconfig
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/${SYSROOT}/lib

export SYSREPOCFG=${SYSROOT}/bin/sysrepocfg
export PATH=${SYSROOT}/bin/:$PATH

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
    checked git checkout v1.0.176
    popd
fi

if [ ! -d "sysrepo" ]; then
    git clone https://github.com/sysrepo/sysrepo.git
    pushd sysrepo
    checked git checkout v1.4.66
    popd
fi

if [ ! -d "libnetconf2" ]; then
    git clone https://github.com/CESNET/libnetconf2.git
    pushd libnetconf2
    checked git checkout v1.1.26
    popd
fi

if [ ! -d "Netopeer2" ]; then
    git clone https://github.com/CESNET/Netopeer2.git
    pushd Netopeer2
    checked git checkout v1.1.34
    popd
fi

#if [ ! -d "sysrepo-plugin-module-versions" ]; then
#    git clone https://github.com/kontron/sysrepo-plugin-module-versions.git
#fi

echo "############################################################"

popd # sources

mkdir -p build
pushd build

echo "############################################################"
echo "#### build libyang .. $(pwd)"
mkdir -p libyang
pushd libyang
checked cmake \
    -DCMAKE_INSTALL_PREFIX=${SYSROOT} \
    -DENABLE_VALGRIND_TESTS=OFF \
    -DGEN_PYTHON_BINDINGS=OFF \
    ../../sources/libyang
checked make
checked make doc
checked make install
popd # libyang


echo "############################################################"
echo "#### build libnetconf2 .. $(pwd)"
mkdir -p libnetconf2
pushd libnetconf2
checked cmake \
    -DCMAKE_INSTALL_PREFIX=${SYSROOT} \
    -DENABLE_VALGRIND_TESTS=OFF \
    -DENABLE_TLS=ON \
	-DENABLE_SSH=ON \
    ../../sources/libnetconf2
checked make
checked make doc
checked make install
popd # libnetconf2


#    -DREDBLACK_INCLUDE_DIR=${SYSROOT}/usr/local/include \
#    -DREDBLACK_LIBRARY=${SYSROOT}/usr/local/lib/libredblack.so \
echo "############################################################"
echo "#### build sysrepo .. $(pwd)"
mkdir -p sysrepo
pushd sysrepo
checked cmake \
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
    ../../sources/sysrepo
checked make
checked make install
popd # sysrepo


echo "############################################################"
echo "#### build netopeer2-server .. $(pwd)"
mkdir -p netopeer2
pushd netopeer2
checked cmake \
    -DCMAKE_INSTALL_PREFIX=${SYSROOT} \
    -DENABLE_BUILD_TESTS=OFF \
    -DENABLE_VALGRIND_TESTS=OFF \
    -DBUILD_CLI=ON \
    -DPIDFILE_PREFIX=${SYSROOT}/var/run \
    ../../sources/Netopeer2
checked make
checked make install
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

echo "############################################################"
echo "#### SUCCESS"
echo "############################################################"
