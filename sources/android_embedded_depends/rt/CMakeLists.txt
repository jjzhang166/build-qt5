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

cmake_minimum_required(VERSION 3.5 FATAL_ERROR)

project(rt LANGUAGES C)

add_library(
    ${CMAKE_PROJECT_NAME}
    SHARED
    rt.c
)

install(
    TARGETS
    ${CMAKE_PROJECT_NAME}
    LIBRARY
    DESTINATION
    lib
    )
