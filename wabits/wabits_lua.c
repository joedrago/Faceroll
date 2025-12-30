#include "wabits_lua.h"

#include <stdint.h>
#include <stdio.h>
#include <windows.h>
#include <xinput.h>

#include <lua.h>

#include <lauxlib.h>
#include <lualib.h>

typedef int32_t (*wlThreadFunc)(void * p);

#ifdef _WIN32
// --------------------------------------------------------------------------------------
// Win32 specific calls for threads/locks

typedef HANDLE wlMutex;

static wlMutex wlMutexCreate()
{
    return CreateMutex(NULL, FALSE, NULL);
}

static void wlMutexLock(wlMutex m)
{
    WaitForSingleObject(m, INFINITE);
}

static void wlMutexUnlock(wlMutex m)
{
    ReleaseMutex(m);
}

static void wlThreadStart(wlThreadFunc func)
{
    DWORD ignored = 0;
    CreateThread(NULL, 0, func, NULL, 0, &ignored);
}

static void wlSleep(int milliseconds)
{
    Sleep((DWORD)milliseconds);
}

static HWND lastWowWindow = INVALID_HANDLE_VALUE;
static int wlIsWowInForeground()
{
    HWND win = GetForegroundWindow();
    if (win) {
        char titleBuffer[1024];
        int len = GetWindowTextA(win, titleBuffer, 1023);
        if (len > 0) {
            titleBuffer[len] = 0;
            // printf("Foreground Window: %s\n", titleBuffer);
            if (!strcmp(titleBuffer, "World of Warcraft")) {
                lastWowWindow = win;
                return 1;
            }
            if (!strcmp(titleBuffer, "Ascension")) {
                lastWowWindow = win;
                return 1;
            }
        }
    }
    return 0;
}

static void wlQueueNativeKeyPress(int vkCode)
{
    // printf("wlQueueNativeKeyPress(native): %d\n", vkCode);

    if (lastWowWindow != INVALID_HANDLE_VALUE) {
        PostMessage(lastWowWindow, WM_KEYDOWN, (WPARAM)vkCode, 0);
        wlSleep(20);
        PostMessage(lastWowWindow, WM_KEYUP, (WPARAM)vkCode, 0);
    }
}

// --------------------------------------------------------------------------------------
#else
#error implement this stuff for this platform
#endif

static lua_State * L = NULL;
static wlMutex luaMutex;

int sendKeyToWowNative(lua_State * L)
{
    int vkCode = (int)luaL_checkinteger(L, 1);
    wlQueueNativeKeyPress(vkCode);
    return 0;
}

void wlOnUpdate(lua_State * L, uint32_t bits)
{
    wlMutexLock(luaMutex);

    lua_getglobal(L, "onUpdate");
    if (lua_isfunction(L, -1)) {
        lua_pushnumber(L, (double)bits);
        if (lua_pcall(L, 1, 0, 0) == LUA_OK) {
            lua_pop(L, lua_gettop(L));
        } else {
            printf("Lua Error (onUpdate): %s\n", lua_tostring(L, -1));
        }
    }

    wlMutexUnlock(luaMutex);
}

int wlOnKeyCode(lua_State * L, int keyCode)
{
    wlMutexLock(luaMutex);
    // printf("onKeyCode start %d\n", keyCode);

    int ret = 0;
    lua_getglobal(L, "onKeyCode");
    if (lua_isfunction(L, -1)) {
        lua_pushinteger(L, keyCode);
        if (lua_pcall(L, 1, 1, 0) == LUA_OK) {
            if (lua_isboolean(L, -1)) {
                ret = lua_toboolean(L, -1);
                lua_pop(L, 1);
            }
            lua_pop(L, lua_gettop(L));
        } else {
            printf("Lua Error (onKeyCode): %s\n", lua_tostring(L, -1));
        }
    }

    wlMutexUnlock(luaMutex);
    return ret;
}

void wlOnReset(lua_State * L)
{
    wlMutexLock(luaMutex);

    lua_getglobal(L, "onReset");
    if (lua_isfunction(L, -1)) {
        if (lua_pcall(L, 0, 0, 0) == LUA_OK) {
            lua_pop(L, lua_gettop(L));
        } else {
            printf("Lua Error (onReset): %s\n", lua_tostring(L, -1));
        }
    }

    wlMutexUnlock(luaMutex);
}

// --------------------------------------------------------------------------------------
// Win32 Hook Code

static HHOOK hookHandle = INVALID_HANDLE_VALUE;

static LRESULT CALLBACK keyHandler(int nCode, WPARAM wParam, LPARAM lParam)
{
    if (nCode == HC_ACTION && wParam == WM_KEYDOWN) {
        KBDLLHOOKSTRUCT * kb = (KBDLLHOOKSTRUCT *)lParam;
        // printf("kb->vkCode: %u\n", kb->vkCode);
        if (wlIsWowInForeground()) {
            if (kb->vkCode == VK_LSHIFT || kb->vkCode == VK_LCONTROL) {
                wlOnReset(L);
            } else {
                if (wlOnKeyCode(L, kb->vkCode)) {
                    // dont process key!
                    return 1;
                }
            }
        }
    }
    return CallNextHookEx(hookHandle, nCode, wParam, lParam);
}

static int hookThreadRunning = 1;
static int32_t hookThread(void * p)
{
    printf("hookThread() startup\n");

    hookHandle = SetWindowsHookEx(WH_KEYBOARD_LL, keyHandler, NULL, 0);
    if (hookHandle == NULL) {
        return 0;
    }

    while (hookThreadRunning) {
        MSG message;
        while (GetMessage(&message, NULL, 0, 0)) {
            TranslateMessage(&message);
            DispatchMessage(&message);
        }
    }

    printf("hookThread() shutdown\n");
    return 0;
}

// --------------------------------------------------------------------------------------
// Gamepad Code

// This must match the values in init_wabits.lua
#define WABITS_GAMEPAD_DPAD_UP 1001
#define WABITS_GAMEPAD_DPAD_DOWN 1002
#define WABITS_GAMEPAD_DPAD_LEFT 1003
#define WABITS_GAMEPAD_DPAD_RIGHT 1004
#define WABITS_GAMEPAD_START 1005
#define WABITS_GAMEPAD_BACK 1006
#define WABITS_GAMEPAD_LEFT_THUMB 1007
#define WABITS_GAMEPAD_RIGHT_THUMB 1008
#define WABITS_GAMEPAD_LEFT_SHOULDER 1009
#define WABITS_GAMEPAD_RIGHT_SHOULDER 1010
#define WABITS_GAMEPAD_A 1011
#define WABITS_GAMEPAD_B 1012
#define WABITS_GAMEPAD_X 1013
#define WABITS_GAMEPAD_Y 1014

static int gamepadThreadRunning = 1;
static int32_t gamepadThread(void * p)
{
    printf("gamepadThread() startup\n");

    struct ButtonMap
    {
        WORD flag;
        int code;
    };
    static const struct ButtonMap buttons[] = {
        { XINPUT_GAMEPAD_DPAD_UP, WABITS_GAMEPAD_DPAD_UP },
        { XINPUT_GAMEPAD_DPAD_DOWN, WABITS_GAMEPAD_DPAD_DOWN },
        { XINPUT_GAMEPAD_DPAD_LEFT, WABITS_GAMEPAD_DPAD_LEFT },
        { XINPUT_GAMEPAD_DPAD_RIGHT, WABITS_GAMEPAD_DPAD_RIGHT },
        { XINPUT_GAMEPAD_START, WABITS_GAMEPAD_START },
        { XINPUT_GAMEPAD_BACK, WABITS_GAMEPAD_BACK },
        { XINPUT_GAMEPAD_LEFT_THUMB, WABITS_GAMEPAD_LEFT_THUMB },
        { XINPUT_GAMEPAD_RIGHT_THUMB, WABITS_GAMEPAD_RIGHT_THUMB },
        { XINPUT_GAMEPAD_LEFT_SHOULDER, WABITS_GAMEPAD_LEFT_SHOULDER },
        { XINPUT_GAMEPAD_RIGHT_SHOULDER, WABITS_GAMEPAD_RIGHT_SHOULDER },
        { XINPUT_GAMEPAD_A, WABITS_GAMEPAD_A },
        { XINPUT_GAMEPAD_B, WABITS_GAMEPAD_B },
        { XINPUT_GAMEPAD_X, WABITS_GAMEPAD_X },
        { XINPUT_GAMEPAD_Y, WABITS_GAMEPAD_Y },
    };
    static const size_t buttonCount = sizeof(buttons) / sizeof(buttons[0]);

    XINPUT_STATE prevStates[XUSER_MAX_COUNT];
    ZeroMemory(prevStates, sizeof(XINPUT_STATE) * XUSER_MAX_COUNT);

    while (gamepadThreadRunning) {
        DWORD dwResult;
        for (DWORD i = 0; i < XUSER_MAX_COUNT; i++) {
            XINPUT_STATE currState;
            ZeroMemory(&currState, sizeof(XINPUT_STATE));

            dwResult = XInputGetState(i, &currState);

            if (dwResult == ERROR_SUCCESS) {
                // Controller is connected

                XINPUT_STATE * prevState = &prevStates[i];
                for (size_t buttonIndex = 0; buttonIndex < buttonCount; ++buttonIndex) {
                    const struct ButtonMap * button = &buttons[buttonIndex];
                    if (!(prevState->Gamepad.wButtons & button->flag) && (currState.Gamepad.wButtons & button->flag)) {
                        // This button was just pressed!

                        wlOnKeyCode(L, button->code);
                    }
                }

                memcpy(&prevStates[i], &currState, sizeof(XINPUT_STATE));
            } else {
                // Controller is not connected

                ZeroMemory(&prevStates[i], sizeof(XINPUT_STATE));
            }
        }

        Sleep(50);
    }

    printf("gamepadThread() shutdown\n");
    return 0;
}

// --------------------------------------------------------------------------------------

int wlStartup()
{
    printf("wlStartup()\n");

    luaMutex = wlMutexCreate();

    L = luaL_newstate();
    luaL_openlibs(L);
    lua_gc(L, LUA_GCRESTART);
    lua_gc(L, LUA_GCGEN, 0, 0);

    lua_pushcfunction(L, sendKeyToWowNative);
    lua_setglobal(L, "sendKeyToWowNative");

    lua_newtable(L);
    lua_setglobal(L, "WABITS_LOAD");

    HANDLE hFind;
    WIN32_FIND_DATA FindFileData;
    int nextIndex = 0;
    if ((hFind = FindFirstFile("Spec*.lua", &FindFileData)) != INVALID_HANDLE_VALUE) {
        do {
            if (strstr(FindFileData.cFileName, "Spec") == FindFileData.cFileName) {
                char * specName = FindFileData.cFileName + 4;
                char * dotLoc = strstr(specName, ".");
                if (dotLoc) {
                    *dotLoc = 0;
                }

                lua_getglobal(L, "WABITS_LOAD");
                lua_pushinteger(L, ++nextIndex);
                lua_pushstring(L, specName);
                lua_settable(L, -3);
            }
        } while (FindNextFile(hFind, &FindFileData));
        FindClose(hFind);
    }

    wlThreadStart(hookThread);
    wlThreadStart(gamepadThread);

    if (luaL_dofile(L, "wabits/wabits.lua") == LUA_OK) {
        lua_pop(L, lua_gettop(L));
    } else {
        printf("Lua Error: %s", lua_tostring(L, -1));
        return 1;
    }

    return 1;
}

void wlShutdown()
{
    printf("wlShutdown()\n");

    hookThreadRunning = 0;
    gamepadThreadRunning = 0;
}

void wlUpdate(uint32_t bits)
{
    // printf("wlUpdate(0x%x)\n", bits);
    wlOnUpdate(L, bits);
}
