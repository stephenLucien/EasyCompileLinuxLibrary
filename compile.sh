#!/bin/bash

LIBNAME=${LIBNAME=nanogui}
HOST=${HOST=host_linux}

if test $# -ge 1; then
    LIBNAME=$1
fi

find . -iname "*${LIBNAME}.conf" | while read CONF; do
    ./${HOST}/build.sh ${CONF}
done
