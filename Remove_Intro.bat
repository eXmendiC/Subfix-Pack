@echo off
:: This script is for removing intros of web sources
:: Drag & Drop the MKV above it
:: Change "time=00:00:05.005" (HH:MM:SS.ms) when the intro is over
:: Set "encode=y" if the results are too inacurate - this takes longer
REM ######################
setlocal ENABLEDELAYEDEXPANSION
echo.
echo Keep all files and this batch file in the same folder. 
echo.
REM ######################
IF [%1]==[] echo "Drag & Drop the file above it!" && goto end
REM ######################
:: Change this values to your liking
set time=00:00:05.005
set encode=n
REM ######################
if "%encode%" EQU "y" (
:: Add "-vf scale=1280x720" before "-c:v libx264", change the preset or raise the crf value if you want to trade accuracy for speed
ffmpeg -i "%~1" -ss %time% -c:v libx264 -preset veryfast -crf 20 -c:a copy -c:s copy "[NoIntroEnc] %~n1.mkv"
) else (
mkvmerge.exe --ui-language en --output "[NoIntro] %~n1.mkv" "(" "%~1" ")" --split parts:%time%-59:59:59.999
)
:end
Pause
