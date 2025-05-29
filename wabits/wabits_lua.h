#ifndef WABITS_LUA_H
#define WABITS_LUA_H

#include <stdint.h>

int wlStartup();
void wlShutdown();
void wlUpdate(uint32_t bits);

#endif
