#!/bin/bash

export SYSROOT=$(pwd)/sysroot
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:${SYSROOT}/lib/pkgconfig
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/${SYSROOT}/lib

export SYSREPOCFG=${SYSROOT}/bin/sysrepocfg

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
    checked git checkout v1.0.109
    popd
fi

if [ ! -d "libredblack" ]; then
    git clone https://github.com/sysrepo/libredblack.git
    pushd libredblack
    popd
fi

if [ ! -d "sysrepo" ]; then
    git clone https://github.com/sysrepo/sysrepo.git
    pushd sysrepo
    checked git checkout v1.3.21
    popd
fi

if [ ! -d "libnetconf2" ]; then
    git clone https://github.com/CESNET/libnetconf2.git
    pushd libnetconf2
    checked git checkout v1.1.3
    popd
fi

if [ ! -d "Netopeer2" ]; then
    git clone https://github.com/CESNET/Netopeer2.git
    pushd Netopeer2
    checked git checkout v1.1.1
    popd
fi

if [ ! -d "sysrepo-plugin-module-versions" ]; then
    git clone https://github.com/kontron/sysrepo-plugin-module-versions.git
fi

echo "############################################################"
echo "#### build libredblack .. $(pwd)"
pushd  libredblack
checked ./configure --prefix=${SYSROOT}
checked make
checked make install
popd # libredblack

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
checked make install
popd # libyang


echo "############################################################"
echo "#### build libnetconf2 .. $(pwd)"
mkdir -p libnetconf2
pushd libnetconf2
checked cmake \
    -DCMAKE_INSTALL_PREFIX=${SYSROOT} \
    -DENABLE_VALGRIND_TESTS=OFF \
    -DENABLE_TLS=ON -DENABLE_SSH=ON \
    ../../sources/libnetconf2
checked make
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


#echo "############################################################"
#echo "#### Netopeer2 .. $(pwd)"
#mkdir -p keystored
#pushd keystored
#echo "############################################################"
#echo "#### build keystored .. $(pwd)"
#checked cmake \
#    -DCMAKE_INSTALL_PREFIX:PATH=${SYSROOT} \
#    -DCMAKE_INSTALL_LIBDIR=lib \
#    -DCMAKE_LIBRARY_PATH:PATH=${SYSROOT}/lib \
#    -DSYSREPO_INCLUDE_DIR:PATH=${SYSROOT}/include \
#    -DSYSREPO_LIBRARY:PATH=${SYSROOT}/lib/libsysrepo.so \
#    -DKEYSTORED_KEYS_DIR=${SYSROOT}/etc/keystored/keys \
#    -DSSH_KEY_INSTALL=ON \
#    ../../sources/Netopeer2/keystored
#checked make
#checked make install
#popd # keystored


echo "############################################################"
echo "#### build netopeer2-server .. $(pwd)"
mkdir -p server
pushd server
checked cmake \
    -DCMAKE_INSTALL_PREFIX=${SYSROOT} \
    -DENABLE_BUILD_TESTS=OFF \
    -DENABLE_VALGRIND_TESTS=OFF \
    -DPIDFILE_PREFIX=${SYSROOT}/var/run \
    ../../sources/Netopeer2/server
checked make
checked make install
popd # server

echo "############################################################"
echo "#### build netopeer2-cli .. $(pwd)"
mkdir -p cli
pushd cli
checked cmake \
    -DCMAKE_INSTALL_PREFIX=${SYSROOT} \
    ../../sources/Netopeer2/cli
checked make
checked make install
popd # cli

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
