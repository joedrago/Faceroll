@echo off
setlocal

:: Configure build type (default: debug)
set BUILD_TYPE=Debug
if /i "%1"=="release" set BUILD_TYPE=Release

echo Building wabits [%BUILD_TYPE%]...

:: Configure with CMake (only runs generator if needed)
cmake -S wabits -B wabits\build -DCMAKE_BUILD_TYPE=%BUILD_TYPE% >nul 2>&1
if %errorlevel% neq 0 (
    echo CMake configure failed. Retrying with output:
    cmake -S wabits -B wabits\build -DCMAKE_BUILD_TYPE=%BUILD_TYPE%
    exit /b 1
)

:: Build
cmake --build wabits\build --config %BUILD_TYPE%
if %errorlevel% neq 0 (
    echo BUILD FAILED
    exit /b 1
)

:: Copy exe to repo root
copy /y "wabits\build\%BUILD_TYPE%\wabits.exe" wabits.exe >nul 2>&1
if not exist wabits.exe (
    copy /y "wabits\build\wabits.exe" wabits.exe >nul 2>&1
)

if not exist wabits.exe (
    echo ERROR: Could not find built wabits.exe
    exit /b 1
)

echo.
echo OK: wabits.exe
