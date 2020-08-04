@echo off
:: Drag & Drop the MKV above it
:: This script generates keyframes for you.
REM ######################
setlocal ENABLEDELAYEDEXPANSION
echo.
echo Keep all files and this batch file in the same folder. 
echo.
REM ######################
IF [%1]==[] echo "Drag & Drop the file above it!" && goto end
REM ######################
ffmpeg -i "%~1" -f yuv4mpegpipe -vf scale=640:360 -pix_fmt yuv420p -vsync drop - | SCXvid "%~n1_keyframes.txt"
echo Done.
PAUSE
