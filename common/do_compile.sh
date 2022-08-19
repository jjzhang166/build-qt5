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

QT_SDK_CONFIGSTR="\
[Paths]\n\
Prefix=../../../target/usr\n\
HostPrefix=../../../host/usr\n\
$QT_SDK_CONFIGSTR_ADD"

mkdir -p $BUILD_DIR
if [ $RESET_STAMP -eq 1 ];then
    print_log title "clean qtbase"
    make -s -C$BUILD_DIR/qt5/work/qtbase clean
    [ $? -ne 0 ] && print_log error
fi
print_log title "compile qtbase"
make -s -C$BUILD_DIR/qt5/work/qtbase -j$(nproc)
[ $? -ne 0 ] && print_log error
print_log title "install qtbase"
make -s -C$BUILD_DIR/qt5/work/qtbase install
[ $? -ne 0 ] && print_log error
mkdir -p $BUILD_HOST_PREFIX/bin/
echo -e $QT_SDK_CONFIGSTR > $BUILD_HOST_PREFIX/bin/qt.conf
for name in $BUILD_LIST
do
    local dname=$(echo -e $name | sed 's/ //g')
    [ "${dname:0:1}" = "#" ] && continue
    [ -z "$dname" ] && continue
    [ "$dname" = "qtbase" ] && continue
    print_log title "qmake $dname"
    mkdir -p $BUILD_DIR/qt5/work/$dname
    local qt_other_cfg=""
    [ -f $PLATFORM_DIR/qt5/${dname}.opt ] && qt_other_cfg=$(sed -e '/#/d' $PLATFORM_DIR/qt5/${dname}.opt)
    $QT_QMAKE_EXECUTABLE -o $BUILD_DIR/qt5/work/$dname $BUILD_DIR/qt5/src/${dname}-* -- $qt_other_cfg
    [ $? -ne 0 ] && print_log error
    if [ $RESET_STAMP -eq 1 ];then
        print_log title "clean $dname"
        make -s -C$BUILD_DIR/qt5/work/$dname clean
        [ $? -ne 0 ] && print_log error
    fi
    print_log title "compile $dname"
    make -s -C$BUILD_DIR/qt5/work/$dname -j$(nproc)
    [ $? -ne 0 ] && print_log error
    print_log title "install $dname"
    make -s -C$BUILD_DIR/qt5/work/$dname install
    [ $? -ne 0 ] && print_log error
done
print_log function "compile examples/tests/tools"
if [ $QT_BUILD_OTHER -eq 1 ];then
    for name in $BUILD_LIST
    do
        local dname=$(echo -e $name | sed 's/ //g')
        [ "${dname:0:1}" = "#" ] && continue
        [ -z "$dname" ] && continue
        print_log title "compile $dname-examples"
        make -s -C$BUILD_DIR/qt5/work/$dname -j$(nproc) sub-examples >/dev/null 2>&1
        make -s -C$BUILD_DIR/qt5/work/$dname -j$(nproc) sub-examples-install_subtargets >/dev/null 2>&1
        [ $? -ne 0 ] && print_log normal "(ignore)"
        print_log title "compile $dname-tests"
        make -s -C$BUILD_DIR/qt5/work/$dname -j$(nproc) sub-tests >/dev/null 2>&1
        make -s -C$BUILD_DIR/qt5/work/$dname -j$(nproc) sub-tests-install_subtargets >/dev/null 2>&1
        [ $? -ne 0 ] && print_log normal "(ignore)"
        print_log title "compile $dname-tools"
        make -s -C$BUILD_DIR/qt5/work/$dname -j$(nproc) sub-tools >/dev/null 2>&1
        make -s -C$BUILD_DIR/qt5/work/$dname -j$(nproc) sub-tools-install_subtargets >/dev/null 2>&1
        [ $? -ne 0 ] && print_log normal "(ignore)"
    done
else
    print_log normal "(ignore)"
fi
cd $CURRENT_DIR
