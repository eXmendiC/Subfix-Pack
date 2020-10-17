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
:: Explanation & Requirements: https://iamscum.wordpress.com/guides/vfr/
REM ######################
:: Change this values to your liking
set replace=n
REM ######################

:anew
set /p srcname=Audio you want to sync (e.g. TestTV.mkv): 
set /p dstname=Audio that is already synced (e.g. TestBD.mkv): 
echo.

:: Extracting everything and moving it
ffmpeg -i "%srcname%" -vn -acodec copy "%srcname%_temp.mka"
ffmpeg -i "%srcname%" "%srcname%.wav"
ffmpeg -i "%dstname%" "%dstname%.wav"
move /Y "%srcname%_temp.mka" audio\sync-audio-tracks
move /Y "%srcname%.wav" audio\sync-audio-tracks
move /Y "%dstname%.wav" audio\sync-audio-tracks

:: Generate offset, convert seconds to milliseconds and store them in a text file
cd audio\sync-audio-tracks
wsl srcname=$(sed "s/[[:space:]]//g" ^<^<^< "%srcname%.wav") ; mv "%srcname%.wav" $srcname
wsl dstname=$(sed "s/[[:space:]]//g" ^<^<^< "%dstname%.wav") ; mv "%dstname%.wav" $dstname
wsl srcname=$(sed "s/[[:space:]]//g" ^<^<^< "%srcname%.wav") ; dstname=$(sed "s/[[:space:]]//g" ^<^<^< "%dstname%.wav") ; offset=$(bash -i compute-sound-offset.sh "$srcname" "$dstname" 0) ; offset=$(awk "BEGIN {print ($offset*1000)}") ; offset=$(sed "s/\.[^.]*$//" ^<^<^< "$offset") ; echo "$offset" >> offset.txt
wsl srcname=$(sed "s/[[:space:]]//g" ^<^<^< "%srcname%.wav") ; rm $srcname
wsl dstname=$(sed "s/[[:space:]]//g" ^<^<^< "%dstname%.wav") ; rm $dstname

:: Store delay inside variable
set /p delay=< offset.txt
echo %delay%
del offset.txt

:: Muxing it with a delay (no quality loss since no converting)
mkvmerge --ui-language en --output "%dstname% [%delay%ms].mka" --default-track "0:yes" --track-name "0:%delay%ms" --sync "0:%delay%" "(" "%srcname%_temp.mka" ")"
del "%srcname%_temp.mka"
move /Y "%dstname% [%delay%ms].mka" ..\..
echo The delay is %delay%ms
cd ..\..

:: Audio replacing
if "%replace%" EQU "y" (
mkvmerge.exe --ui-language en --output "[NEW] %dstname%" --no-audio  "(" "%dstname%" ")"  --language "1:jpn" "(" "%dstname% [%delay%ms].mka" ")"
del "%dstname% [%delay%ms].mka"
)
PAUSE
