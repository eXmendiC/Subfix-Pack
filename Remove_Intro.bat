@echo off
:: This script is for removing intros of web sources
:: Drag & Drop the MKV above it
REM ######################
setlocal ENABLEDELAYEDEXPANSION
echo.
echo Keep all files and this batch file in the same folder. 
echo.
REM ######################
:: Change this values to your liking
REM set start=
REM set end=
REM ######################
IF [%1]==[] echo "Drag & Drop the MKV above it!" && goto end
REM ######################
set /p start=Start time (e.g. 00:01:41.935): 
set /p end=End time (e.g. 00:01:51.945): 
REM ######################
mkvmerge.exe --ui-language en --output "%~n1_temp.mkv" "(" "%~1" ")" --split parts:00:00:00.000-%start%,%end%-59:59:59.999
mkvmerge.exe --ui-language en --output "[NoSponsorScreen] %~n1.mkv" "(" "%~n1_temp-001.mkv" ")" + "(" "%~n1_temp-002.mkv" ")"
del "%~n1_temp-001.mkv"
del "%~n1_temp-002.mkv"
:end
Pause