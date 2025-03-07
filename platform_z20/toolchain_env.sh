#!/bin/bash
PLATFORM_DIR=$(dirname $(realpath ${BASH_SOURCE}))

TOOLCHAIN_DIR=${PLATFORM_DIR}/toolchain
TOOLCHAIN_BIN_DIR=${TOOLCHAIN_DIR}/bin

TOOLCHAIN_TRIPLE=arm-linux-gnueabihf

SYSTEM_NAME=Linux

SYSTEM_PROCESSOR=arm

CFLAGS="-mfloat-abi=hard -mfpu=vfp"
CFLAGS="${CFLAGS} -fPIC"
CFLAGS="${CFLAGS} -fdata-sections -ffunction-sections"
# CFLAGS="${CFLAGS} -fno-omit-frame-pointer"
# CFLAGS="${CFLAGS} -save-temps=obj"
# CFLAGS="${CFLAGS} -Wno-unused-result -Wno-unused-but-set-variable -Wno-unused-but-set-parameter -Wno-unused-variable -Wno-unused-parameter -Wno-unused-label -Wno-unused-function"
# CFLAGS="${CFLAGS} -O2"
# CFLAGS="${CFLAGS} -static"

CXXFLAGS=${CXXFLAGS="${CFLAGS} -fexceptions"}

LDFLAGS="-Wl,--gc-sections"

LIBS=""

# EXPORT_TOOLCHAIN=false
source ${PLATFORM_DIR}/../scripts/env_template_for_toolchain.sh
