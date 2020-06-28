@echo off
:: This script is for removing intros of web sources
:: Drag & Drop the MKV above it
:: Change "time=00:00:05.005" (HH:MM:SS.ms) when the intro is over
REM ######################
setlocal ENABLEDELAYEDEXPANSION
echo.
echo Keep all files and this batch file in the same folder. 
echo.
REM ######################
:: Change this values to your liking
set time=00:00:05.005
REM ######################
mkvmerge.exe --ui-language en --output "[NoIntro] %~n1.mkv" "(" "%~1" ")" --split parts:%time%-59:59:59.999
Pause