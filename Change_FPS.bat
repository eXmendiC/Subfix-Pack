@echo off
:: This script is for changing the fps of a source (audio/subtitle) for later purpose like putting (PAL) DVD subs on BD.
:: Drag & Drop the MKV above it.
:: Keep in mind that the audio/subs won't sync with the source video anymore, that's intended! 
:: It should work with your correct fps BD source now.
:: Some PAL DVDs have one video for all episodes, use "full=n" then.
:: Also, read all of the comments to change the fps to your desiered fps settings!
REM ######################
setlocal ENABLEDELAYEDEXPANSION
echo.
echo Keep all files and this batch file in the same folder. 
echo.
REM ######################
:: Change this values to your liking
REM set start=
REM set end=
set full=y
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
mkvmerge.exe --ui-language en --output "Fix-%~n1.mkv" --no-audio  "(" "[PartEnc] %~n1_test.mkv" ")" --default-track "0:yes" --track-name "0:" "(" "%~n1_export.wav" ")"
REM mkvextract --ui-language en tracks "Fix-%~n1.mkv" 1:"%~n1.sub"
REM ffmpeg -i "%~n1.sub" "%~n1.ass"
ffmpeg -i "Fix-%~n1.mkv" "%~n1.ass"
:: Change the "--multiplier" value to the fps you want to gain (current_fps/wanted_fps)
py -3 audio\prass\prass.py shift "%~n1.ass" --multiplier 24/23.976 -o "%~n1_fixed.ass"
ffmpeg -i "%~n1_fixed.ass" "%~n1.srt"
mkvmerge.exe --ui-language en --output "Final-%~n1.mkv" --no-subtitles "(" "Fix-%~n1.mkv" ")" --default-track "0:yes" --track-name "0:" "(" "%~n1.srt" ")"
del "%~n1.sub"
del "%~n1.ass"
del "%~n1_fixed.ass"
del "%~n1.srt"
del "Fix-%~n1.mkv"
del "[PartEnc] %~n1_test.mkv"
del "%~n1_export.wav"
del "%~n1_export - Log.txt"
:end
Pause

