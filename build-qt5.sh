#!/bin/bash

#*********************************************************************************
#  *Copyright(C): Juntuan.Lu, 2020-2030, All rights reserved.
#  *Author:  Juntuan.Lu
#  *Version: 1.0
#  *Date:  2021/11/29
#  *Email: 931852884@qq.com
#  *Description:
#  *Others:
#  *Function List:
#  *History:
#**********************************************************************************

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

PROGRAM_PATH=$0

if [ ! -f $CURRENT_DIR/common/common.sh ];then
    echo -e "Error: Can not find common.sh!"
    exit 1
fi
. $CURRENT_DIR/common/common.sh
if [ $# -ne 2 ] || [ -z $1 ] || [ -z $2 ];then
    print_parameter
fi
BUILD_PLATFORM=$1
BUILD_TYPE=$2
[ -z $BUILD_DIR ] && BUILD_DIR=$CURRENT_DIR/build/$BUILD_PLATFORM
[ -z $BUILD_SDK_DIR ] && BUILD_SDK_DIR=$BUILD_DIR/sdk
[ -z $BUILD_RUNTIME_DIR ] && BUILD_RUNTIME_DIR=$BUILD_DIR/runtime
[ -z $SOURCE_DIR ] && SOURCE_DIR=$CURRENT_DIR/sources
[ -z $REPO_DIR ] && REPO_DIR=$CURRENT_DIR/repo
[ -z $DOWNLOAD_DIR ] && DOWNLOAD_DIR=$CURRENT_DIR/downloads
[ -z $TARGET_PACKAGE_DIR ] && TARGET_PACKAGE_DIR=$BUILD_DIR
BUILD_HOST_PREFIX=$BUILD_SDK_DIR/host/usr
BUILD_TARGET_PREFIX=$BUILD_SDK_DIR/target/usr
PLATFORM_DIR=$CURRENT_DIR/platforms/$BUILD_PLATFORM
if [ -f $CURRENT_DIR/common/config ];then
    . $CURRENT_DIR/common/config
fi
if [ ! -f $PLATFORM_DIR/config ];then
    print_available
    echo -e ""
    echo -e "Error: Can not find platform [$BUILD_PLATFORM]!"
    exit 2
fi
RESET_STAMP=1
LAST_LOG=
SHELL_TYPE=
BUILD_LIST=$(cat $PLATFORM_DIR/qt5/build.list)
QT_QMAKE_EXECUTABLE=$BUILD_HOST_PREFIX/bin/qmake
CMAKE_EXECUTABLE=$BUILD_HOST_PREFIX/bin/cmake
. $PLATFORM_DIR/config
#if [ -z $TARGET_SYSROOT ];then
    #TARGET_SYSROOT=$BUILD_DIR/sysroot
    #echo -e "Warning: 'TARGET_SYSROOT' environment not set, use default($TARGET_SYSROOT)."
#fi
if [ -z $CMAKE_TOOLCHAIN_FILE ];then
    [ -f $PLATFORM_DIR/cmake/toolchain.cmake ] && CMAKE_TOOLCHAIN_FILE=$PLATFORM_DIR/cmake/toolchain.cmake
else
    echo -e "Warning: CMAKE_TOOLCHAIN_FILE = $CMAKE_TOOLCHAIN_FILE"
fi
[[ $PATH != *$BUILD_HOST_PREFIX/bin* ]] && export PATH=$BUILD_HOST_PREFIX/bin:$PATH
[[ $LD_LIBRARY_PATH != *$BUILD_HOST_PREFIX/lib* ]] && export LD_LIBRARY_PATH=$BUILD_HOST_PREFIX/lib:$LD_LIBRARY_PATH
export BUILD_HOST_PREFIX
export BUILD_TARGET_PREFIX
export QT_QMAKE_EXECUTABLE
export CMAKE_EXECUTABLE
export CMAKE_TOOLCHAIN_FILE
if [ ! -z $TARGET_SYSROOT ];then
    export TARGET_SYSROOT
fi

BUILD_START_TIME=$(date +%s)

do_toolchain(){
    invoke_shell toolchain
}

do_3rdparty(){
    invoke_shell 3rdparty
}

do_vendor(){
    invoke_shell vendor
}

do_fetch(){
    invoke_shell fetch
}

do_configure(){
    invoke_shell configure
}

do_compile(){
    invoke_shell compile
}

do_deploy(){
    invoke_shell deploy
}

do_clean(){
    mkdir -p $BUILD_DIR
    local cleanall_flag=$1
    if [ -z $cleanall_flag ];then
        print_log function "clean"
        OLDIFS="$IFS"
        IFS=$'\n'
        for NAME in $(ls $BUILD_DIR)
        do
            if [ "$NAME" = "toolchain" ];then
                continue
            fi
            print_log title "remove $NAME"
            rm -rf $BUILD_DIR/$NAME
            [ $? -ne 0 ] && print_log error
        done
        IFS="$OLDIFS"
    else
        print_log function "cleanall"
        rm -rf $CURRENT_DIR/build/*
    fi
    cd $CURRENT_DIR
}

case "$BUILD_TYPE" in
    all)
    RESET_STAMP=0
    do_toolchain
    do_3rdparty
    do_fetch
    do_configure
    do_compile
    do_vendor
    do_deploy
    ;;
    toolchain)
    do_toolchain
    ;;
    3rdparty)
    do_3rdparty
    ;;
    fetch)
    do_fetch
    ;;
    configure)
    do_configure
    ;;
    compile)
    do_compile
    ;;
    vendor)
    do_vendor
    ;;
    deploy)
    do_deploy
    ;;
    clean)
    do_clean
    ;;
    cleanall)
    do_clean all
    ;;
    *)
    print_parameter
esac



print_log function "all finished"

BUILD_END_TIME=$(date +%s)
BUILD_PASS_TIME=$(($BUILD_END_TIME - $BUILD_START_TIME))
echo -e "Pass time: $(date -u -d @$BUILD_PASS_TIME "+%H:%M:%S")"

exit 0
