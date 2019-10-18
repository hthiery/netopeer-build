#!/bin/bash

export ROOTFS=$(pwd)/rootfs
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:${ROOTFS}/lib/pkgconfig
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/${ROOTFS}/lib

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
    checked git checkout v1.0-r3
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
    checked git checkout v0.7.8
    popd
fi

if [ ! -d "libnetconf2" ]; then
    git clone https://github.com/CESNET/libnetconf2.git
    pushd libnetconf2
    checked git checkout v0.12-r2
    popd
fi

if [ ! -d "Netopeer2" ]; then
    git clone https://github.com/CESNET/Netopeer2.git
    pushd Netopeer2
    checked git checkout v0.7-r2
    popd
fi

echo "############################################################"
echo "#### build libredblack .. $(pwd)"
pushd  libredblack
checked ./configure --prefix=${ROOTFS}
checked make
checked make install
popd # libredblack

echo "############################################################"

popd # sources

mkdir -p build
pushd build

echo "############################################################"
echo "#### build libyang .. $(pwd)"
mkdir -p build-libyang
pushd build-libyang
checked cmake \
    -DCMAKE_INSTALL_PREFIX:PATH=${ROOTFS} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DENABLE_VALGRIND_TESTS:BOOL=OFF \
    -DGEN_PYTHON_BINDINGS:BOOL=OFF \
    ../../sources/libyang
checked make
checked make install
popd # libyang


echo "############################################################"
echo "#### build libnetconf2 .. $(pwd)"
mkdir -p build-libnetconf2
pushd build-libnetconf2
checked cmake \
    -DCMAKE_INSTALL_PREFIX:PATH=${ROOTFS} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_LIBRARY_PATH:PATH=${ROOTFS}/lib \
    -DENABLE_VALGRIND_TESTS:BOOL=OFF \
    -DENABLE_TLS:BOOL=ON -DENABLE_SSH:BOOL=ON \
    ../../sources/libnetconf2
checked make
checked make install
popd


#    -DREDBLACK_INCLUDE_DIR=${ROOTFS}/usr/local/include \
#    -DREDBLACK_LIBRARY=${ROOTFS}/usr/local/lib/libredblack.so \
echo "############################################################"
echo "#### build sysrepo .. $(pwd)"
mkdir -p build-sysrepo
pushd build-sysrepo
checked cmake \
    -DCMAKE_INSTALL_PREFIX:PATH=${ROOTFS} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_LIBRARY_PATH:PATH=${ROOTFS}/lib \
    -DBUILD_EXAMPLES:BOOL=OFF \
    -DBUILD_CPP_EXAMPLES:BOOL=OFF \
    -DENABLE_TESTS:BOOL=OFF \
    -DGEN_PYTHON_BINDINGS:BOOL=OFF \
    -DENABLE_NACM:BOOL=ON \
    -DNACM_RECOVERY_UID:INTEGER=0 \
    -DREPOSITORY_LOC:PATH=${ROOTFS}/etc/sysrepo \
    -DSUBSCRIPTIONS_SOCKET_DIR:PATH=${ROOTFS}/var/run/sysrep-subscriptions \
    -DDAEMON_PID_FILE:PATH=${ROOTFS}/var/run/sysrepod.pid \
    -DDAEMON_SOCKET:PATH=${ROOTFS}/var/run/sysrepod.sock \
    ../../sources/sysrepo
checked make
checked make install
popd


echo "############################################################"
echo "#### Netopeer2 .. $(pwd)"
mkdir -p build-keystored
pushd build-keystored
echo "############################################################"
echo "#### build keystored .. $(pwd)"
checked cmake \
    -DCMAKE_INSTALL_PREFIX:PATH=${ROOTFS} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_LIBRARY_PATH:PATH=${ROOTFS}/lib \
    -DSYSREPO_INCLUDE_DIR:PATH=${ROOTFS}/include \
    -DSYSREPO_LIBRARY:PATH=${ROOTFS}/lib/libsysrepo.so \
    -DSR_PLUGINS_DIR=${ROOTFS}/lib64/sysrepo/plugins \
    -DKEYSTORED_KEYS_DIR=${ROOTFS}/etc/keystored/keys \
    -DSSH_KEY_INSTALL=ON \
    ../../sources/Netopeer2/keystored
checked make
checked make install
popd # build-keystored


echo "############################################################"
echo "#### build server .. $(pwd)"
mkdir -p build-server
pushd build-server
checked cmake \
    -DCMAKE_INSTALL_PREFIX:PATH=${ROOTFS} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_LIBRARY_PATH:PATH=${ROOTFS}/lib \
    -DLIBNETCONF2_LIBRARY=${ROOTFS}/lib/libnetconf2.so \
    -DLIBNETCONF2_INCLUDE_DIR=${ROOTFS}/include \
    -DREDBLACK_INCLUDE_DIR=${ROOTFS}/usr/local/include \
    -DREDBLACK_LIBRARY=${ROOTFS}/usr/local/lib/libredblack.so \
    -DENABLE_BUILD_TESTS:BOOL=OFF \
    -DENABLE_VALGRIND_TESTS:BOOL=OFF \
    -DLIBYANG_INCLUDE_DIR:PATH=${ROOTFS}/include \
    -DLIBYANG_LIBRARY:PATH=${ROOTFS}/lib/libyang.so \
    -DPIDFILE_PREFIX:PATH=${ROOTFS}/var/run \
    ../../sources/Netopeer2/server
checked make
checked make install
popd

echo "############################################################"
echo "#### build cli .. $(pwd)"
mkdir -p build-cli
pushd build-cli
checked cmake \
    -DCMAKE_INSTALL_PREFIX:PATH=${ROOTFS} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DLIBNETCONF2_LIBRARY=${ROOTFS}/lib/libnetconf2.so \
    -DLIBNETCONF2_INCLUDE_DIR=${ROOTFS}/include \
    -DLIBYANG_INCLUDE_DIR:PATH=${ROOTFS}/include \
    -DLIBYANG_LIBRARY:PATH=${ROOTFS}/lib/libyang.so \
    ../../sources/Netopeer2/cli
checked make
checked make install
popd # build-cli

popd # build


echo "############################################################"
echo "#### SUCCESS"
echo "############################################################"
