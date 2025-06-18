@echo off

set PIPELINE=-y -f gdigrab -i desktop -vf crop=30:60:4593:1449

if /%1==/ goto run

echo "Creating test capture PNG: %1"
ffmpeg %PIPELINE% -vframes 1 "%1"
goto end

:run
ffmpeg %PIPELINE% -pix_fmt yuv422p -f yuv4mpegpipe -r 10 - | wabits.exe

:end
