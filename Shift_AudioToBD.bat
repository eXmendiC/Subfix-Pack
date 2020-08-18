@echo off
:: This script is for syncing audio from a WEB/BD source onto a different BD source
REM ######################
setlocal ENABLEDELAYEDEXPANSION
echo.
echo Keep all files and this batch file in the same folder. 
echo Only set the names of them, no directory structure (paths)!
echo Just press enter for detault values.
echo Always use lowercase.
echo.
REM ######################
:: Explanation: https://iamscum.wordpress.com/guides/vfr/
:: Requirements: WSL version 1 with Ubuntu / Debian / Pengwin & ffmpeg + sox
REM ######################

:anew
set /p srcname=Audio you want to sync (e.g. TestTV.mkv): 
set /p dstname=Audio that is already synced (e.g. TestBD.mkv): 
echo.

:: Extracting everything and moving it
ffmpeg -i "%srcname%" -vn -acodec copy "%srcname%_temp.mka"
ffmpeg -i "%srcname%" "want_sync.wav"
ffmpeg -i "%dstname%" "have_sync.wav"
move /Y "%srcname%_temp.mka" audio\sync-audio-tracks
move /Y "want_sync.wav" audio\sync-audio-tracks
move /Y "have_sync.wav" audio\sync-audio-tracks

:: Generate offset, convert seconds to milliseconds and store them in a text file
cd audio\sync-audio-tracks
wsl offset=$(bash -i compute-sound-offset.sh want_sync.wav have_sync.wav 0) ; offset=$(awk "BEGIN {print ($offset*1000)}") ; offset=$(sed "s/\.[^.]*$//" ^<^<^< "$offset") ; echo "$offset" >> offset.txt
del want_sync.wav
del have_sync.wav

:: Store delay inside variable
set /p delay=< offset.txt
echo %delay%
del offset.txt

:: Muxing it with a delay (no quality loss since no converting)
mkvmerge --ui-language en --output "%dstname% [%delay%ms].mka" --default-track "0:yes" --track-name "0:%delay%ms" --sync "0:%delay%" "(" "%srcname%_temp.mka" ")"
del "%srcname%_temp.mka"
move /Y "%dstname% [%delay%ms].mka" ..\..
echo The delay is %delay%ms
PAUSE
