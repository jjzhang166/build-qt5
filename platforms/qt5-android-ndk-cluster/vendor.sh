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

do_build_qtdemo(){
    [ ! -f $QT_QMAKE_EXECUTABLE ] && return 0
    build_project qmake digitalclock "-after target.path=$BUILD_TARGET_PREFIX/bin" "$(printf $BUILD_DIR/qt5/src/qtbase-*/examples/widgets/widgets/digitalclock)"
    build_project qmake gallery "-after target.path=$BUILD_TARGET_PREFIX/bin" "$(printf $BUILD_DIR/qt5/src/qtquickcontrols2-*/examples/quickcontrols2/gallery)"
    build_project qmake hellocube "-after target.path=$BUILD_TARGET_PREFIX/bin" "$(printf $BUILD_DIR/qt5/src/qtquick3d-*/examples/quick3d/hellocube)"
}

do_build_vendor(){
    [ ! -f $CMAKE_EXECUTABLE ] && return 0
    local vendor_project_name=cluster
    if [ -d $REPO_DIR/$vendor_project_name ];then
        build_project cmake $vendor_project_name "-DCMAKE_INSTALL_PREFIX=$BUILD_TARGET_PREFIX"
    else
        print_log normal "(no vendor, ignore)"
    fi
}

do_build_qtdemo
do_build_vendor
