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
if [ $RESET_STAMP -eq 0 ] && [ -d $BUILD_DIR/qt5 ] && [ ! -f $BUILD_DIR/qt5/lock ];then
    print_log normal "(ignore)"
    return 0
fi
mkdir -p $BUILD_DIR/qt5/src
mkdir -p $BUILD_DIR/qt5/work
echo "1" > $BUILD_DIR/qt5/lock
QT_PACKAGE_MD5SUM_LIST=
if [ -f $PLATFORM_DIR/qt5/md5sum.txt ];then
    QT_PACKAGE_MD5SUM_LIST=$(cat $PLATFORM_DIR/qt5/md5sum.txt)
fi
curl --version > /dev/null 2>&1
FETCH_HAS_CURL=$?
if [ $FETCH_HAS_CURL -eq 0 ];then
    if [ "$NO_NETWORK" != "1" ];then
        echo -e "Try to get md5sum online..."
        QT_PACKAGE_MD5SUM_LIST=$(curl -s "$QT_DOWNLOAD_URL_PRE/md5sum.txt")
        [ $? -ne 0 ] && print_log error
    fi
else
    print_log normal "(no network, ignore)"
fi
rsync --version > /dev/null 2>&1
FETCH_HAS_RSYNC=$?
for name in $BUILD_LIST
do
    local dname=$(echo -e $name | sed 's/ //g')
    [ "${dname:0:1}" = "#" ] && continue
    [ -z "$dname" ] && continue
    [ -d $BUILD_DIR/qt5/src/$dname-* ] && rm -rf $BUILD_DIR/qt5/src/$dname-*/
    if [ -f $SOURCE_DIR/$dname-*/${dname}.pro ];then
        print_log title "copy $dname"
        if [ $FETCH_HAS_RSYNC -eq 0 ];then
            rsync -r --exclude=".git" $SOURCE_DIR/$dname-*/ $BUILD_DIR/qt5/src/$(basename $SOURCE_DIR/$dname-*/)
        else
            cp -rf $SOURCE_DIR/$dname-*/ $BUILD_DIR/qt5/src/
        fi
        [ $? -ne 0 ] && print_log error
    else
        print_log title "download $dname"
        mkdir -p $DOWNLOAD_DIR/qt5
        DMD5SUM=$(echo "$QT_PACKAGE_MD5SUM_LIST" | grep -E "$dname-" | grep -E ".tar.xz" | awk '{print $1}')
        fetch_download "$QT_DOWNLOAD_URL_PRE/${dname}${QT_DOWNLOAD_URL_POST}" "$DOWNLOAD_DIR/qt5" "" "$DMD5SUM" MD5
        [ $? -ne 0 ] && print_log error
        print_log title "decompress $dname"
        tar -xf $DOWNLOAD_DIR/qt5/${dname}-*.tar.xz -C $BUILD_DIR/qt5/src/
        [ $? -ne 0 ] && print_log error
    fi
    local patch_list=
    [ -d $PLATFORM_DIR/qt5/$dname ] && patch_list=$(find $PLATFORM_DIR/qt5/$dname -type f -name "*.patch")
    if [ ! -z "$patch_list" ];then
        print_log title "patch $dname"
        for PATCH_NAME in $patch_list
        do
            patch -p1 -N -d $BUILD_DIR/qt5/src/$dname* < $PATCH_NAME
            [ $? -ne 0 ] && print_log error
        done
    fi
done
[ -f $BUILD_DIR/qt5/lock ] && rm -f $BUILD_DIR/qt5/lock
cd $CURRENT_DIR
