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

do_build_boost(){
    print_log title "download boost"
    fetch_download "http://sources.buildroot.net/boost/boost_1_74_0.tar.bz2" "$DOWNLOAD_DIR/$SHELL_TYPE" "" "da07ca30dd1c0d1fdedbd487efee01bd" MD5
    [ $? -ne 0 ] && print_log error
    local src_dir=$SOURCE_DIR/android_embedded_depends/Boost-for-Android
    print_log title "build Boost"
    cp -rf $src_dir $BUILD_DIR/$SHELL_TYPE/src/
    cp -rf $src_dir $BUILD_DIR/$SHELL_TYPE/work/
    local work_dir=$BUILD_DIR/$SHELL_TYPE/work/Boost-for-Android
    cp -f $DOWNLOAD_DIR/$SHELL_TYPE/boost* $work_dir/
    cd $work_dir && \
    ./build-android.sh $ANDROID_NDK_ROOT \
    --boost=1.74.0 \
    --prefix=$BUILD_TARGET_PREFIX \
    --arch=arm64-v8a \
    --target-version=29 \
    --layout=system \
    --with-libraries=filesystem \
    --with-libraries=system \
    --with-libraries=thread \
    --with-libraries=log \
    > /dev/null 2>&1
    [ $? -ne 0 ] && print_log error
}

do_build_dlt(){
    build_project cmake dlt-daemon "-DCMAKE_INSTALL_PREFIX=$BUILD_TARGET_PREFIX -DDLT_IPC=UNIX_SOCKET -DWITH_DLT_TESTS=OFF -DDLT_USER_IPC_PATH=/data/local/tmp"
}

do_build_vsomeip(){
    build_project cmake vsomeip "-DCMAKE_INSTALL_PREFIX=$BUILD_TARGET_PREFIX -DANDROID=ON -DBASE_PATH=/data/local/tmp"
}

do_build_capicxx_core(){
#     print_log title "download commonapi_core_generator"
#     fetch_download "https://github.com/COVESA/capicxx-core-tools/releases/download/3.2.0.1/commonapi_core_generator.zip" "$DOWNLOAD_DIR/$SHELL_TYPE" "" "73644816f29c9fa4f65d944d60ee6425" MD5
#     mkdir -p $BUILD_DIR/$SHELL_TYPE/work/commonapi_core_generator
#     unzip -q -o $DOWNLOAD_DIR/$SHELL_TYPE/commonapi_core_generator.zip -d $BUILD_DIR/$SHELL_TYPE/work/commonapi_core_generator
#     [ $? -ne 0 ] && print_log error
    print_log title "install commonapi_core_generator"
    unzip -q -o $SOURCE_DIR/commonapi_core_generator/commonapi_core_generator*.zip -d $BUILD_DIR/$SHELL_TYPE/work/commonapi_core_generator
    [ $? -ne 0 ] && print_log error
    cp -rf $BUILD_DIR/$SHELL_TYPE/work/commonapi_core_generator $BUILD_HOST_PREFIX/share/
    ln -sf -T "../share/commonapi_core_generator/commonapi-core-generator-linux-x86_64" $BUILD_HOST_PREFIX/bin/capicxx-core-gen
    [ $? -ne 0 ] && print_log error
    #
    build_project cmake capicxx-core-runtime "-DCMAKE_INSTALL_PREFIX=$BUILD_TARGET_PREFIX -DANDROID=ON"
}

do_build_capicxx_vsomeip(){
#     print_log title "download commonapi_someip_generator"
#     fetch_download "https://github.com/COVESA/capicxx-someip-tools/releases/download/3.2.0.1/commonapi_someip_generator.zip" "$DOWNLOAD_DIR/$SHELL_TYPE" "" "ac3eb5d83d35bb57e93c8f03cac2c989" MD5
#     mkdir -p $BUILD_DIR/$SHELL_TYPE/work/commonapi_someip_generator
#     unzip -q -o $DOWNLOAD_DIR/$SHELL_TYPE/commonapi_someip_generator.zip -d $BUILD_DIR/$SHELL_TYPE/work/commonapi_someip_generator
#     [ $? -ne 0 ] && print_log error
    print_log title "install commonapi_someip_generator"
    unzip -q -o $SOURCE_DIR/commonapi_someip_generator/commonapi_someip_generator*.zip -d $BUILD_DIR/$SHELL_TYPE/work/commonapi_someip_generator
    [ $? -ne 0 ] && print_log error
    cp -rf $BUILD_DIR/$SHELL_TYPE/work/commonapi_someip_generator $BUILD_HOST_PREFIX/share/
    ln -sf -T "../share/commonapi_someip_generator/commonapi-someip-generator-linux-x86_64" $BUILD_HOST_PREFIX/bin/capicxx-someip-gen
    [ $? -ne 0 ] && print_log error
    #
    build_project cmake capicxx-someip-runtime "-DCMAKE_INSTALL_PREFIX=$BUILD_TARGET_PREFIX -DANDROID=ON -DUSE_INSTALLED_COMMONAPI=ON"
}

do_build_protobuf(){
    print_log title "download protoc-host"
    fetch_download "https://github.com/protocolbuffers/protobuf/releases/download/v3.20.0/protoc-3.20.0-linux-x86_64.zip" "$DOWNLOAD_DIR/$SHELL_TYPE" "" "bda6439729a515d1d8c71b41e0ab1fb0" MD5
    [ $? -ne 0 ] && print_log error
    local src_dir=$BUILD_DIR/$SHELL_TYPE/src/protoc-host
    mkdir -p $src_dir
    print_log title "install protoc-host"
    unzip -q -o $DOWNLOAD_DIR/$SHELL_TYPE/protoc-3.20.0-linux-x86_64.zip -d $src_dir
    [ $? -ne 0 ] && print_log error
    mkdir -p $BUILD_HOST_PREFIX/bin/
    mkdir -p $BUILD_HOST_PREFIX/include/
    cp -rf $src_dir/bin/* $BUILD_HOST_PREFIX/bin/
    cp -rf $src_dir/include/* $BUILD_HOST_PREFIX/include/
    #
    print_log title "download protocbuf"
    fetch_download "https://github.com/protocolbuffers/protobuf/releases/download/v3.20.0/protobuf-cpp-3.20.0.tar.gz" "$DOWNLOAD_DIR/$SHELL_TYPE" "" "1db6ee0c403452514fd87e5c1a0f8405" MD5
    [ $? -ne 0 ] && print_log error
    tar -xf $DOWNLOAD_DIR/$SHELL_TYPE/protobuf-cpp-3.20.0.tar.gz -C $BUILD_DIR/$SHELL_TYPE/src
    [ $? -ne 0 ] && print_log error
    src_dir=$(printf $BUILD_DIR/$SHELL_TYPE/src/protobuf*)
    build_project cmake $(basename $src_dir) "-DCMAKE_INSTALL_PREFIX=$BUILD_TARGET_PREFIX -Dprotobuf_BUILD_SHARED_LIBS=ON -Dprotobuf_BUILD_PROTOC_BINARIES=OFF -Dprotobuf_BUILD_TESTS=OFF"
}

do_build_fdbus(){
    build_project cmake fdbus "-DCMAKE_INSTALL_PREFIX=$BUILD_TARGET_PREFIX -DANDROID=ON -DCOMPILE_DEFINITIONS=-DFDB_CFG_SOCKET_PATH=\"/data/local/tmp\""
    cp -rf $BUILD_TARGET_PREFIX/usr/* $BUILD_TARGET_PREFIX/
    rm -rf $BUILD_TARGET_PREFIX/usr/
}

do_build_cxxruntime
do_build_libsffg
do_build_rt
do_build_thread
do_build_openssl
do_build_boost
do_build_dlt
do_build_vsomeip
do_build_capicxx_core
do_build_capicxx_vsomeip
do_build_protobuf
do_build_fdbus
