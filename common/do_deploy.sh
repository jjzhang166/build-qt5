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

USER_SIGN_STR="\
#*********************************************************************************\n\
#  *Copyright(C): Juntuan.Lu, 2020-2030, All rights reserved.\n\
#  *Author:  Juntuan.Lu\n\
#  *Version: 1.0\n\
#  *Date:  2021/11/29\n\
#  *Email: 931852884@qq.com\n\
#  *Description:\n\
#  *Others:\n\
#  *Function List:\n\
#  *History:\n\
#**********************************************************************************\n\
"
#
QT_RUNTIME_CONFIGSTR="\
[Paths]\n\
Prefix=$QT_RUNTIME_PREFIX_PATH/usr\n\
Headers=$QT_RUNTIME_PREFIX_PATH/usr/include\n\
Binaries=$QT_RUNTIME_PREFIX_PATH/usr/bin\n\
Libraries=$QT_RUNTIME_PREFIX_PATH/usr/$TARGET_LIB_NAME\n\
ArchData=$QT_RUNTIME_PREFIX_PATH/usr/$TARGET_LIB_NAME\n\
Qml2Imports=$QT_RUNTIME_PREFIX_PATH/usr/$TARGET_LIB_NAME/qml\n\
Plugins=$QT_RUNTIME_PREFIX_PATH/usr/$TARGET_LIB_NAME/plugins\n\
LibraryExecutables=$QT_RUNTIME_PREFIX_PATH/usr/$TARGET_LIB_NAME/libexec\n\
Settings=$QT_RUNTIME_PREFIX_PATH/etc\n\
Data=$QT_RUNTIME_PREFIX_PATH/usr/share\n\
Translations=$QT_RUNTIME_PREFIX_PATH/usr/share/translations\n\
Documentation=$QT_RUNTIME_PREFIX_PATH/usr/share/doc\n\
Examples=$QT_RUNTIME_PREFIX_PATH/usr/share/examples\n\
Tests=$QT_RUNTIME_PREFIX_PATH/usr/share/tests\n\
$QT_RUNTIME_CONFIGSTR_ADD"
#
QT_SDK_ENV_CONFIGSTR="\
#!/bin/bash\n\
\n\
$USER_SIGN_STR\n\
CURRENT_DIR=\"\$(cd \"\$(dirname \"\${BASH_SOURCE[0]:-\$0}\")\" && pwd)\"\n\
\n\
echo -e \"Setup sdk environment...\"\n\
echo -e \"\"\n\
echo -e \"##########################################################################\"\n\
echo -e \"Platform: $BUILD_PLATFORM\"\n\
echo -e \"Root: \$CURRENT_DIR\"\n\
echo -e \"Date: $(date "+%Y-%m-%d  %H:%M:%S")\"\n\
echo -e \"Copyright(C): Juntuan.Lu, 2020-2030, All rights reserved.\"\n\
echo -e \"##########################################################################\"\n\
echo -e \"\"\n\
echo -e \"Please run qmake or cmake to compile your project.\"\n\
echo -e \"\"\n\
\n\
[[ \$PATH != *\$CURRENT_DIR/host/usr/bin* ]] && export PATH=\$CURRENT_DIR/host/usr/bin:\$PATH\n\
[[ \$LD_LIBRARY_PATH != *\$CURRENT_DIR/host/usr/lib* ]] && export LD_LIBRARY_PATH=\$CURRENT_DIR/host/usr/lib:\$LD_LIBRARY_PATH\n\
[ -f \$CURRENT_DIR/host/usr/cmake/toolchain.cmake ] && export CMAKE_TOOLCHAIN_FILE=\$CURRENT_DIR/host/usr/cmake/toolchain.cmake\n\
export BUILD_TARGET_PREFIX=\$CURRENT_DIR/host/usr\n\
export QT_QMAKE_EXECUTABLE=\$CURRENT_DIR/host/usr/bin/qmake\n\
$QT_SDK_ENV_CONFIGSTR_ADD"
#
QT_RUNTIME_ENV_CONFIGSTR="\
#!/bin/sh\n\
\n\
$USER_SIGN_STR\n\
echo -e \"Setup runtime environment...\"\n\
echo -e \"\"\n\
echo -e \"##########################################################################\"\n\
echo -e \"Platform: $BUILD_PLATFORM\"\n\
echo -e \"Date: $(date "+%Y-%m-%d  %H:%M:%S")\"\n\
echo -e \"Copyright(C): Juntuan.Lu, 2020-2030, All rights reserved.\"\n\
echo -e \"##########################################################################\"\n\
echo -e \"\"\n\
\n\
[[ \$PATH != *$QT_RUNTIME_PREFIX_PATH/usr/bin* ]] && export PATH=$QT_RUNTIME_PREFIX_PATH/usr/bin:\$PATH\n\
[[ \$LD_LIBRARY_PATH != *$QT_RUNTIME_PREFIX_PATH/usr/$TARGET_LIB_NAME* ]] && export LD_LIBRARY_PATH=$QT_RUNTIME_PREFIX_PATH/usr/$TARGET_LIB_NAME:\$LD_LIBRARY_PATH\n\
export QML2_IMPORT_PATH=$QT_RUNTIME_PREFIX_PATH/usr/$TARGET_LIB_NAME/qml\n\
export QT_QPA_FONTDIR=$QT_RUNTIME_PREFIX_PATH/usr/share/fonts\n\
export QT_PLUGIN_PATH=$QT_RUNTIME_PREFIX_PATH/usr/$TARGET_LIB_NAME/plugins\n\
$QT_RUNTIME_ENV_CONFIGSTR_ADD"

DEPLOY_SDK_PKG_NAME=${BUILD_PLATFORM}-sdk
DEPLOY_RUNTIME_PKG_NAME=${BUILD_PLATFORM}-runtime
DEPLOY_SDK_SHELL_NAME=environment-setup
DEPLOY_RUNTIME_SHELL_NAME=qt5.sh

mkdir -p $BUILD_DIR
mkdir -p $BUILD_HOST_PREFIX
mkdir -p $BUILD_TARGET_PREFIX
mkdir -p $TARGET_PACKAGE_DIR
echo -e $QT_SDK_ENV_CONFIGSTR > $BUILD_SDK_DIR/$DEPLOY_SDK_SHELL_NAME && chmod +x $BUILD_SDK_DIR/$DEPLOY_SDK_SHELL_NAME
[ $? -ne 0 ] && print_log error
print_log title "package sdk"
if [ "$NO_DEPLOY_PACKUP" = "1" ];then
    print_log normal "(ignore)"
else
    tar -cjf $TARGET_PACKAGE_DIR/${DEPLOY_SDK_PKG_NAME}.tar.bz2 -C $BUILD_SDK_DIR ./ --transform="flags=r;s|./|./${DEPLOY_SDK_PKG_NAME}/|"
    [ $? -ne 0 ] && print_log error
fi
print_log title "install sysroot"
if [ -z $TARGET_SYSROOT ];then
    print_log normal "(ignore)"
else
    mkdir -p $TARGET_SYSROOT
    cp -rfd $BUILD_TARGET_PREFIX/../* $TARGET_SYSROOT/
fi
[ $? -ne 0 ] && print_log error
print_log title "install runtime"
[ -d $BUILD_RUNTIME_DIR ] && rm -rf $BUILD_RUNTIME_DIR
mkdir -p $BUILD_RUNTIME_DIR/etc
mkdir -p $BUILD_RUNTIME_DIR/usr/bin
mkdir -p $BUILD_RUNTIME_DIR/usr/$TARGET_LIB_NAME
mkdir -p $BUILD_RUNTIME_DIR/usr/share
SDK_WHOLE_PATH="$(cd "$BUILD_TARGET_PREFIX/../" && pwd)"
OLDIFS="$IFS"
IFS=$'\n'
for name in $(find $SDK_WHOLE_PATH -type f -o -type l)
do
    local real_name=$name
    local real_path=${real_name/"$SDK_WHOLE_PATH/"/""}
    real_path=${real_path/"lib"/"$TARGET_LIB_NAME"}
    local real_dir=$(dirname "$real_path")
    if [ -z $real_path ];then
        continue
    elif [[ $real_path = include/* ]] || [[ $real_path = doc/* ]];then
        continue
    elif [[ $real_path = $TARGET_LIB_NAME/*.a ]] || [[ $real_path = $TARGET_LIB_NAME/*.o ]] || [[ $real_path = $TARGET_LIB_NAME/*.la ]];then
        continue
    elif [[ $real_path = usr/etc/* ]] || [[ $real_path = usr/include/* ]] || [[ $real_path = usr/doc/* ]] || [[ $real_path = usr/ssl/* ]] || [[ $real_path = usr/man/* ]];then
        continue
    elif [[ $real_path = usr/plugins/* ]] || [[ $real_path = usr/qml/* ]];then
        continue
    elif [[ $real_path = usr/share/doc/* ]] || [[ $real_path = usr/share/man/* ]];then
        continue
    elif [[ $real_path = usr/$TARGET_LIB_NAME/cmake/* ]] || [[ $real_path = usr/$TARGET_LIB_NAME/metatypes/* ]] || [[ $real_path = usr/$TARGET_LIB_NAME/pkgconfig/* ]];then
        continue
    elif [[ $real_path = usr/$TARGET_LIB_NAME/*.a ]] || [[ $real_path = usr/$TARGET_LIB_NAME/*.o ]] || [[ $real_path = usr/$TARGET_LIB_NAME/*.la ]] || [[ $real_path = usr/$TARGET_LIB_NAME/*.prl ]];then
        continue
    else
        [ ! -d $BUILD_RUNTIME_DIR/$real_dir ] && mkdir -p $BUILD_RUNTIME_DIR/$real_dir
        cp -fd "$name" "$BUILD_RUNTIME_DIR/$real_dir" > /dev/null 2>&1
        [ $? -ne 0 ] && print_log error
    fi
done
IFS="$OLDIFS"
[ $? -ne 0 ] && print_log error
[ -d $BUILD_TARGET_PREFIX/etc ] && cp -rfd $BUILD_TARGET_PREFIX/etc $BUILD_RUNTIME_DIR/
[ -d $BUILD_TARGET_PREFIX/plugins ] && cp -rfd $BUILD_TARGET_PREFIX/plugins $BUILD_RUNTIME_DIR/usr/$TARGET_LIB_NAME/
[ -d $BUILD_TARGET_PREFIX/qml ] && cp -rfd $BUILD_TARGET_PREFIX/qml $BUILD_RUNTIME_DIR/usr/$TARGET_LIB_NAME/
[ -d $CURRENT_DIR/common/fonts ] && cp -rfd $CURRENT_DIR/common/fonts ${BUILD_RUNTIME_DIR}/usr/share/
[ -d $PLATFORM_DIR/sysroot ] && cp -rfd $PLATFORM_DIR/sysroot/* $BUILD_RUNTIME_DIR/
echo -e $QT_RUNTIME_ENV_CONFIGSTR > $BUILD_RUNTIME_DIR/etc/$DEPLOY_RUNTIME_SHELL_NAME && chmod +x $BUILD_RUNTIME_DIR/etc/$DEPLOY_RUNTIME_SHELL_NAME
echo -e $QT_RUNTIME_CONFIGSTR > $BUILD_RUNTIME_DIR/usr/bin/qt.conf
[ $? -ne 0 ] && print_log error
print_log title "strip runtime"
if [ -z $STRIP_EXECUTABLE ];then
    print_log normal "(ignore)"
else
    strip_symbol $STRIP_EXECUTABLE $BUILD_RUNTIME_DIR
    [ $? -ne 0 ] && print_log error
fi
print_log title "package runtime"
if [ "$NO_DEPLOY_PACKUP" = "1" ];then
    print_log normal "(ignore)"
else
    tar -cjf $TARGET_PACKAGE_DIR/${DEPLOY_RUNTIME_PKG_NAME}.tar.bz2 -C $BUILD_RUNTIME_DIR ./
    [ $? -ne 0 ] && print_log error
fi
cd $CURRENT_DIR
