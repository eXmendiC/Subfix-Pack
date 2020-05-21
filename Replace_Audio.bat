@echo off
echo 
:: This script replaces the audio from one source with another source
REM ######################
setlocal ENABLEDELAYEDEXPANSION
echo.
echo Keep all files and this batch file in the same folder. 
echo Only set the names of them, no directory structure (paths)!
echo Just press enter for detault values.
echo Always use lowercase.
echo.
REM ######################
set /p videoname=Videosource (e.g. CR.mkv): 
set /p audioname=Audiosource (e.g. AMZ.mkv): 
set delay=0
REM set /p delay=Audiodelay in ms (Default: 0): 
for /F "delims=" %%I in ('ffprobe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "%audioname%"') do set "acodec=%%I"
for /F "delims=" %%I in ('ffprobe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "%videoname%"') do set "oldcodec=%%I"

if "%acodec%" EQU "ac3" (set acodec=AC3)
if "%acodec%" EQU "eac3" (set acodec=E-AC3)
if "%acodec%" EQU "aac" (set acodec=AAC)
if "%acodec%" EQU "flac" (set acodec=FLAC)

if "%oldcodec%" EQU "ac3" (set oldcodec=AC3)
if "%oldcodec%" EQU "eac3" (set oldcodec=E-AC3)
if "%oldcodec%" EQU "aac" (set oldcodec=AAC)
if "%oldcodec%" EQU "flac" (set oldcodec=FLAC)

echo Old Audio-Codec: %oldcodec%
echo New Audio-Codec: %acodec%
call set new_name=%%videoname:%oldcodec%=%acodec%%%
if "%oldcodec%" EQU "%acodec%" (set "new_name=%videoname%")
mkvmerge.exe --ui-language en --output "[NEW] %new_name%" --no-audio  "(" "%videoname%" ")" --no-video --no-attachments --language "1:jpn" --default-track "1:yes" --track-name "1:Replaced" --sync "1:%delay%" "(" "%audioname%" ")"

echo Done.
PAUSE