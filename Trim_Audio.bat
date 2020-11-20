@echo off
:: This script is for trimming an audio (removing beginning and ending)
REM ######################
setlocal ENABLEDELAYEDEXPANSION
echo.
echo Keep all files and this batch file in the same folder. 
echo.
REM ######################
:: Explanation: https://iamscum.wordpress.com/guides/vfr/
REM ######################
IF [%1]==[] echo "Drag & Drop the file above it!" && goto end
REM ######################
:: Trimming audio
:: You might want to change the "fps"
py -3 tools\vfr\vfr.py -i "%~1" -o "%~n1.trimmed.mka" --fps=24000/1001 -vmr trim.txt

:: Deleting everything that isn't needed anymore
IF EXIST "%~n1.trimmed.mka" (
	del "%~1"
) 
del "%~n1 - Log.txt"
del "%~n1.trimmed - Log.txt"

echo Done.
:end
PAUSE
