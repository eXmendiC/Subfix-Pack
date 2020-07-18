@echo off
:: This script is for changing the fps of a source (video/audio) for later purpose like  DVD subs on BD
:: Drag & Drop the MKV above it
:: Some PAL DVDs have different fps and one video for all episodes
:: This script takes care of that issues. However, it can't fix the fps of the subtitles
:: Extract the subtitles from the result here and use Aegisub for that
:: Start Aegisub -> Open .srt -> File -> Export subtitles... -> Transform Framerate -> Change values and tick Reverse transformation
:: Set "full=y" if you rather want to encode the full clip
REM ######################
setlocal ENABLEDELAYEDEXPANSION
echo.
echo Keep all files and this batch file in the same folder. 
echo.
REM ######################
:: Change this values to your liking
REM set start=
REM set end=
set full=n
REM ######################
IF [%1]==[] echo "Drag & Drop the MKV above it!" && goto end
REM ######################
set /p start=Start time (e.g. 00:01:41.935): 
set /p end=End time (e.g. 00:01:51.945): 
REM ######################
if "%full%" EQU "y" (
:: Change the "-r" value to the fps you want to gain and remove "-vf yadif" if you don't want deinterlace
ffmpeg -i "%~1" -vf yadif -r 24 -c:v libx264 -preset veryfast -crf 20 -c:a copy -c:s copy "[PartEnc] %~n1_test.mkv"
) else (
:: Change the "-r" value to the fps you want to gain and remove "-vf yadif" if you don't want deinterlace
ffmpeg -i "%~1" -ss %start% -to %end% -vf yadif -r 24 -c:v libx264 -preset veryfast -crf 20 -c:a copy -c:s copy "[PartEnc] %~n1_test.mkv"
)
:: Change the "-changeTo" value to the fps you want to gain
eac3\eac3to.exe "[PartEnc] %~n1_test.mkv"  "%~n1_export.wav" -changeTo23.976
mkvmerge.exe --ui-language en --output "Fix-%~n1.mkv" --no-audio  "(" "[PartEnc] %~n1_test.mkv" ")" --language "1:jpn" --default-track "1:yes" --track-name "1:" "(" "%~n1_export.wav" ")"
del "[PartEnc] %~n1_test.mkv"
del "%~n1_export.wav"
del "%~n1_export - Log.txt"
:end
Pause
