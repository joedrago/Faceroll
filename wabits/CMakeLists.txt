cmake_minimum_required(VERSION 3.15)
project(wabits)

if(WIN32)
    set(WABITS_LUA TRUE)
endif()

set(WABITS_SRCS
    wabits.c
)

if(WABITS_LUA)
    add_definitions(-DWABITS_LUA=1)
    set(WABITS_SRCS
        ${WABITS_SRCS}
        wabits_lua.c

        ext/lua-5.4.7/src/lauxlib.c
        ext/lua-5.4.7/src/liolib.c
        ext/lua-5.4.7/src/lopcodes.c
        ext/lua-5.4.7/src/lstate.c
        ext/lua-5.4.7/src/lobject.c
        ext/lua-5.4.7/src/lmathlib.c
        ext/lua-5.4.7/src/loadlib.c
        ext/lua-5.4.7/src/lvm.c
        ext/lua-5.4.7/src/lfunc.c
        ext/lua-5.4.7/src/lstrlib.c
        # ext/lua-5.4.7/src/lua.c
        ext/lua-5.4.7/src/linit.c
        ext/lua-5.4.7/src/lstring.c
        ext/lua-5.4.7/src/lundump.c
        ext/lua-5.4.7/src/lctype.c
        # ext/lua-5.4.7/src/luac.c
        ext/lua-5.4.7/src/ltable.c
        ext/lua-5.4.7/src/ldump.c
        ext/lua-5.4.7/src/loslib.c
        ext/lua-5.4.7/src/lgc.c
        ext/lua-5.4.7/src/lzio.c
        ext/lua-5.4.7/src/ldblib.c
        ext/lua-5.4.7/src/lutf8lib.c
        ext/lua-5.4.7/src/lmem.c
        ext/lua-5.4.7/src/lcorolib.c
        ext/lua-5.4.7/src/lcode.c
        ext/lua-5.4.7/src/ltablib.c
        ext/lua-5.4.7/src/lapi.c
        ext/lua-5.4.7/src/lbaselib.c
        ext/lua-5.4.7/src/ldebug.c
        ext/lua-5.4.7/src/lparser.c
        ext/lua-5.4.7/src/llex.c
        ext/lua-5.4.7/src/ltm.c
        ext/lua-5.4.7/src/ldo.c
    )

    include_directories(ext/lua-5.4.7/src)
endif()

add_executable(wabits
    ${WABITS_SRCS}
)

if(WIN32)
    target_link_libraries(wabits wsock32 xinput)
endif()
