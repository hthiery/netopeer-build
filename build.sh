export ROOTFS=$(pwd)/rootfs
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:${ROOTFS}/usr/lib/pkgconfig
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/${ROOTFS}/usr/lib/

if [ ! -d "libyang" ]; then
    git clone https://github.com/CESNET/libyang.git
    pushd libyang
    git checkout v1.0-r3 -b v1.0-r3
    popd
fi

if [ ! -d "sysrepo" ]; then
    git clone https://github.com/sysrepo/sysrepo.git
    pushd sysrepo
    git checkout  v0.7.8 -b v0.7.8
    popd
fi

if [ ! -d "libnetconf2" ]; then
    git clone https://github.com/CESNET/libnetconf2.git
    pushd libnetconf2
    git checkout  v0.12-r2 -b v0.12-r2
    popd
fi

if [ ! -d "Netopeer2" ]; then
    git clone https://github.com/CESNET/Netopeer2.git
    pushd Netopeer2
    git checkout  v0.7-r2 -b v0.7-r2
    popd
fi

pushd libyang
echo "############################################################"
echo "#### build libyang .. $(pwd)"
mkdir -p build
pushd build
cmake -DCMAKE_INSTALL_PREFIX:PATH=${ROOTFS}/usr \
    -DENABLE_VALGRIND_TESTS:BOOL=OFF \
    -DGEN_PYTHON_BINDINGS:BOOL=OFF \
    ..
make
make install
popd # build
popd # libyang

pushd libnetconf2
echo "############################################################"
echo "#### build libnetconf2 .. $(pwd)"
mkdir -p build
pushd build
cmake -DENABLE_VALGRIND_TESTS:BOOL=OFF \
    -DCMAKE_INSTALL_PREFIX:PATH=${ROOTFS}/usr \
    -DENABLE_TLS:BOOL=ON -DENABLE_SSH:BOOL=ON \
    -DCMAKE_BUILD_TYPE:String=Release \
    ..
make
make install
popd
popd


pushd sysrepo
mkdir -p build
pushd build
cmake -DENABLE_TESTS:BOOL=OFF \
    -DBUILD_EXAMPLES:BOOL=OFF \
    -DBUILD_CPP_EXAMPLES:BOOL=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DGEN_PYTHON_BINDINGS:BOOL=OFF \
    -DCMAKE_INSTALL_PREFIX:PATH=${ROOTFS}/usr \
    -DENABLE_NACM:BOOL=ON \
    -DNACM_RECOVERY_UID:INTEGER=0 \
    -DREPOSITORY_LOC:PATH=${ROOTFS}/etc/sysrepo \
    -DSUBSCRIPTIONS_SOCKET_DIR:PATH=${ROOTFS}/var/run/sysrep-subscriptions \
    ..
make
make install
popd
popd

pushd Netopeer2

pushd keystored
mkdir -p build
pushd build
echo "############################################################"
echo "#### build keystored .. $(pwd)"
cmake -DSYSREPO_LIBRARY:PATH=${ROOTFS}/usr/lib \
    -DSYSREPO_INCLUDE_DIR:PATH=${ROOTFS}/usr/include \
    -DCMAKE_INSTALL_PREFIX:PATH=${ROOTFS}/usr \
    ..
make
make install
popd # build
popd # keystored


pushd server
mkdir -p build
pushd build
echo "############################################################"
echo "#### build server .. $(pwd)"
cmake  -DLIBNETCONF2_LIBRARY=${ROOTFS}/usr/lib \
    -DCMAKE_LIBRARY_PATH:PATH=${ROOTFS}/usr/lib \
    -DLIBNETCONF2_INCLUDE_DIR=${ROOTFS}/usr/include/ \
    -DCMAKE_INSTALL_PREFIX:PATH=${ROOTFS}/usr \
    -DENABLE_BUILD_TESTS:BOOL=OFF \
    -DENABLE_VALGRIND_TESTS:BOOL=OFF \
    -DLIBYANG_INCLUDE_DIR:PATH=${ROOTFS}/usr/include/ \
    -DLIBYANG_LIBRARY:PATH=${ROOTFS}/usr/lib/ \
    ..
make
make install
popd # build
popd # server
popd # notopeer
