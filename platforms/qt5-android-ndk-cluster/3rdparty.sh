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

do_build_cxxruntime(){
    print_log title "install libc++_shared.so"
    mkdir -p $BUILD_TARGET_PREFIX/lib/
    cp -f $NDK_LLVM_PATH/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so $BUILD_TARGET_PREFIX/lib/
    [ $? -ne 0 ] && print_log error
}

do_build_libsffg(){
    print_log title "install libsffg"
    mkdir -p $BUILD_TARGET_PREFIX/lib/
    if [ -z $OPENGL_DIR_PREFIX ] || [ -z $OPENGL_FILE_SUFFIX ];then
        cp -f $SOURCE_DIR/android_embedded_depends/libsffg/libsffg.so $BUILD_TARGET_PREFIX/lib/
    else
        cp -f $SOURCE_DIR/android_embedded_depends/libsffg_${OPENGL_FILE_SUFFIX}/libsffg.so $BUILD_TARGET_PREFIX/lib/
        ln -sf "${OPENGL_DIR_PREFIX}libEGL_${OPENGL_FILE_SUFFIX}.so" $BUILD_TARGET_PREFIX/lib/libEGL.so
        ln -sf "${OPENGL_DIR_PREFIX}libGLES_${OPENGL_FILE_SUFFIX}.so" $BUILD_TARGET_PREFIX/lib/libGLES.so
        ln -sf "${OPENGL_DIR_PREFIX}libGLESv1_CM_${OPENGL_FILE_SUFFIX}.so" $BUILD_TARGET_PREFIX/lib/libGLESv1_CM.so
        ln -sf "${OPENGL_DIR_PREFIX}libGLESv2_${OPENGL_FILE_SUFFIX}.so" $BUILD_TARGET_PREFIX/lib/libGLESv2.so
        ln -sf "${OPENGL_DIR_PREFIX}libGLESv3_${OPENGL_FILE_SUFFIX}.so" $BUILD_TARGET_PREFIX/lib/libGLESv3.so
    fi
    [ $? -ne 0 ] && print_log error
}

do_build_rt(){
    print_log title "build rt"
    build_project cmake rt "-DCMAKE_INSTALL_PREFIX=$BUILD_TARGET_PREFIX" "$SOURCE_DIR/android_embedded_depends/rt"
    [ $? -ne 0 ] && print_log error
}

do_build_thread(){
    print_log title "build thread"
    build_project cmake pthread "-DCMAKE_INSTALL_PREFIX=$BUILD_TARGET_PREFIX" "$SOURCE_DIR/android_embedded_depends/pthread"
    [ $? -ne 0 ] && print_log error
}

do_build_openssl(){
    print_log title "download openssl"
    fetch_download "http://sources.buildroot.net/libopenssl/openssl-1.1.1n.tar.gz" "$DOWNLOAD_DIR/$SHELL_TYPE" "" "2aad5635f9bb338bc2c6b7d19cbc9676" MD5
    [ $? -ne 0 ] && print_log error
    tar -xf $DOWNLOAD_DIR/$SHELL_TYPE/openssl-1.1.1n.tar.gz -C $BUILD_DIR/$SHELL_TYPE/src
    [ $? -ne 0 ] && print_log error
    local src_dir=$(printf $BUILD_DIR/$SHELL_TYPE/src/openssl*)
    print_log title "build openssl"
    cp -rf $src_dir $BUILD_DIR/$SHELL_TYPE/work/
    local work_dir=$(printf $BUILD_DIR/$SHELL_TYPE/work/openssl*)
    export ANDROID_NDK_HOME=$ANDROID_NDK_ROOT PATH=$NDK_LLVM_PATH/bin:$PATH CC=clang && \
    cd $work_dir && \
    ./Configure \
    android-arm64 \
    --prefix=$BUILD_TARGET_PREFIX \
    -D__ANDROID_API__=29 \
    > /dev/null 2>&1 && \
    make -s -C$work_dir -j$(nproc) > /dev/null 2>&1 && \
    make -s -C$work_dir install > /dev/null 2>&1
    [ $? -ne 0 ] && print_log error
}

do_build_cxxruntime
do_build_libsffg
do_build_rt
do_build_thread
do_build_openssl
