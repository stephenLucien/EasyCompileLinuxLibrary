#!/bin/bash

TOOLCHAIN_TRIPLE=
if test -n "${TOOLCHAIN_TRIPLE}"; then
    TOOLCHAIN_PREFIX="${TOOLCHAIN_TRIPLE}-"
    CROSS_COMPILE="${TOOLCHAIN_TRIPLE}-"
fi

CC=${TOOLCHAIN_PREFIX}gcc
CXX=${TOOLCHAIN_PREFIX}g++
AR=${TOOLCHAIN_PREFIX}ar
RANLIB=${TOOLCHAIN_PREFIX}ranlib
ADDR2LINE=${TOOLCHAIN_PREFIX}addr2line


SYSROOT=$(${CC} -print-sysroot)

CFLAGS=
CXXFLAGS=

INCLUDES=
CPPFLAGS=

LDFLAGS=
LIBS=
