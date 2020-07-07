@echo off
:: This script is for trimming an audio (removing beginning and ending)
:: Write the trims inside a "trims.txt" inside the same folder with content like: Trim(START_FRAME,ENDING_FRAME)
:: Syntax is the same as Avisynth: http://avisynth.nl/index.php/Trim
:: For example Trim(3000,0) = Starting with frame 3000 until 0 (End)
:: Trim(3000,30000) = Starting with frame 3000 until 30000
:: Trim(1000,5000)++Trim(6000,0) = Starting with frame 1000 until 5000 & starting from 6000 until 0 (End) - Removing everything between 5001 and 5999
REM ######################
setlocal ENABLEDELAYEDEXPANSION
echo.
echo Keep all files and this batch file in the same folder. 
echo.
REM ######################
IF [%1]==[] echo "Drag & Drop the file above it!" && goto end
REM ######################
:: Trimming audio
:: You might want to change the "fps"
py -3 audio\vfr\vfr.py -i "%~1" -o "%~n1.trimmed.mka" --fps=24000/1001 -vmr trims.txt

:: Deleting everything that isn't needed anymore
IF EXIST "%~n1.trimmed.mka" (
	del "%~1"
) 
del "%~n1 - Log.txt"
del "%~n1.trimmed - Log.txt"

echo Done.
:end
PAUSE
