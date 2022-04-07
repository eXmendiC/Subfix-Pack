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
set add=n
REM ######################

:anew
set /p want_sync=Audio you want to sync (e.g. TestTV.mkv): 
set /p is_sync=Audio that is already synced (e.g. TestBD.mkv): 
echo.

:: Extracting everything and moving it
ffmpeg -i "%want_sync%" -vn -acodec copy "%want_sync%_temp.mka"
ffmpeg -i "%want_sync%" "%want_sync%.wav"
ffmpeg -i "%is_sync%" "%is_sync%.wav"
move /Y "%want_sync%_temp.mka" tools\sync-audio-tracks
move /Y "%want_sync%.wav" tools\sync-audio-tracks
move /Y "%is_sync%.wav" tools\sync-audio-tracks

:: Generate offset, convert seconds to milliseconds and store them in a text file
cd tools\sync-audio-tracks
wsl want_sync=$(sed "s/[[:space:]]//g" ^<^<^< "%want_sync%.wav") ; mv "%want_sync%.wav" $want_sync
wsl is_sync=$(sed "s/[[:space:]]//g" ^<^<^< "%is_sync%.wav") ; mv "%is_sync%.wav" $is_sync
wsl want_sync=$(sed "s/[[:space:]]//g" ^<^<^< "%want_sync%.wav") ; is_sync=$(sed "s/[[:space:]]//g" ^<^<^< "%is_sync%.wav") ; offset=$(bash -i compute-sound-offset.sh "$want_sync" "$is_sync" 0) ; offset=$(awk "BEGIN {print ($offset*1000)}") ; offset=$(sed "s/\.[^.]*$//" ^<^<^< "$offset") ; echo "$offset" >> "%is_sync%".txt
wsl want_sync=$(sed "s/[[:space:]]//g" ^<^<^< "%want_sync%.wav") ; rm $want_sync
wsl is_sync=$(sed "s/[[:space:]]//g" ^<^<^< "%is_sync%.wav") ; rm $is_sync

:: Store delay inside variable
set /p delay=< "%is_sync%".txt
del "%is_sync%".txt

:: Muxing it with a delay (no quality loss since no converting)
mkvmerge --ui-language en --output "%is_sync% [%delay%ms].mka" --default-track "0:no" --track-name "0:Shifted by %delay%ms" --sync "0:%delay%" "(" "%want_sync%_temp.mka" ")"
del "%want_sync%_temp.mka"
move /Y "%is_sync% [%delay%ms].mka" ..\..
echo The delay is %delay%ms
cd ..\..

:: Audio replacing
if "%replace%" EQU "y" (
mkvmerge.exe -o "[NEW] %is_sync%" --no-audio --no-subtitles --no-buttons --no-track-tags --no-chapters --no-attachments --no-global-tags "(" "%is_sync%" ")"  --default-track "0:yes" "--language" "1:jpn" "(" "%is_sync% [%delay%ms].mka" ")" --no-video --no-audio  "(" "%is_sync%" ")"
del "%is_sync% [%delay%ms].mka"
)

:: Audio adding
if "%add%" EQU "y" (
mkvmerge.exe -o "[NEW] %is_sync%" --no-audio --no-subtitles --no-buttons --no-track-tags --no-chapters --no-attachments --no-global-tags "(" "%is_sync%" ")"  --default-track "0:yes" "--language" "1:ger" "(" "%is_sync% [%delay%ms].mka" ")" --no-video "(" "%is_sync%" ")"
del "%is_sync% [%delay%ms].mka"
)

PAUSE
