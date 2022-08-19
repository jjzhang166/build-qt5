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

print_available(){
    OLDIFS="$IFS"
    IFS=$'\n'
    echo -e "Available platforms are as follows:"
    for name in $(ls $CURRENT_DIR/platforms)
    do
        [ ! -f $CURRENT_DIR/platforms/$name/config ] && continue
        echo -e "[${name}]"
    done
    IFS="$OLDIFS"
}

print_parameter(){
    print_available
    echo -e ""
    echo -e "Parameter error, Usage:"
    echo -e "$PROGRAM_PATH [platform] all"
    echo -e "$PROGRAM_PATH [platform] toolchain"
    echo -e "$PROGRAM_PATH [platform] 3rdparty"
    echo -e "$PROGRAM_PATH [platform] fetch"
    echo -e "$PROGRAM_PATH [platform] configure"
    echo -e "$PROGRAM_PATH [platform] compile"
    echo -e "$PROGRAM_PATH [platform] vendor"
    echo -e "$PROGRAM_PATH [platform] deploy"
    echo -e "$PROGRAM_PATH [platform] clean"
    echo -e "$PROGRAM_PATH [platform] cleanall"
    exit 1
}

print_log(){
    local log_content=$(echo $2 | tr '[a-z]' '[A-Z]')
    case "$1" in
    function)
    echo -e "\033[1m\033[34m### $log_content ... ###\033[0m"
    LAST_LOG=$log_content
    ;;
    title)
    echo -e "\033[1m\033[32m=== $log_content ... ===\033[0m"
    LAST_LOG=$log_content
    ;;
    error)
    echo -e "\033[1m\033[31m*** $LAST_LOG failed! ***\033[0m"
    exit 10
    ;;
    *)
    echo -e "$2"
    esac
}

fetch_verify(){
    local verify_path=$1
    local verify_num=$2
    local verify_type=$3
    local real_num=
    if [ "$verify_type" = "MD5" ];then
        echo -e "Verifing..."
        real_num=$(cd $(dirname $verify_path) && md5sum $(basename $verify_path) | awk '{print $1}')
        echo -e "MD5 verify nummber = [$verify_num]"
        echo -e "MD5 real   nummber = [$real_num]"
        [ "$verify_num" != "$real_num" ] && return 1
    elif [ "$verify_type" = "SHA1" ];then
        echo -e "Verifing..."
        real_num=$(cd $(dirname $verify_path) && sha1sum $(basename $verify_path))
        echo -e "SHA1 verify nummber = [$verify_num]"
        echo -e "SHA1 real   nummber = [$real_num]"
        [ "$verify_num" != "$real_num" ] && return 1
    elif [ "$verify_type" = "SHA256" ];then
        echo -e "Verifing..."
        real_num=$(cd $(dirname $verify_path) && sha256sum $(basename $verify_path))
        echo -e "SHA256 verify nummber = [$verify_num]"
        echo -e "SHA256 real   nummber = [$real_num]"
        [ "$verify_num" != "$real_num" ] && return 1
    fi
    return 0
}

fetch_download(){
    local fetch_url=$1
    local fetch_dir=$2
    local fetch_realname=$3
    local verify_num=$4
    local verify_type=$5
    local fetch_basename=$(basename $fetch_url)
    local fetch_path=$fetch_dir/$fetch_basename
    local fetch_suffix=.download_cache
    local fetch_dir_real=${fetch_dir/$DOWNLOAD_DIR\//}
    if [ ! -z $fetch_realname ];then
        fetch_path=$fetch_dir/$fetch_realname
    fi
    if [ -f $fetch_path ];then
        if [ ! -z "$verify_num" ];then
            fetch_verify "$fetch_path" "$verify_num" "$verify_type"
            [ $? -eq 0 ] && return 0
            rm -f $fetch_path
        fi
        if [ "$NO_NETWORK" = "1" ];then
            print_log normal "(no network, ignore)"
            return 0
        fi
    fi
    local github_replace_old="https://github.com"
    local github_replace_new="https://endpoint.fastgit.org/https://github.com"
    fetch_url=${fetch_url/$github_replace_old/$github_replace_new}
    if [ ! -z $DOWNLOAD_INTERNAL_URL ];then
        wget --no-check-certificate --spider $DOWNLOAD_INTERNAL_URL/$fetch_dir_real/$fetch_basename > /dev/null 2>&1
        if [ $? -eq 0 ];then
            fetch_url=$DOWNLOAD_INTERNAL_URL/$fetch_dir_real/$fetch_basename
        else
            wget --no-check-certificate --spider $DOWNLOAD_INTERNAL_URL/$fetch_basename > /dev/null 2>&1
            if [ $? -eq 0 ];then
                fetch_url=$DOWNLOAD_INTERNAL_URL/$fetch_basename
            else
                print_log normal "(internal url not exist, ignore)"
            fi
        fi
    fi
    echo -e "Downloading..."
    echo -e "$fetch_url"
    mkdir -p $fetch_dir
    local wget_progress_opt=
    wget --help | grep -q '\--show-progress' && wget_progress_opt="-q --show-progress"
    local wget_command="wget -c $wget_progress_opt \
    --content-disposition \
    --no-check-certificate \
    --timeout 10 --tries 100 \
    $fetch_url -O ${fetch_path}${fetch_suffix}"
    local download_ok=0
    local download_retry_times=10
    for i in $(seq 1 $download_retry_times)
    do
        $wget_command
        if [ $? -eq 0 ];then
            download_ok=1
            break
        fi
        echo -e "Download error, Retry... [$i/$download_retry_times]"
    done
    if [ $download_ok -eq 0 ];then
        return 1
    else
        [ ! -f ${fetch_path}${fetch_suffix} ] && return 1
        mv -f ${fetch_path}${fetch_suffix} ${fetch_path}
        [ $? -ne 0 ] && return 1
    fi
    if [ ! -z "$verify_num" ];then
        fetch_verify "$fetch_path" "$verify_num" "$verify_type"
        [ $? -ne 0 ] && return 1
    fi
    return 0
}

strip_symbol(){
    local strip_command=$1
    local strip_dir=$2
    [ -z $strip_command ] && return 1
    [ -z $strip_dir ] && return 1
    local strip_bin_list=$(find $strip_dir/* \( -path "*/bin/*" \) -type f \( -iname "*" ! -iname "*.*" \))
    local strip_lib_list=$(find $strip_dir/* \( -path "*/lib/*" \) -type f \( -iname "*.so*" \))
    local strip_lib64_list=$(find $strip_dir/* \( -path "*/lib64/*" \) -type f \( -iname "*.so*" \))
    local strip_all_list=$(echo -e "$strip_bin_list\n$strip_lib_list\n$strip_lib64_list")
    local file_message
    local has_striped
    local has_not_striped
    realpath --version > /dev/null 2>&1
    local strip_has_real_patch=$?
    OLDIFS="$IFS"
    IFS=$'\n'
    for name in $strip_all_list
    do
        if [ $strip_has_real_patch -eq 0 ];then
            echo "$(realpath --relative-to=$strip_dir $name)"
        else
            echo "$name"
        fi
        file_message=$(file $name)
        has_striped=$(echo $file_message | grep ", stripped")
        has_not_striped=$(echo $file_message | grep ", not stripped")
        if [ ! -z $has_striped ];then
            echo -e "--ignore (has stripped)"
            continue
        elif [ -z $has_not_striped ];then
            echo -e "--ignore (not a file that can be stripped)"
            continue
        fi
        if [ $? -ne 0 ];then
            echo "--break (strip failed)"
            return 1
        fi
        echo -e "--pass"
        $strip_command -s $name
    done
    IFS="$OLDIFS"
    return 0
}

###

shell_build(){
    mkdir -p $BUILD_DIR
    local step_name=$1
    local step_type=$2
    [ -z $step_name ] && return 1
    if [ ! -z $step_name ];then
        if [ $RESET_STAMP -eq 0 ] && [ -d $BUILD_DIR/$step_name ] && [ ! -f $BUILD_DIR/$step_name/lock ];then
            print_log normal "(ignore)"
            return 0
        fi
    fi
    if [ ! -f $PLATFORM_DIR/$step_name.sh ];then
        print_log normal "(ignore)"
        return 0
    fi
    if [ ! -z $step_name ];then
        mkdir -p $BUILD_DIR/$step_name
        echo "1" > $BUILD_DIR/$step_name/lock
        if [ "$step_type" = "normal" ];then
            mkdir -p $BUILD_DIR/$step_name/src
            mkdir -p $BUILD_DIR/$step_name/work
            mkdir -p $BUILD_HOST_PREFIX
            mkdir -p $BUILD_TARGET_PREFIX
        fi
    fi
    SHELL_TYPE=$step_name
    . $PLATFORM_DIR/$step_name.sh
    [ -f $BUILD_DIR/$step_name/lock ] && rm -f $BUILD_DIR/$step_name/lock
    cd $CURRENT_DIR
}

install_pkgconfig(){
    print_log title "install pkg-config"
    if [ -z $PKG_CONFIG_SYSROOT_DIR ];then
        print_log normal "(ignore)"
        return 0
    fi
    if [ ! -f $CURRENT_DIR/common/tools/pkg-config ];then
        print_log normal "(ignore)"
        return 0
    fi
    $CURRENT_DIR/common/tools/pkg-config --version > /dev/null 2>&1
    local has_pkgconfig=$?
    if [ $has_pkgconfig -ne 0 ];then
        print_log normal "(ignore)"
        return 0
    fi
    mkdir -p $BUILD_HOST_PREFIX/bin
    cp -f $CURRENT_DIR/common/tools/pkg-config $BUILD_HOST_PREFIX/bin/
    [ $? -ne 0 ] && print_log error
}

install_cmake(){
    print_log title "download cmake"
    if [ $RESET_STAMP -eq 0 ] && [ -d $BUILD_DIR/cmake ] && [ ! -f $BUILD_DIR/cmake/lock ];then
        print_log normal "(ignore)"
        return 0
    fi
    if [ -z $CMAKE_DOWNLOAD_URL ];then
        print_log normal "(ignore)"
        return 0
    fi
    mkdir -p $BUILD_DIR/cmake
    mkdir -p $BUILD_DIR/cmake/src
    mkdir -p $BUILD_DIR/cmake/work
    echo "1" > $BUILD_DIR/cmake/lock
    fetch_download "$CMAKE_DOWNLOAD_URL" "$CURRENT_DIR/downloads/cmake" "" "$CMAKE_DOWNLOAD_MD5" MD5
    [ $? -ne 0 ] && print_log error
    local pkg_name=$(basename $CMAKE_DOWNLOAD_URL)
    print_log title "decompress cmake"
    cp -f $CURRENT_DIR/downloads/cmake/$pkg_name $BUILD_DIR/cmake/src
    chmod +x $BUILD_DIR/cmake/src/$pkg_name
    $BUILD_DIR/cmake/src/$pkg_name --skip-license --prefix=$BUILD_DIR/cmake/work
    [ $? -ne 0 ] && print_log error
    mkdir -p $BUILD_HOST_PREFIX/bin
    cp -f $BUILD_DIR/cmake/work/bin/cmake $BUILD_HOST_PREFIX/bin/
    cp -f $BUILD_DIR/cmake/work/bin/ccmake $BUILD_HOST_PREFIX/bin/
    cp -f $BUILD_DIR/cmake/work/bin/cpack $BUILD_HOST_PREFIX/bin/
    cp -f $BUILD_DIR/cmake/work/bin/ctest $BUILD_HOST_PREFIX/bin/
    cp -rf $BUILD_DIR/cmake/work/share $BUILD_HOST_PREFIX/
    cp -rf $BUILD_DIR/cmake/work/man $BUILD_HOST_PREFIX/
    [ -d $PLATFORM_DIR/cmake ] && cp -rf $PLATFORM_DIR/cmake $BUILD_HOST_PREFIX/
    [ -f $BUILD_DIR/cmake/lock ] && rm -f $BUILD_DIR/cmake/lock
    cd $CURRENT_DIR
}

build_project(){
    local project_type=$1
    local project_name=$2
    local project_opt=$3
    local project_real_path=$4
    print_log title "build $project_name"
    [ -z $project_type ] && print_log error
    [ -z $project_name ] && print_log error
    [ -z $SHELL_TYPE ] && print_log error
    if [ -z $project_real_path ];then
        if [ -d $PLATFORM_DIR/$SHELL_TYPE/$project_name ];then
            cp -rf $PLATFORM_DIR/$SHELL_TYPE/$project_name $BUILD_DIR/$SHELL_TYPE/src/
        elif [ -d $PLATFORM_DIR/sources/$project_name ];then
            cp -rf $PLATFORM_DIR/sources/$project_name $BUILD_DIR/$SHELL_TYPE/src/
        elif [ -d $REPO_DIR/$project_name ];then
            cp -rf $REPO_DIR/$project_name $BUILD_DIR/$SHELL_TYPE/src/
        elif [ -d $SOURCE_DIR/$project_name ];then
            cp -rf $SOURCE_DIR/$project_name $BUILD_DIR/$SHELL_TYPE/src/
        elif [ ! -d $BUILD_DIR/$SHELL_TYPE/src/$project_name ];then
            print_log error
        fi
    else
        [ ! -d $project_real_path ] && print_log error
        cp -rf $project_real_path $BUILD_DIR/$SHELL_TYPE/src
    fi
    local project_root_dir=$BUILD_DIR/$SHELL_TYPE/src/$project_name
    mkdir -p $BUILD_DIR/$SHELL_TYPE/work/$project_name
    if [ "$project_type" = "cmake" ];then
        [ ! -f $project_root_dir/CMakeLists.txt ] && project_root_dir=$project_root_dir/cmake
        [ ! -f $project_root_dir/CMakeLists.txt ] && print_log error
        $CMAKE_EXECUTABLE -B $BUILD_DIR/$SHELL_TYPE/work/$project_name $project_root_dir $project_opt
    elif [ "$project_type" = "qmake" ];then
        [ ! -f $project_root_dir/*.pro ] && print_log error
        $QT_QMAKE_EXECUTABLE -o $BUILD_DIR/$SHELL_TYPE/work/$project_name $project_root_dir $project_opt
        [ $? -ne 0 ] && print_log error
    else
        print_log error
    fi
    make -s -C$BUILD_DIR/$SHELL_TYPE/work/$project_name -j$(nproc)
    [ $? -ne 0 ] && print_log error
    make -s -C$BUILD_DIR/$SHELL_TYPE/work/$project_name install
    [ $? -ne 0 ] && print_log error
    cd $CURRENT_DIR
}

invoke_shell(){
    local shell_name=$1
    print_log function "$shell_name"
    [ -z $shell_name ] && print_log error
    if [ -f $CURRENT_DIR/common/do_${shell_name}.sh ];then
        . $CURRENT_DIR/common/do_${shell_name}.sh
    else
        echo -e "Error: Can not find ${shell_name}.sh"
        print_log error
    fi
}
