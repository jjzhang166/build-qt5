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

#include "libsffg.h"
#include <gui/Surface.h>
#include <gui/SurfaceComposerClient.h>
#include <iostream>
#include <ui/DisplayInfo.h>
#ifdef OPENGL_USE_HOST
#include <binder/IPCThreadState.h>
#include <binder/ProcessState.h>
#endif

#define SFFG_OK 0
#define SFFG_ERROR 1
#define SFFG_SCREEN_POWER_ON 2

using namespace android;

static sp<SurfaceComposerClient> g_session;
static sp<IBinder> g_display;
static sp<SurfaceControl> g_control;
static DisplayInfo g_displayInfo;

int sffg_init(int32_t display_screen, int32_t* display_width, int32_t* display_height)
{
    if (display_screen < 0) {
        std::cerr << "libsffg: Invalid display screen (input)" << std::endl;
        return SFFG_ERROR;
    }
    if (!display_width || !display_height) {
        std::cerr << "libsffg: Invalid display size (input)" << std::endl;
        return SFFG_ERROR;
    }
    if (g_session) {
        std::cerr << "libsffg: Session has inited" << std::endl;
        return SFFG_ERROR;
    }
    if (g_display) {
        std::cerr << "libsffg: Display has inited" << std::endl;
        return SFFG_ERROR;
    }
    if (g_control) {
        std::cerr << "libsffg: Control has inited" << std::endl;
        return SFFG_ERROR;
    }
#ifdef OPENGL_USE_HOST
    ProcessState::initWithDriver("/dev/vndbinder");
    sp<ProcessState> proc(ProcessState::self());
    ProcessState::self()->startThreadPool();
#endif
    g_session = new SurfaceComposerClient();
    status_t status = g_session->initCheck();
    if (status != NO_ERROR) {
        std::cerr << "libsffg: Session init error, status=" << status << std::endl;
        return SFFG_ERROR;
    }
    const auto& displayList = SurfaceComposerClient::getPhysicalDisplayIds();
    if (display_screen >= displayList.size()) {
        std::cerr << "libsffg: Invalid display screen" << std::endl;
        return SFFG_ERROR;
    }
    g_display = SurfaceComposerClient::getPhysicalDisplayToken(displayList.at(display_screen));
    if (!g_display) {
        std::cerr << "libsffg: Invalid display screen" << std::endl;
        return SFFG_ERROR;
    }
    SurfaceComposerClient::setDisplayPowerMode(g_display, SFFG_SCREEN_POWER_ON);
    status = SurfaceComposerClient::getDisplayInfo(g_display, &g_displayInfo);
    if (status != NO_ERROR) {
        std::cerr << "libsffg: Invalid display info" << std::endl;
        return SFFG_ERROR;
    }
    if (g_displayInfo.w <= 0 || g_displayInfo.h <= 0) {
        std::cerr << "libsffg: Invalid display size" << std::endl;
        return SFFG_ERROR;
    }
    if (g_displayInfo.orientation == DISPLAY_ORIENTATION_0 || g_displayInfo.orientation == DISPLAY_ORIENTATION_180) {
        *display_width = g_displayInfo.w;
        *display_height = g_displayInfo.h;
    } else {
        *display_width = g_displayInfo.h;
        *display_height = g_displayInfo.w;
    }
    return SFFG_OK;
}

int sffg_create(int32_t display_stack, int32_t display_index, EGLNativeWindowType* native_window)
{
    if (display_stack < 0) {
        std::cerr << "libsffg: Invalid display stack (input)" << std::endl;
        return SFFG_ERROR;
    }
    if (display_index < 0) {
        std::cerr << "libsffg: Invalid display index (input)" << std::endl;
        return SFFG_ERROR;
    }
    if (!native_window) {
        std::cerr << "libsffg: Invalid native_window (input)" << std::endl;
        return SFFG_ERROR;
    }
    if (!g_session) {
        std::cerr << "libsffg: Session not init" << std::endl;
        return SFFG_ERROR;
    }
    if (!g_display) {
        std::cerr << "libsffg: Display not init" << std::endl;
        return SFFG_ERROR;
    }
    if (g_control) {
        std::cerr << "libsffg: Control has inited" << std::endl;
        return SFFG_ERROR;
    }
    g_control = g_session->createSurface(String8("SFFG"), g_displayInfo.w, g_displayInfo.h, PIXEL_FORMAT_RGBA_8888);
    if (!g_control || !g_control->isValid()) {
        std::cerr << "libsffg: Control create failed" << std::endl;
        return SFFG_ERROR;
    }
    sp<Surface> surface = g_control->getSurface();
    if (!surface) {
        std::cerr << "libsffg: Invalid surface" << std::endl;
        return SFFG_ERROR;
    }
    SurfaceComposerClient::Transaction trans;
    trans.setLayerStack(g_control, (uint32_t)display_stack);
    trans.setLayer(g_control, (uint32_t)display_index);
    trans.show(g_control);
    status_t status = trans.apply();
    if (status != NO_ERROR) {
        std::cerr << "libsffg: Transform error, status=" << status << std::endl;
        return SFFG_ERROR;
    }
    *native_window = surface.get();
    return SFFG_OK;
}

int sffg_destroy(EGLNativeWindowType native_window)
{
    (void)native_window;
    if (!g_session) {
        std::cerr << "libsffg: Session not init" << std::endl;
        return SFFG_ERROR;
    }
    if (g_control) {
        g_control->release();
    }
    g_session->dispose();
    return SFFG_OK;
}
