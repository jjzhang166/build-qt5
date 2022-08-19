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

mkdir -p $BUILD_DIR
mkdir -p $BUILD_HOST_PREFIX
mkdir -p $BUILD_TARGET_PREFIX
[ -d $PLATFORM_DIR/qt5/mkspecs/ ] && \
cp -rf $PLATFORM_DIR/qt5/mkspecs/* $BUILD_DIR/qt5/src/qtbase-*/mkspecs/
QT_BASE_CFG=""
[ -f $PLATFORM_DIR/qt5/qtbase.opt ] && QT_BASE_CFG=$(sed -e '/#/d' $PLATFORM_DIR/qt5/qtbase.opt)
mkdir -p $BUILD_DIR/qt5/work/qtbase
cd $BUILD_DIR/qt5/work/qtbase
QT_CONFIG_RECHECK=
[ $RESET_STAMP -eq 1 ] && QT_CONFIG_RECHECK=-recheck-all
$BUILD_DIR/qt5/src/qtbase-*/configure \
-opensource -confirm-license \
-hostprefix $BUILD_HOST_PREFIX \
-extprefix  $BUILD_TARGET_PREFIX \
$QT_CONFIG_COMMON $QT_CONFIG_PLATFORM $QT_CONFIG_OPTION \
$QT_BASE_CFG $QT_CONFIG_RECHECK
[ $? -ne 0 ] && print_log error
cd $CURRENT_DIR
