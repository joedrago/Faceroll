@echo off

REM Run this with no arguments begin capture and Lua processing. Adjust the crop
REM rectangle (X:Y:W:H) to correspond to the mod's rectangle. Pass the name of a
REM PNG on the commandline to output the rectangle's capture once for
REM positioning debugging.

set PIPELINE=-y -f gdigrab -i desktop -vf crop=30:60:2221:9

if /%1==/ goto run

echo "Creating test capture PNG: %1"
ffmpeg %PIPELINE% -vframes 1 "%1"
goto end

:run
ffmpeg %PIPELINE% -pix_fmt yuv422p -f yuv4mpegpipe -r 10 - | wabits.exe

:end
