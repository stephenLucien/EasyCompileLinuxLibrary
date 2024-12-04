#!/bin/bash
ENV_DIR=$(dirname $(realpath ${BASH_SOURCE}))
ENV_EXPORT=${ENV_EXPORT=true}

SYSTEM_NAME=$(uname)
SYSTEM_PROCESSOR=AMD64

# makefile
MAKE="make"

# cmake
CMAKE_GENERATOR="Ninja"
GENERATOR=ninja
CMAKE_TOOLCHAIN_FILE=${ENV_DIR}/toolchain.cmake

#
TEMP_DIR=${ENV_DIR}/tmp
STAGE_DIR=${ENV_DIR}/stage
STAGE_SYSROOT_DIR=${ENV_DIR}/sysroot

#
source ${ENV_DIR}/env_gcc.sh

if test "${ENV_EXPORT}" = "true"; then
    source ${ENV_DIR}/env_export.sh
fi
