@echo off
:: Drag & Drop the MKV/MP4/FLAC/WAV above it
:: Set "trim=y" if you want to trim the audio before converting
:: Set "replace=y" if you want to replace the source audio with the output
:: Change "track=0" if you want to select a different track than auto detect
REM ######################
setlocal ENABLEDELAYEDEXPANSION
echo.
echo Keep all files and this batch file in the same folder. 
echo.
REM ######################
set trim=n
set replace=n
set track=0
REM ######################

if "%track%" EQU "0" (
ffmpeg.exe -i "%~1" -c:a pcm_s24le "%~n1.wav"
)
else (
ffmpeg.exe -i "%~1" -map 0:%track% -c:a pcm_s24le "%~n1.wav"
)

if "%trim%" EQU "y" (
py -3 audio\vfr\vfr.py -i "%~n1.wav" -o "%~n1.trimmed.mka" --fps=24000/1001 -vmr trims.txt
)

IF EXIST "%~n1.trimmed.mka" (
echo Convert again...
eac3\eac3to.exe "%~n1.trimmed.mka" "%~n1.meme.wav"
eac3\qaac64.exe "%~n1.meme.wav" -V 127 --no-delay --no-optimize --verbose -o "%~n1.trimmed.m4a"
echo.
echo Done.
) ELSE (
eac3\qaac64.exe "%~n1.wav" -V 127 --no-delay --no-optimize --verbose -o "%~n1.m4a"
echo.
echo Done.
)

if "%replace%" EQU "y" (
 IF EXIST "%~n1.trimmed.m4a" (
  ren "%~n1.trimmed.m4a" "%~n1.m4a"
 )
mkvmerge.exe --ui-language en --output "[QAAC] %~n1%~x1" --no-audio  "(" "%~n1%~x1" ")" --language "1:jpn" --default-track "1:yes" --track-name "1:QAAC" "(" "%~n1.m4a" ")"
del "%~n1.m4a"
)

del "%~n1 - Log.txt"
del "%~n1.meme - Log.txt"
del "%~n1.trimmed - Log.txt"
del "%~n1.wav"
IF EXIST "%~n1.trimmed.mka" (
 del "%~n1.wav"
) 

IF EXIST "%~n1.meme.wav" (
 del "%~n1.trimmed.mka"
) 

IF EXIST "%~n1.trimmed.m4a" (
 del "%~n1.meme.wav"
) 

IF EXIST "%~n1.m4a" (
 del "%~n1.wav"
) 
PAUSE
