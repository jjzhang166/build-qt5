/*********************************************************************************
 *Copyright(C): Juntuan.Lu, 2020-2030, All rights reserved.
 *Author:  Juntuan.Lu
 *Version: 1.0
 *Date:  2021/11/29
 *Email: 931852884@qq.com
 *Description:
 *Others:
 *Function List:
 *History:
 **********************************************************************************/

#ifndef LIB_SFFG_H
#define LIB_SFFG_H

#include <EGL/egl.h>

#ifdef __cplusplus
extern "C" {
#endif

int sffg_init(int32_t display_screen, int32_t* display_width, int32_t* display_height);
int sffg_create(int32_t display_stack, int32_t display_index, EGLNativeWindowType* native_window);
int sffg_destroy(EGLNativeWindowType native_window);

#ifdef __cplusplus
}
#endif

#endif // LIB_SFFG_H
