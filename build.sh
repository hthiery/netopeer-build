#!/bin/bash


#LIBYANG_VERSION="v2.1.4"
##SYSREPO_VERSION="v2.2.105"
#LIBNETCONF2_VERSION="v2.1.25"
##NETOPEER2_VERSION="v2.1.71"
#LIBSSH_VERSION="libssh-0.11.1"

LIBYANG_VERSION="v2.1.111"
SYSREPO_VERSION="v2.2.105"
LIBNETCONF2_VERSION="v2.1.37"
NETOPEER2_VERSION="v2.1.71"
LIBSSH_VERSION="libssh-0.11.1"

export SOURCES=$(pwd)/sources
export BUILD=$(pwd)/build
export SYSROOT=$(pwd)/sysroot
export PKG_CONFIG_PATH=${SYSROOT}/lib/pkgconfig
export LD_LIBRARY_PATH=${SYSROOT}/lib


echo "SOURCES=${SOURCES}"
echo "BUILD=${BUILD}"
echo "SYSROOT=${SYSROOT}"
echo "PKG_CONFIG_PATH=${PKG_CONFIG_PATH}"
echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"

export SYSREPOCFG=${SYSROOT}/bin/sysrepocfg
export PATH=${SYSROOT}/bin/:${PATH}

CPUS=$(nproc)

mkdir -p $SOURCES
mkdir -p $BUILD
mkdir -p $SYSROOT

checked () {
    CMD=$*
    $CMD
    if [ $? -ne 0 ]; then
        echo "$CMD: error"
        exit 1
    fi
}

################################################################################
# get sources
################################################################################

function get_libyang() {
	pushd $SOURCES
	if [ ! -d "libyang" ]; then
	    git clone https://github.com/CESNET/libyang.git
	    pushd libyang
	    checked git checkout ${LIBYANG_VERSION} -b ${LIBYANG_VERSION}
	    popd
	fi
	popd
}

function get_sysrepo() {
	pushd $SOURCES
	if [ ! -d "sysrepo" ]; then
	    git clone https://github.com/sysrepo/sysrepo.git
	    pushd sysrepo
	    checked git checkout ${SYSREPO_VERSION} -b ${SYSREPO_VERSION}
	    popd
	fi
	popd
}

function get_libnetconf2() {
	pushd $SOURCES
	if [ ! -d "libnetconf2" ]; then
	    git clone https://github.com/CESNET/libnetconf2.git
	    pushd libnetconf2
	    checked git checkout ${LIBNETCONF2_VERSION} -b ${LIBNETCONF2_VERSION}
	    popd
	fi
	popd
}

function get_netopeer2() {
	pushd $SOURCES
	if [ ! -d "Netopeer2" ]; then
	    git clone https://github.com/CESNET/Netopeer2.git
	    pushd Netopeer2
	    checked git checkout ${NETOPEER2_VERSION} -b ${NETOPEER2_VERSION}
	    popd
	fi
	popd
}

function get_libssh() {
	pushd $SOURCES
	if [ ! -d "libssh" ]; then
	    git clone https://git.libssh.org/projects/libssh.git
	    pushd libssh
	    checked git checkout ${LIBSSH_VERSION} -b ${LIBSSH_VERSION}
	    popd
	fi
	popd
}

#if [ ! -d "sysrepo-plugin-module-versions" ]; then
#    git clone https://github.com/kontron/sysrepo-plugin-module-versions.git
#fi

echo "############################################################"

# This is required for temporarily installation process
# The files in /dev/shm/ are automatically created and will conflict with other
# instances. So create these one with a prefix and do a cleanup later on.
SHM_PREFIX=$(mktemp -uq)
echo "SHM_PREFIX=$SHM_PREFIX"
SHM_PREFIX=$(basename ${SHM_PREFIX})
echo "SHM_PREFIX=$SHM_PREFIX"
export SYSREPO_SHM_PREFIX=${SHM_PREFIX}

function build_libssh() {
	pushd $BUILD
	echo "############################################################"
	echo "#### build libssh .. $(pwd)"
	echo "############################################################"
	mkdir -p libssh
	pushd libssh
	checked cmake \
		-DCMAKE_INCLUDE_PATH=${SYSROOT}/include \
		-DCMAKE_LIBRARY_PATH=${SYSROOT}/lib \
		-DCMAKE_INSTALL_PREFIX=${SYSROOT} \
		-DWITH_EXAMPLES=OFF \
		../../sources/libssh
	checked make -j${CPUS}
	checked make install
	popd # libssh
	popd
}


function build_libyang() {
	pushd $BUILD
	echo "############################################################"
	echo "#### build libyang .. $(pwd)"
	echo "############################################################"
	mkdir -p libyang
	pushd libyang
	checked cmake \
	    -DCMAKE_INSTALL_PREFIX=${SYSROOT} \
	    -DENABLE_VALGRIND_TESTS=OFF \
		-DENABLE_TESTS=OFF \
		-DWITH_SERVER=ON \
	    ../../sources/libyang
	checked make -j${CPUS}
	#checked make doc
	checked make install
	popd # libyang
	popd
}


function build_libnetconf2() {
	pushd $BUILD
	echo "############################################################"
	echo "#### build libnetconf2 .. $(pwd)"
	echo "############################################################"
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
	checked make -j${CPUS} VERBOSE=1
	#checked make doc
	checked make install
	popd # libnetconf2
	popd
}


function build_sysrepo() {
	pushd $BUILD
	echo "############################################################"
	echo "#### build sysrepo .. $(pwd)"
	echo "############################################################"
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
	checked make -j${CPUS}
	#checked make doc
	checked make install
	popd # sysrepo
	popd
}


function build_netopeer2() {
	pushd $BUILD
	echo "############################################################"
	echo "#### build netopeer2-server .. $(pwd)"
	echo "############################################################"
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
	checked make -j${CPUS}
	checked make install
	rm -f /dev/shm/${SHM_PREFIX}*
	popd # netopeer2
	popd
}

get_libssh
get_libyang
get_sysrepo
get_libnetconf2
get_netopeer2

build_libssh
build_libyang
build_libnetconf2
build_sysrepo
build_netopeer2


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
