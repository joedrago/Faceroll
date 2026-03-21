@echo off
setlocal

:: Configure build type (default: debug)
set BUILD_TYPE=debug
if /i "%1"=="release" set BUILD_TYPE=release

:: Find vcvarsall.bat
set "VCVARS=C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsall.bat"
if not exist "%VCVARS%" (
    set "VCVARS=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat"
)
if not exist "%VCVARS%" (
    echo ERROR: Could not find vcvarsall.bat
    exit /b 1
)

:: Set up MSVC environment
call "%VCVARS%" x64 >nul 2>&1

:: Source files
set SRCS=wabits\wabits.c wabits\wabits_lua.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\lauxlib.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\liolib.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\lopcodes.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\lstate.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\lobject.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\lmathlib.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\loadlib.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\lvm.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\lfunc.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\lstrlib.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\linit.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\lstring.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\lundump.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\lctype.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\ltable.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\ldump.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\loslib.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\lgc.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\lzio.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\ldblib.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\lutf8lib.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\lmem.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\lcorolib.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\lcode.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\ltablib.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\lapi.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\lbaselib.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\ldebug.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\lparser.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\llex.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\ltm.c
set SRCS=%SRCS% wabits\ext\lua-5.4.7\src\ldo.c

:: Compiler flags
set CFLAGS=/nologo /W3 /DWABITS_LUA=1 /I"wabits\ext\lua-5.4.7\src"
set LDFLAGS=/link wsock32.lib xinput.lib user32.lib

if /i "%BUILD_TYPE%"=="debug" (
    set CFLAGS=%CFLAGS% /Zi /Od /DDEBUG
    echo Building wabits [debug]...
) else (
    set CFLAGS=%CFLAGS% /O2 /DNDEBUG
    echo Building wabits [release]...
)

:: Build — output wabits.exe in repo root, obj files in wabits\obj
if not exist wabits\obj mkdir wabits\obj
cl %CFLAGS% /Fo"wabits\obj\\" /Fe"wabits.exe" /Fd"wabits\obj\wabits.pdb" %SRCS% %LDFLAGS%

if %errorlevel% neq 0 (
    echo BUILD FAILED
    exit /b 1
)

echo.
echo OK: wabits.exe
