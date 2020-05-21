@echo off
:: This script is for subtitles from different sources (timing & font).
:: Drag & Drop the FLAC/WAV above it
:: Set "trim=y" if you want to trim the audio before converting
REM ######################
setlocal ENABLEDELAYEDEXPANSION
echo.
echo Keep all files and this batch file in the same folder. 
echo Only set the names of them, no directory structure (paths)!
echo Just press enter for detault values.
echo Always use lowercase.
echo.
REM ######################
set trim=n
REM ######################

ffmpeg.exe -i "%~1" -c:a pcm_s24le "%~n1.wav"

if "%trim%" EQU "y" (
py -3 audio\vfr\vfr.py -i "%~n1.wav" -o "%~n1.trimmed.mka" --fps=24000/1001 -vmr trims.txt
)

IF EXIST "%~n1.trimmed.mka" (
echo Convert again...
eac3\eac3to.exe "%~n1.trimmed.mka" "%~n1.meme.wav"
eac3\flac.exe -8 "%~n1.meme.wav" -o "%~n1.trimmed.flac"
echo.
echo Done.
) ELSE (
eac3\flac.exe -8 "%~n1.wav" -o "%~n1.flac"
echo.
echo Done.
)

IF EXIST "%~n1.trimmed.mka" (
	del "%~n1.wav"
) 

IF EXIST "%~n1.meme.wav" (
	del "%~n1.trimmed.mka"
) 

IF EXIST "%~n1.trimmed.flac" (
	del "%~n1.meme.wav"
) 

IF EXIST "%~n1.flac" (
	del "%~n1.wav"
) 

del "%~n1 - Log.txt"
del "%~n1.meme - Log.txt"
del "%~n1.trimmed - Log.txt"

@pause