@echo off
:: This script is for fixing German & English subtitles from CR (timing & font).
:: For "extract=y" you need the following base as a MKV: "Sub 1: German" + "Sub 2: English"
:: For other languages than German the script needs a bit tweaking (see the comments below)
REM ######################
setlocal ENABLEDELAYEDEXPANSION
echo.
echo Keep all files and this batch file in the same folder. 
echo Only set the names of them, no directory structure (paths)!
echo Just press enter for detault values.
echo Always use lowercase.
echo.
REM ######################
:: Explanation: https://iamscum.wordpress.com/guides/prass/
REM ######################
:: Change this values to your liking
set fast=y
set extract=n
set timefixing=n
set shifting=0
set mux=y
set template=template_advanced.ass
set font=font1.ttf
set font2=font1i.ttf
REM ######################

:: Extract subtitle from source
if "%extract%" EQU "y" (
 mkvmerge --ui-language en --output "%~n1_test%~x1" --no-audio --no-video --no-attachments --no-chapters "(" "%~n1%~x1" ")"
 mkvextract --ui-language en tracks "%~n1_test%~x1" 0:"%~n1-01.sub" 1:"%~n1-02.sub"
 set videoname=%~n1%~x1
 set scriptname=%~n1-01.sub
 set scriptnamenew=%~n1-02.sub
 del "%~n1_test%~x1"
 goto TTT
)

set /p videoname=Video (e.g. Test.mkv): 
set /p scriptname=GER-Subtitle (e.g. Test_de-de.ass): 
set /p scriptnamenew=ENG-Subtitle (e.g. Test_en-gb.ass): 

:TTT

if "%fast%" EQU "y" (
goto GGF
)

set /p template=Template (e.g. template.ass): 
set /p font=Normal font (e.g. font.ttf): 
set /p font2=Italic font (e.g. font2.ttf): 
set /p shifting=Time difference for subtitles (1,2,24 for frame/s forward, 0 for nothing or -1,-2,-24 for frame/s backward): 
set /p timefixing=Run time fixing (y/n): 
set /p mux=Mux everything together at the end (y/n): 

:GGF

:: A second muxing for setting the correct fps and removing audio delay - you might have to change it for non 23,976fps content
if NOT exist "%videoname%_fixed.mkv" (
 mkvmerge -o "%videoname%_fixed.mkv"  "--default-track" "0:yes"  "--default-duration" "0:24000/1001p" "--fix-bitstream-timing-information" "0:1" "-a" "1" "-d" "0" "-S" "-T" "(" "%videoname%" ")" "--track-order" "0:0,0:1"
)

::That python script is replacing the font
py -3 audio\prass\prass.py copy-styles --resample --from audio\%template% --to "%scriptname%" -o "%scriptname%_tmp.ass"

:: Shifting the subs a few frames forward or backward
if "%shifting%" EQU "1" (
 ren "%scriptname%_tmp.ass" "%scriptname%_tmp2.ass"
 py -3 audio\prass\prass.py shift --by 42ms "%scriptname%_tmp2.ass" -o "%scriptname%_tmp.ass"
 del "%scriptname%_tmp2.ass"
)

if "%shifting%" EQU "-1" (
 ren "%scriptname%_tmp.ass" "%scriptname%_tmp2.ass"
 py -3 audio\prass\prass.py shift --by -42ms "%scriptname%_tmp2.ass" -o "%scriptname%_tmp.ass"
 del "%scriptname%_tmp2.ass"
)

if "%shifting%" EQU "2" (
 ren "%scriptname%_tmp.ass" "%scriptname%_tmp2.ass"
 py -3 audio\prass\prass.py shift --by 84ms "%scriptname%_tmp2.ass" -o "%scriptname%_tmp.ass"
 del "%scriptname%_tmp2.ass"
)

if "%shifting%" EQU "-2" (
 ren "%scriptname%_tmp.ass" "%scriptname%_tmp2.ass"
 py -3 audio\prass\prass.py shift --by -84ms "%scriptname%_tmp2.ass" -o "%scriptname%_tmp.ass"
 del "%scriptname%_tmp2.ass"
)

if "%shifting%" EQU "24" (
 ren "%scriptname%_tmp.ass" "%scriptname%_tmp2.ass"
 py -3 audio\prass\prass.py shift --by 1001ms "%scriptname%_tmp2.ass" -o "%scriptname%_tmp.ass"
 del "%scriptname%_tmp2.ass"
)

if "%shifting%" EQU "-24" (
 ren "%scriptname%_tmp.ass" "%scriptname%_tmp2.ass"
 py -3 audio\prass\prass.py shift --by -1001ms "%scriptname%_tmp2.ass" -o "%scriptname%_tmp.ass"
 del "%scriptname%_tmp2.ass"
)


:: This step is important for fixing weird border upscaling with players like mpv
awk.exe "/\[Script Info\]/ { print; print \"ScaledBorderAndShadow: yes\"; next }1" "%scriptname%_tmp.ass" >"%scriptname%_tmp2.ass"
del "%scriptname%_tmp.ass"
ren "%scriptname%_tmp2.ass" "%scriptname%_tmp.ass"
echo Fixing border successful

:: Creating keyframes & fixing timing
if "%timefixing%" EQU "y" (
 if NOT exist "%videoname%_fixed.mkv_keyframes.txt" (
  echo Generate keyframes...
  ffmpeg -i "%videoname%_fixed.mkv" -f yuv4mpegpipe -vf scale=640:360 -pix_fmt yuv420p -vsync drop - | SCXvid "%videoname%_fixed.mkv_keyframes.txt"
  echo Keyframes completed.
  )
  py -3 audio\prass\prass.py tpp "%scriptname%_tmp.ass" --lead-in 42 --lead-out 42 --gap 210 --overlap 126 --bias 100 --keyframes "%videoname%_fixed.mkv_keyframes.txt" --fps 23.976 --kf-before-start 210 --kf-before-end 210 --kf-after-start 252 --kf-after-end 252    -o "%scriptname%_fixed.ass"
  del "%scriptname%_tmp.ass"
 )
)
if "%timefixing%" EQU "n" (
 ren "%scriptname%_tmp.ass" "%scriptname%_fixed.ass"
)

:: A loop so it does both subtitles
if not exist "%scriptname%_fixed1.ass" (
 ren "%scriptname%_fixed.ass" "%scriptname%_fixed1.ass"
 del "%scriptname%"
 ren "%scriptnamenew%" "%scriptname%"
 goto GGF
)
del "%scriptname%"

ren "%scriptname%_fixed.ass" "%scriptname%_eng.ass"
ren "%scriptname%_fixed1.ass" "%scriptname%_ger.ass"

:: Muxing the subtitles and audio
:: You might want to change the "--language" or "--default-duration" here
if "%mux%" EQU "y" (
  mkvmerge -o "%videoname%_final.mkv"  "--language" "0:jpn" "--default-track" "0:yes" "--default-duration" "0:24000/1001p" "--language" "1:jpn" "--default-track" "1:yes" "-a" "1" "-d" "0" "-S" "-T" "(" "%videoname%_fixed.mkv" ")" "--sub-charset" "0:UTF-8" "--language" "0:ger"  "--track-name" "0:Deutsch"  "--default-track" "0:yes" "-s" "0" "-D" "-A" "-T" "(" "%scriptname%_ger.ass" ")" "--sub-charset" "0:UTF-8" "--language" "0:eng" "--track-name" "0:English" "--default-track" "0:no" "-s" "0" "-D" "-A" "-T" "(" "%scriptname%_eng.ass" ")" "--track-order" "0:0,0:1,1:0,2:0" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "%font%" "--attach-file" "audio\%font%" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "%font2%" "--attach-file" "audio\%font2%"
  del "%videoname%_fixed.mkv"
 )
)

del "%scriptname%_eng.ass"
del "%scriptname%_ger.ass"

echo Done.
PAUSE
