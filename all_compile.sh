#!/bin/bash
TOP_DIR=$(dirname $(realpath ${BASH_SOURCE}))
cd ${TOP_DIR}

LIBNAME=${LIBNAME=""}
PLATFORM_TARGET=${PLATFORM_TARGET=arm-linux-gnueabihf}

ls c*.conf | while read CONF; do
    echo $CONF
    if test -e "$CONF"; then
        LIBNAME=$(echo $CONF | sed -ne 's/^c[0-9][0-9]_\(.*\)\.conf$/\1/p')
        #
        CMD="PLATFORM_TARGET=${PLATFORM_TARGET} ./compile.sh ${LIBNAME}"
        echo $CMD
        eval $CMD
    else
        echo "ignore!!!"
    fi
done
