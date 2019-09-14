export ROOTFS=$(pwd)/rootfs
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:${ROOTFS}/usr/lib/pkgconfig
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/${ROOTFS}/usr/lib/

checked () {
    CMD=$*
    $CMD
    if [ $? -ne 0 ]; then
        echo "$CMD: error"
        exit 1
    fi
}

if [ ! -d "libyang" ]; then
    git clone https://github.com/CESNET/libyang.git
    pushd libyang
    checked git checkout v1.0-r3 -b v1.0-r3
    popd
fi

if [ ! -d "sysrepo" ]; then
    git clone https://github.com/sysrepo/sysrepo.git
    pushd sysrepo
    checked git checkout  v0.7.8 -b v0.7.8
    popd
fi

if [ ! -d "libnetconf2" ]; then
    git clone https://github.com/CESNET/libnetconf2.git
    pushd libnetconf2
    checked git checkout  v0.12-r2 -b v0.12-r2
    popd
fi

if [ ! -d "Netopeer2" ]; then
    git clone https://github.com/CESNET/Netopeer2.git
    pushd Netopeer2
    checked git checkout  v0.7-r2 -b v0.7-r2
    popd
fi

pushd libyang
echo "############################################################"
echo "#### build libyang .. $(pwd)"
mkdir -p build
pushd build
checked cmake \
    -DCMAKE_INSTALL_PREFIX:PATH=${ROOTFS}/usr \
    -DCMAKE_BUILD_TYPE:String=Release \
    -DENABLE_VALGRIND_TESTS:BOOL=OFF \
    -DGEN_PYTHON_BINDINGS:BOOL=OFF \
    ..
checked make
checked make install
popd # build
popd # libyang

pushd libnetconf2
echo "############################################################"
echo "#### build libnetconf2 .. $(pwd)"
mkdir -p build
pushd build
checked cmake \
    -DCMAKE_INSTALL_PREFIX:PATH=${ROOTFS}/usr \
    -DCMAKE_LIBRARY_PATH:PATH=${ROOTFS}/usr/lib \
    -DCMAKE_BUILD_TYPE:String=Release \
    -DENABLE_VALGRIND_TESTS:BOOL=OFF \
    -DENABLE_TLS:BOOL=ON -DENABLE_SSH:BOOL=ON \
    ..
checked make
checked make install
popd
popd


pushd sysrepo
echo "############################################################"
echo "#### build sysrepo .. $(pwd)"
mkdir -p build
pushd build
checked cmake \
    -DCMAKE_INSTALL_PREFIX:PATH=${ROOTFS}/usr \
    -DCMAKE_LIBRARY_PATH:PATH=${ROOTFS}/usr/lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_EXAMPLES:BOOL=OFF \
    -DBUILD_CPP_EXAMPLES:BOOL=OFF \
    -DENABLE_TESTS:BOOL=OFF \
    -DGEN_PYTHON_BINDINGS:BOOL=OFF \
    -DENABLE_NACM:BOOL=ON \
    -DNACM_RECOVERY_UID:INTEGER=0 \
    -DREPOSITORY_LOC:PATH=${ROOTFS}/usr/etc/sysrepo \
    -DSUBSCRIPTIONS_SOCKET_DIR:PATH=${ROOTFS}/var/run/sysrep-subscriptions \
    -DDAEMON_PID_FILE:PATH=${ROOTFS}/var/run/sysrepod.pid \
    -DDAEMON_SOCKET:PATH=${ROOTFS}/var/run/sysrepod.sock \
    ..
checked make
checked make install
popd
popd

pushd Netopeer2

echo "############################################################"
echo "#### Netopeer2 .. $(pwd)"
mkdir -p build-keystored
pushd build-keystored
echo "############################################################"
echo "#### build keystored .. $(pwd)"
checked cmake \
    -DCMAKE_INSTALL_PREFIX:PATH=${ROOTFS}/usr \
    -DCMAKE_LIBRARY_PATH:PATH=${ROOTFS}/usr/lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DSYSREPO_INCLUDE_DIR:PATH=${ROOTFS}/usr/include \
    -DSYSREPO_LIBRARY:PATH=${ROOTFS}/usr/lib/libsysrepo.so \
    ../keystored
checked make
checked make install
popd # build-keystored


mkdir -p build-server
pushd build-server
echo "############################################################"
echo "#### build server .. $(pwd)"
checked cmake \
    -DCMAKE_INSTALL_PREFIX:PATH=${ROOTFS}/usr \
    -DCMAKE_LIBRARY_PATH:PATH=${ROOTFS}/usr/lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DLIBNETCONF2_LIBRARY=${ROOTFS}/usr/lib/libnetconf2.so \
    -DLIBNETCONF2_INCLUDE_DIR=${ROOTFS}/usr/include/ \
    -DENABLE_BUILD_TESTS:BOOL=OFF \
    -DENABLE_VALGRIND_TESTS:BOOL=OFF \
    -DLIBYANG_INCLUDE_DIR:PATH=${ROOTFS}/usr/include/ \
    -DLIBYANG_LIBRARY:PATH=${ROOTFS}/usr/lib/libyang.so \
    -DPIDFILE_PREFIX:PATH=${ROOTFS}/var/run \
    ../server
checked make
checked make install
popd # build-server

mkdir -p build-cli
pushd build-cli
echo "############################################################"
echo "#### build cli .. $(pwd)"
checked cmake \
    -DCMAKE_INSTALL_PREFIX:PATH=${ROOTFS}/usr \
    -DCMAKE_LIBRARY_PATH:PATH=${ROOTFS}/usr/lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DLIBNETCONF2_LIBRARY=${ROOTFS}/usr/lib/libnetconf2.so \
    -DLIBNETCONF2_INCLUDE_DIR=${ROOTFS}/usr/include/ \
    -DLIBYANG_INCLUDE_DIR:PATH=${ROOTFS}/usr/include/ \
    -DLIBYANG_LIBRARY:PATH=${ROOTFS}/usr/lib/libyang.so \
    ../cli
checked make
checked make install
popd # build-cli

popd # notopeer


