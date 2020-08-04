@echo off
:: This script is for removing intros of web sources
:: Drag & Drop the MKV above it
:: Set "encode=y" if the results are too inacurate - this takes longer
REM ######################
setlocal ENABLEDELAYEDEXPANSION
echo.
echo Keep all files and this batch file in the same folder. 
echo.
REM ######################
:: Change this values to your liking
REM set start=
REM set end=
set encode=n
REM ######################
IF [%1]==[] echo "Drag & Drop the MKV above it!" && goto end
REM ######################
set /p start=Start time (e.g. 00:01:41.935): 
set /p end=End time (e.g. 00:01:51.945): 
REM ######################
if "%encode%" EQU "y" (
:: Add "-vf scale=1280x720" before "-c:v libx264", change the preset or raise the crf value if you want to trade accuracy for speed
ffmpeg -i "%~1" -ss 00:00:00.000 -to %start% -c:v libx264 -preset veryfast -crf 20 -c:a copy "%~n1_temp-001.mkv"
ffmpeg -i "%~1" -ss %end% -c:v libx264 -preset veryfast -crf 20 -c:a copy "%~n1_temp-002.mkv"
mkvmerge --ui-language en --output "[NoSponsorScreenEnc] %~n1.mkv" "(" "%~n1_temp-001.mkv" ")" + "(" "%~n1_temp-002.mkv" ")"
del "%~n1_temp-001.mkv"
del "%~n1_temp-002.mkv"
) else (
mkvmerge --ui-language en --output "%~n1_temp.mkv" "(" "%~1" ")" --split parts:00:00:00.000-%start%,%end%-59:59:59.999
mkvmerge --ui-language en --output "[NoSponsorScreen] %~n1.mkv" "(" "%~n1_temp-001.mkv" ")" + "(" "%~n1_temp-002.mkv" ")"
del "%~n1_temp-001.mkv"
del "%~n1_temp-002.mkv"
)
:end
Pause
