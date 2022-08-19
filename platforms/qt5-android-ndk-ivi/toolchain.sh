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

do_install_ndk(){
    local ndk_url=
    local ndk_md5=
    local pkg_name=
    ndk_url="https://mirrors.cloud.tencent.com/AndroidSDK/${ANDROID_NDK_NAME}-linux-x86_64.zip"
    #ndk_url="https://dl.google.com/android/repository/${ANDROID_NDK_NAME}-linux-x86_64.zip"
    ndk_md5="b99a69907ca29e8181852645328b6004"
    pkg_name=$(basename $ndk_url)
    print_log title "download ndk"
    mkdir -p $DOWNLOAD_DIR/toolchain
    fetch_download "$ndk_url" "$DOWNLOAD_DIR/toolchain" "" "$ndk_md5" MD5
    [ $? -ne 0 ] && print_log error
    print_log title "decompress ndk"
    mkdir -p $BUILD_DIR/toolchain
    [ -d $BUILD_DIR/toolchain/android-ndk-* ] && rm -rf $BUILD_DIR/toolchain/android-ndk-*
    unzip -q -o $DOWNLOAD_DIR/toolchain/$pkg_name -d $BUILD_DIR/toolchain
    [ $? -ne 0 ] && print_log error
}

do_install_ndk
