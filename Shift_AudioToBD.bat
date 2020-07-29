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

:: Finding out the offset/delay
cd audio\sync-audio-tracks
wsl bash -i compute-sound-offset.sh want_sync.wav have_sync.wav 0 >> offset.txt
del want_sync.wav
del have_sync.wav

:: Storing the offset value inside a variable
wsl sed 's/[^a-zA-Z^ \t^.]*//g' offset.txt >> offset_fixed.txt
del offset.txt
wsl sed 's/^000.*//' offset_fixed.txt >> offset_fixed2.txt
del offset_fixed.txt
set /p delay=< offset_fixed2.txt
del offset_fixed2.txt

::Reducing the amount of numbers - else it won't work
if "%delay%"=="%delay:/-=%" ( 
set delay=%delay:~0,6%
) else ( 
set delay=%delay:~0,5%
)

:: Muxing it with a delay (no quality loss since no converting)
mkvmerge --ui-language en --output "[SyncedTo] %dstname%.mka" --default-track "0:yes" --track-name "0:%delay%ms" --sync "0:%delay%" "(" "%srcname%_temp.mka" ")"
del "%srcname%_temp.mka"
move /Y "[SyncedTo] %dstname%.mka" ..\..
echo The delay is %delay%ms
PAUSE