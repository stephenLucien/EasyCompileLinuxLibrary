#!/bin/bash
COMMON_SCRIPTS_DIR=$(dirname $(realpath ${BASH_SOURCE}))

TOP_DIR=${COMMON_SCRIPTS_DIR}/..
THIRDPARTY_SRC_DIR=${THIRDPARTY_SRC_DIR=${TOP_DIR}/sources}

LIBNAME_TMP=${GIT_SOURCE##*/}
LIBNAME=${LIBNAME_TMP%%.git}
LIB_DIR=${THIRDPARTY_SRC_DIR}/${LIBNAME}
BUILD_DIR_NAME=${BUILD_DIR_NAME=build}
BUILD_DIR=${BUILD_DIR=${LIB_DIR}/${BUILD_DIR_NAME}}
TMP_INSTALL_DIR=${TMP_INSTALL_DIR=${BUILD_DIR}/usr}
INSTALL_SUBDIR=${INSTALL_SUBDIR=""}
INSTALL_DIR=${INSTALL_DIR=${SYSROOT}/usr${INSTALL_SUBDIR}}

CMD_PRE_PATCH=${CMD_PRE_PATCH=""}
CMD_POST_PATCH=${CMD_POST_PATCH=""}

FORCE_CMAKE=${FORCE_CMAKE=false}
FORCE_CONFIGURE=${FORCE_CONFIGURE=false}

GEN_MAKE_DB=${GEN_MAKE_DB=false}

try_fetch_git() {
    if test -z "${GIT_SOURCE}"; then
        return
    fi
    if test ! -e "${LIB_DIR}"; then
        mkdir -p $(dirname ${LIB_DIR})
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

check_libdir() {
    if test ! -d "${LIB_DIR}"; then
        echo "dir: ${LIB_DIR} not found"
        exit 1
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
    ${MAKE} distclean
    ${MAKE} clean
}

try_make_clean() {
    echo "try_make_clean"
    make_clean ${LIB_DIR}
    make_clean ${BUILD_DIR}
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
    ${MAKE} --no-silent -d -j$(nproc) | tee make.log >/dev/null
}

make_gen_compiledb() {
    local COMPILE_DB_CMD=$(which compiledb)
    if test -n "${COMPILE_DB_CMD}"; then
        echo ""
        if test -f make.log; then
            ${COMPILE_DB_CMD} -v -S -p make.log
        else
            echo "make.log not found"
        fi
    else
        echo "compiledb not found, it is needed for generating compile_commands.json"
        echo "consider installing it by cmd: pip install compiledb"
    fi
}

try_make_compile() {
    if test "$(make_exist ${BUILD_DIR})" = "1"; then
        make_compile ${BUILD_DIR}
    else
        make_compile ${LIB_DIR}
    fi
    if test "${GEN_MAKE_DB}" = "true"; then
        make_gen_compiledb
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
    rm -rf ${TMP_INSTALL_DIR}
    mkdir -p ${TMP_INSTALL_DIR}
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
    local conf_ac_script
    #
    # conf_ac_script=$(find ${LIB_DIR} -maxdepth 1 -iname 'aconfigure.ac' | head -n 1)
    # if test -f "${conf_ac_script}"; then
    #     echo ${conf_ac_script}
    #     return
    # fi

    conf_ac_script=$(find ${LIB_DIR} -maxdepth 1 -iname 'configure.ac' | head -n 1)
    if test -f "${conf_ac_script}"; then
        echo ${conf_ac_script}
        return
    fi
}

configure_ac_conf() {
    echo "check autoconf"

    local CONF_AC_SCRIPT="$(configure_ac_exist)"
    local CMD
    if test ! -e "${CONF_AC_SCRIPT}"; then
        return
    fi

    cd ${LIB_DIR}
    if test $? -ne 0; then
        return
    fi

    CMD="autoconf -i"
    echo $CMD
    eval $CMD | tee autoconf.log
}

configure_exist() {
    if test ! -d "${LIB_DIR}"; then
        return
    fi
    local conf_script
    #
    conf_script=$(find ${LIB_DIR} -maxdepth 1 -iname 'aconfigure' | head -n 1)
    if test -x "${conf_script}"; then
        echo ${conf_script}
        return
    fi
    #
    conf_script=$(find ${LIB_DIR} -maxdepth 1 -iname 'configure' | head -n 1)
    if test -x "${conf_script}"; then
        echo ${conf_script}
        return
    fi
}

configure_conf() {
    echo "check configure"
    local CONF_SCRIPT="$(configure_exist)"
    local CMD
    if test ! -x "${CONF_SCRIPT}"; then
        return
    fi

    CONFIGURE_OPTS="${CONFIGURE_OPTS} --prefix=${TMP_INSTALL_DIR}"
    if test -n "${TOOLCHAIN_TRIPLE}"; then
        CONFIGURE_OPTS="${CONFIGURE_OPTS} --host=${TOOLCHAIN_TRIPLE}"
    fi
    cd ${LIB_DIR}
    if test $? -ne 0; then
        echo "lib dir not found: ${LIB_DIR}"
        return
    fi
    CMD="${CONF_SCRIPT} ${CONFIGURE_OPTS}"
    echo "$CMD"
    eval $CMD | tee configure.log
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
    local CMD
    if test ! "$(cmake_exist)" = "1"; then
        return
    fi

    test -e ${BUILD_DIR} || mkdir -p ${BUILD_DIR}
    cd ${BUILD_DIR}
    if test $? -ne 0; then
        return
    fi

    CMD="cmake -G \"${CMAKE_GENERATOR}\" \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} \
        -DCMAKE_INSTALL_PREFIX=${TMP_INSTALL_DIR} \
        ${CMAKE_OPTS} \
        ${LIB_DIR} \
        "
    echo "$CMD"
    eval $CMD | tee cmake.log

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

    rm -rf ${TMP_INSTALL_DIR}
    mkdir -p ${TMP_INSTALL_DIR}
    ${GENERATOR} install | tee generator_install.log
}

pre_patch() {
    echo "${CMD_PRE_PATCH}" >/dev/null
    if test -n "${CMD_PRE_PATCH}"; then
        eval "${CMD_PRE_PATCH}"
    fi
}

post_patch() {
    echo "${CMD_POST_PATCH}" >/dev/null
    if test -n "${CMD_POST_PATCH}"; then
        eval "${CMD_POST_PATCH}"
    fi
}

post_install() {
    echo "" >/dev/null
    # return
    test -e ${INSTALL_DIR} || mkdir -p ${INSTALL_DIR}
    cp -rf ${TMP_INSTALL_DIR}/* ${INSTALL_DIR}
}

routine_prepare() {
    echo "routine_prepare"
    try_fetch_git
    check_libdir
    try_make_clean
    rm -rf ${BUILD_DIR}
    git_clean
    pre_patch
}

routine_cmake() {
    echo "routine_cmake"

    cmake_conf
    cmake_compile
    post_patch
    cmake_install
    post_install
}

routine_configure() {
    echo "routine_configure"

    configure_ac_conf
    configure_conf
    try_make_compile
    post_patch
    try_make_install
    post_install
}

routine_default() {
    routine_prepare
    if test "${FORCE_CMAKE}" = "true"; then
        routine_cmake
    elif test "${FORCE_CONFIGURE}" = "true"; then
        routine_configure
    elif test "$(cmake_exist)" = "1"; then
        routine_cmake
    else
        routine_configure
    fi
}

case $2 in
cmake)
    routine_prepare
    routine_cmake
    ;;
configure)
    routine_prepare
    routine_configure
    ;;
*)
    routine_default
    ;;
esac
