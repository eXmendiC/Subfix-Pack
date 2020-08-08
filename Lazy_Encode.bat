@echo off
:: This script is for lazy encoding videos without any filtering
:: If you want to store your blu-rays a bit better compressed
:: I recommend converting lossless audio with AAC after that -> "Convert_Trim_Audio-toAAC.bat"
:: Drag & Drop the video above it
REM ######################
setlocal ENABLEDELAYEDEXPANSION
echo.
echo Keep all files and this batch file in the same folder. 
echo.
REM ######################
IF [%1]==[] echo "Drag & Drop the video above it!" && goto end
REM ######################
:: Change this values to your liking
set extension=mkv
set level_limit=0
set bitrate_limit=0
set crf=15
set bitdepth10=y
set hardsub=n
set authoring=n
set res1080p=y
set res720p=n
REM ######################
pushd %~dp0
if "%level_limit%" EQU "0" ( 
set level_limit=
set ref=:ref=12
) else (
set level_limit=-level:v %level_limit%
)
if "%bitrate_limit%" EQU "0" ( 
set bitrate_limit=
) else (
set bitrate_limit=:vbv-maxrate=%bitrate_limit%:vbv-bufsize=%bitrate_limit%
)
if "%bitdepth10%" EQU "y" ( 
set bitdepth10=-profile:v high10 -pix_fmt yuv420p10le 
) else (
set bitdepth10=-pix_fmt yuv420p
)
if "%hardsub%" EQU "y" ( 
set hardsub1080=-vf "subtitles='%~n1'%~x1" -sn
set hardsub720=,"subtitles='%~n1'%~x1" -sn
) else (
set hardsub1080=-c:s copy
set hardsub720= -c:s copy
)
if "%authoring%" EQU "y" ( 
set bitdepth10=-pix_fmt yuv420p
set extension=.264
set level_limit=
set bitrate_limit=
set authoring=:bluray-compat=1:vbv-maxrate=38000:vbv-bufsize=30000:level=4.1:keyint=24:open-gop=1:slices=4:sar=1,1:colorprim=bt709:transfer=bt709:colormatrix=bt709
) else (
set authoring=
)

if "%res1080p%" EQU "y" ( 
ffmpeg -i "%~1" %hardsub1080% -c:a copy -c:v libx264 %bitdepth10% %level_limit% -preset veryslow -crf %crf% -x264-params bframes=10:deblock=-1,-1:psy-rd=0.75,0.10:qcomp=0.70:aq-mode=3:aq-strength=1.00%ref%%bitrate_limit%%authoring% "%~n1_enc.%extension%"
)
if "%res720p%" EQU "y" ( 
ffmpeg -i "%~1" -vf scale=1280x720:flags=spline%hardsub720% -c:a copy -c:v libx264 %bitdepth10% %level_limit% -preset veryslow -crf %crf% -x264-params bframes=10:deblock=-1,-1:psy-rd=0.75,0.10:qcomp=0.70:aq-mode=3:aq-strength=1.00%ref%%bitrate_limit%%authoring% "%~n1_enc-720.%extension%"
)

REM x264_x64.exe "%~1" --colormatrix bt709 --output-depth 10 --preset veryslow --tune animation --crf 15 --deblock -1:-1 --psy-rd 0.75:0.10 --qcomp 0.70 --aq-mode 3 --aq-strength 1.00 --output "%~n1_enc.%extension%"
popd
PAUSE
