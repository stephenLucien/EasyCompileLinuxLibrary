#!/bin/bash
ENV_DIR=$(dirname $(realpath ${BASH_SOURCE}))

if test $# -lt 1; then
    echo "argc: $#, should provide resource"
    exit 0
fi
RES_FILE=$1
if test ! -f $RES_FILE; then
    echo "$RES_FILE not a file"
    exit 0
fi

TOP_DIR=${ENV_DIR}/..
THIRDPARTY_SRC_DIR=${TOP_DIR}/sources

source ${ENV_DIR}/env.sh
source $RES_FILE
if test -e $RES_FILE.$(basename ${ENV_DIR}); then
    source $RES_FILE.$(basename ${ENV_DIR})
fi

LIBNAME_TMP=${GIT_SOURCE##*/}
LIBNAME=${LIBNAME_TMP%%.git}
LIB_DIR=${THIRDPARTY_SRC_DIR}/${LIBNAME}
BUILD_DIR=${TEMP_DIR}/${LIBNAME}
INSTALL_DIR=${STAGE_DIR}/${LIBNAME}

try_fetch_git() {
    if test -z "${GIT_SOURCE}"; then
        return
    fi
    if test ! -e "${LIB_DIR}"; then
        cd $(dirname ${LIB_DIR})
        # git clone ${GIT_SOURCE}
        $(which proxychains4) git clone ${GIT_SOURCE}
    fi
    cd ${LIB_DIR}
    if test $? -ne 0; then
        exit 1
    fi
    if test -n "${GIT_BRANCH}"; then
        git checkout ${GIT_BRANCH}
    fi
}

git_clean() {
    cd ${LIB_DIR}
    if test $? -ne 0; then
        return
    fi
    git status
    if test $? -ne 0; then
        return
    fi
    if test -n "${GIT_BRANCH}"; then
        git checkout ${GIT_BRANCH}
        git reset --hard
        git clean -df
    fi
}

make_exist() {
    local MK_DIR="$1"
    if test ! -d "${MK_DIR}"; then
        return
    fi
    local found_mk=$(find ${MK_DIR} -maxdepth 1 -iname 'makefile')
    if test -z "${found_mk}"; then
        return
    fi
    echo 1
}

make_clean() {
    local MK_DIR="$1"
    if test ! "$(make_exist ${MK_DIR})" = "1"; then
        return
    fi
    cd ${MK_DIR}
    if test $? -ne 0; then
        return
    fi
    ${MAKE} clean
}

try_make_clean() {
    make_clean ${BUILD_DIR}
    make_clean ${LIB_DIR}
}

make_compile() {
    local MK_DIR="$1"
    if test ! "$(make_exist ${MK_DIR})" = "1"; then
        return
    fi
    cd ${MK_DIR}
    if test $? -ne 0; then
        return
    fi
    ${MAKE} -j$(nproc) | tee make.log >/dev/null
}

try_make_compile() {
    if test "$(make_exist ${BUILD_DIR})" = "1"; then
        make_compile ${BUILD_DIR}
    else
        make_compile ${LIB_DIR}
    fi
}

make_install() {
    local MK_DIR="$1"
    if test ! "$(make_exist ${MK_DIR})" = "1"; then
        return
    fi
    cd ${MK_DIR}
    if test $? -ne 0; then
        return
    fi
    ${MAKE} install | tee make_install.log
}

try_make_install() {
    if test "$(make_exist ${BUILD_DIR})" = "1"; then
        make_install ${BUILD_DIR}
    else
        make_install ${LIB_DIR}
    fi
}

configure_ac_exist() {
    if test ! -d "${LIB_DIR}"; then
        return
    fi
    local found_conf=$(find ${LIB_DIR} -maxdepth 1 -iname 'configure.ac')
    if test -z "${found_conf}"; then
        return
    fi
    echo 1
}

configure_ac_conf() {
    if test ! "$(configure_ac_exist)" = "1"; then
        return
    fi

    test -e ${BUILD_DIR} || mkdir -p ${BUILD_DIR}
    cd ${BUILD_DIR}
    if test $? -ne 0; then
        return
    fi

    autoconf -i | tee autoconf.log
}

configure_exist() {
    if test ! -d "${LIB_DIR}"; then
        return
    fi
    local found_conf=$(find ${LIB_DIR} -maxdepth 1 -iname 'configure')
    if test -z "${found_conf}"; then
        return
    fi
    echo 1
}

configure_conf() {
    if test ! "$(configure_exist)" = "1"; then
        return
    fi

    test -e ${BUILD_DIR} || mkdir -p ${BUILD_DIR}
    cd ${BUILD_DIR}
    if test $? -ne 0; then
        return
    fi

    CONFIGURE_OPTS="${CONFIGURE_OPTS} --prefix=${INSTALL_DIR}"
    if test -n "${TOOLCHAIN_TRIPLE}"; then
        CONFIGURE_OPTS="${CONFIGURE_OPTS} --host=${TOOLCHAIN_TRIPLE}"
    fi
    ./configure ${CONFIGURE_OPTS} | tee configure.log
}

cmake_exist() {
    if test ! -d "${LIB_DIR}"; then
        return
    fi
    local found_cmake=$(find ${LIB_DIR} -maxdepth 1 -iname 'CMakeLists.txt')
    if test -z "${found_cmake}"; then
        return
    fi
    echo 1
}

cmake_conf() {
    if test ! "$(cmake_exist)" = "1"; then
        return
    fi

    test -e ${BUILD_DIR} || mkdir -p ${BUILD_DIR}
    cd ${BUILD_DIR}
    if test $? -ne 0; then
        return
    fi

    cmake -G "${CMAKE_GENERATOR}" \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
        ${CMAKE_OPTS} \
        ${LIB_DIR} | tee cmake.log

}

cmake_compile() {
    if test ! "$(cmake_exist)" = "1"; then
        return
    fi

    cd ${BUILD_DIR}
    if test $? -ne 0; then
        return
    fi
    ${GENERATOR} | tee generator.log
}

cmake_install() {
    if test ! "$(cmake_exist)" = "1"; then
        return
    fi

    cd ${BUILD_DIR}
    if test $? -ne 0; then
        return
    fi

    rm -rf ${INSTALL_DIR}
    ${GENERATOR} install | tee generator_install.log
}

pre_patch() {
    echo "" >/dev/null
}

post_patch() {
    echo "" >/dev/null
}

post_install() {
    echo "" >/dev/null
    mkdir -p ${STAGE_SYSROOT_DIR}/usr
    cp -rv ${INSTALL_DIR}/* ${STAGE_SYSROOT_DIR}/usr/ | tee post_install.log >/dev/null
}

routine_cmake() {
    try_fetch_git
    try_make_clean
    rm -rf ${BUILD_DIR}
    git_clean
    pre_patch
    cmake_conf
    cmake_compile
    post_patch
    cmake_install
    post_install
}

routine_configure() {
    try_fetch_git
    try_make_clean
    rm -rf ${BUILD_DIR}
    git_clean
    pre_patch
    configure_ac_conf
    configure_conf
    try_make_compile
    post_patch
    try_make_install
    post_install
}

routine_default() {
    if test "$(cmake_exist)" = "1"; then
        routine_cmake
    else
        routine_configure
    fi
}

case $2 in
cmake)
    routine_cmake
    ;;
configure)
    routine_configure
    ;;
*)
    routine_default
    ;;
esac
