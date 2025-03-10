#!/bin/bash
TOP_DIR=$(dirname $(realpath ${BASH_SOURCE}))

LIBNAME=${LIBNAME=""}
if test $# -ge 1; then
    LIBNAME=$1
fi

PLATFORM_TARGET=${PLATFORM_TARGET=arm-linux-gnueabihf}

COMMON_SCRIPTS_DIR=${TOP_DIR}/scripts
PLATFORM_DIR=${TOP_DIR}/platform_${PLATFORM_TARGET}
THIRDPARTY_SRC_DIR=${THIRDPARTY_SRC_DIR=${TOP_DIR}/sources}
BUILD_DIR_NAME=build_${PLATFORM_TARGET}

if test -e ${PLATFORM_DIR}/toolchain_env.sh; then
    source ${PLATFORM_DIR}/toolchain_env.sh
fi

find . -maxdepth 1 -iname "*${LIBNAME}.conf" | while read CONF; do
    if test -e "${CONF}"; then
        source ${CONF}
    fi
    if test -e "${CONF}.${PLATFORM_TARGET}"; then
        source ${CONF}.${PLATFORM_TARGET}
    fi
    # INSTALL_SUBDIR="/${LIBNAME}"
    source ${COMMON_SCRIPTS_DIR}/lib_compile.sh
done
