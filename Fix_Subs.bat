@echo off
:: This script is for subtitles from different sources (timing & font).
:: It only works on sources with 23.976fps. If your source is different you've to change the following parameters in the code:
:: "--default-duration" "0:24000/1001p"
:: --fps 23.976
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
set fast=n
set extract=n
set source=ass
set timefixing=y
set timefixingmode=3
set shifting=0
set secpass=y
set mux=y
set german_typographie=n
set italic_honorifics=n
set template=template_advanced.ass
set font=font1.ttf
set font2=font1i.ttf
REM ######################

:: Extract subtitle from source
if "%extract%" EQU "y" (
 mkvmerge --ui-language en --output "%~n1_test%~x1" --no-audio --no-video --no-attachments --no-chapters "(" "%~n1%~x1" ")"
 mkvextract --ui-language en tracks "%~n1_test%~x1" 0:"%~n1.sub"
 set videoname=%~n1%~x1
 set scriptname=%~n1.sub
 del "%~n1_test%~x1"
 goto TTT
)

echo Avoid special characters like bracket!
set /p videoname=Video (e.g. Test.mkv): 
set /p scriptname=Subtitle (e.g. Test.ass / Test.srt): 

:TTT

if "%fast%" EQU "y" (
goto GGF
)

echo .
echo Default is template_advanced.ass
set /p template=Template (e.g. template.ass) [template]: 
echo Default is font.ttf
set /p font=Normal font (e.g. font.ttf) [font]: 
echo Default is font2.ttf
set /p font2=Italic font (e.g. font2.ttf) [font2]: 
echo Default is ass
set /p source=srt or ass input (srt/ass) [source]: 
echo Default is y
set /p secpass=Use a second mux pass (y/n) [secpass]: 
echo Default is 0
set /p shifting=Shifting timing in frames (1,2,24,0,-1,-2,-24) [shifting]: 
echo Default is y
set /p timefixing=Run time fixing (y/n) [timefixing]: 
echo Default is 3
set /p timefixingmode=Mode of the timefixing (0-6) [timefixingmode]: 
echo Default is n
set /p typo=Run german typography fixing (y/n) [typo]: 
echo Default is y
set /p mux=Mux everything together at the end (y/n) [mux]: 

:GGF
echo.
echo Start fixing...

:: A second muxing for setting the correct fps and removing audio delay
:: You might want to change the "0:24000/1001p" aka fps here
if "%secpass%" EQU "y" (
 if NOT exist "%videoname%_fixed.mkv" (
 mkvmerge -o "%videoname%_fixed.mkv" "--no-subtitles" "--default-duration" "0:24000/1001p" "--fix-bitstream-timing-information" "0:1" "%videoname%"
 )
)
if "%secpass%" EQU "n" (
 if NOT exist "%videoname%_fixed.mkv" (
 copy "%videoname%" "%videoname%_fixed.mkv"
 )
)
 
if "%source%" EQU "srt" (
 echo Converting srt to ass...
 :: That python script is scaling the subtitles and replacing the font
 py -3 tools\prass\prass.py convert-srt "%scriptname%" --encoding utf-8 | py -3 tools\prass\prass.py copy-styles --resolution 1920x1080 --from custom\%template% -o "%scriptname%_srt.ass"
 :: That python script is detecting typeset and making it "/an8" (top)
 py -3 tools\amazon-netflix_typeset_split.py "%scriptname%_srt.ass" "%scriptname%_tmp.ass"
 del "%scriptname%_srt.ass"
 del "%~n1.sub"
 echo Converting completed.
)

if "%source%" EQU "ass" (
:: That python script is and replacing the font
py -3 tools\prass\prass.py copy-styles --resample --from custom\%template% --to "%scriptname%" -o "%scriptname%_tmp.ass"
del "%~n1.sub"
)

:: Shifting the subs a few frames forward or backward
if "%shifting%" EQU "1" (
 ren "%scriptname%_tmp.ass" "%scriptname%_tmp2.ass"
 py -3 tools\prass\prass.py shift --by 42ms "%scriptname%_tmp2.ass" -o "%scriptname%_tmp.ass"
 del "%scriptname%_tmp2.ass"
)

if "%shifting%" EQU "-1" (
 ren "%scriptname%_tmp.ass" "%scriptname%_tmp2.ass"
 py -3 tools\prass\prass.py shift --by -42ms "%scriptname%_tmp2.ass" -o "%scriptname%_tmp.ass"
 del "%scriptname%_tmp2.ass"
)

if "%shifting%" EQU "2" (
 ren "%scriptname%_tmp.ass" "%scriptname%_tmp2.ass"
 py -3 tools\prass\prass.py shift --by 84ms "%scriptname%_tmp2.ass" -o "%scriptname%_tmp.ass"
 del "%scriptname%_tmp2.ass"
)

if "%shifting%" EQU "-2" (
 ren "%scriptname%_tmp.ass" "%scriptname%_tmp2.ass"
 py -3 tools\prass\prass.py shift --by -84ms "%scriptname%_tmp2.ass" -o "%scriptname%_tmp.ass"
 del "%scriptname%_tmp2.ass"
)

if "%shifting%" EQU "24" (
 ren "%scriptname%_tmp.ass" "%scriptname%_tmp2.ass"
 py -3 tools\prass\prass.py shift --by 1001ms "%scriptname%_tmp2.ass" -o "%scriptname%_tmp.ass"
 del "%scriptname%_tmp2.ass"
)

if "%shifting%" EQU "-24" (
 ren "%scriptname%_tmp.ass" "%scriptname%_tmp2.ass"
 py -3 tools\prass\prass.py shift --by -1001ms "%scriptname%_tmp2.ass" -o "%scriptname%_tmp.ass"
 del "%scriptname%_tmp2.ass"
)

:: Cleaning the .ass file
py -3 tools\prass\prass.py cleanup "%scriptname%_tmp.ass" --styles --empty-lines --comments -o "%scriptname%_tmp2.ass"
del "%scriptname%_tmp.ass"
ren "%scriptname%_tmp2.ass" "%scriptname%_tmp.ass"

:: This step is important for fixing weird border upscaling with players like mpv
awk "/\[Script Info\]/ { print; print \"ScaledBorderAndShadow: yes\"; next }1" "%scriptname%_tmp.ass" >"%scriptname%_tmp2.ass"
del "%scriptname%_tmp.ass"
ren "%scriptname%_tmp2.ass" "%scriptname%_tmp.ass"


if "%timefixing%" EQU "n" (
 ren "%scriptname%_tmp.ass" "%scriptname%_fixed.ass"
 goto NSU
)
if "%timefixingmode%" EQU "0" (
 ren "%scriptname%_tmp.ass" "%scriptname%_fixed.ass"
 goto NSU
)

:: Creating keyframes & fixing timing
:: You might want to change the "fps" here
if "%timefixing%" EQU "y" (
 if NOT exist "%videoname%_fixed.mkv_keyframes.txt" (
  echo Generate keyframes...
  ffmpeg -i "%videoname%_fixed.mkv" -f yuv4mpegpipe -vf scale=640:360 -pix_fmt yuv420p -vsync drop - | SCXvid "%videoname%_fixed.mkv_keyframes.txt"
  echo Keyframes completed.
  )
 if "%timefixingmode%" EQU "0" (
  py -3 tools\prass\prass.py tpp "%scriptname%_tmp.ass" --lead-in 42 --lead-out 42 --gap 210 --overlap 126 --bias 80 --keyframes "%videoname%_fixed.mkv_keyframes.txt" --fps 23.976 --kf-before-start 126 --kf-before-end 168 --kf-after-start 126 --kf-after-end 168 -o "%scriptname%_fixed.ass"
  del "%scriptname%_tmp.ass"
 )
 if "%timefixingmode%" EQU "1" (
  py -3 tools\prass\prass.py tpp "%scriptname%_tmp.ass" --lead-in 42 --lead-out 42 --gap 210 --overlap 126 --bias 80 --keyframes "%videoname%_fixed.mkv_keyframes.txt" --fps 23.976 --kf-before-start 210 --kf-before-end 252 --kf-after-start 210 --kf-after-end 252 -o "%scriptname%_fixed.ass"
  del "%scriptname%_tmp.ass"
 )
 if "%timefixingmode%" EQU "2" (
  py -3 tools\prass\prass.py tpp "%scriptname%_tmp.ass" --lead-in 42 --lead-out 42 --gap 336 --overlap 210 --bias 80 --keyframes "%videoname%_fixed.mkv_keyframes.txt" --fps 23.976 --kf-before-start 252 --kf-before-end 294 --kf-after-start 252 --kf-after-end 294 -o "%scriptname%_fixed.ass"
  del "%scriptname%_tmp.ass"
 )
 if "%timefixingmode%" EQU "3" (
  py -3 tools\prass\prass.py tpp "%scriptname%_tmp.ass" --lead-in 84 --lead-out 84 --gap 462 --overlap 252 --bias 80 --keyframes "%videoname%_fixed.mkv_keyframes.txt" --fps 23.976 --kf-before-start 294 --kf-before-end 294 --kf-after-start 294 --kf-after-end 294 -o "%scriptname%_fixed.ass"
  del "%scriptname%_tmp.ass"
 )
 if "%timefixingmode%" EQU "4" (
  py -3 tools\prass\prass.py tpp "%scriptname%_tmp.ass" --lead-in 126 --lead-out 126 --gap 378 --overlap 210 --bias 80 --keyframes "%videoname%_fixed.mkv_keyframes.txt" --fps 23.976 --kf-before-start 210 --kf-before-end 336 --kf-after-start 294 --kf-after-end 294 -o "%scriptname%_fixed.ass"
  del "%scriptname%_tmp.ass"
 )
 if "%timefixingmode%" EQU "5" (
  py -3 tools\prass\prass.py tpp "%scriptname%_tmp.ass" --lead-in 210 --gap 378 --overlap 252 --bias 30 --keyframes "%videoname%_fixed.mkv_keyframes.txt" --fps 23.976 --kf-before-start 420 --kf-before-end 1008 --kf-after-start 420 --kf-after-end 420 -o "%scriptname%_fixed.ass"
  del "%scriptname%_tmp.ass"
 )
 if "%timefixingmode%" EQU "6" (
  py -3 tools\prass\prass.py tpp "%scriptname%_tmp.ass" --lead-in 84 --lead-out 84 --gap 336 --overlap 210 --bias 60 --keyframes "%videoname%_fixed.mkv_keyframes.txt" --fps 23.976 --kf-before-start 294 --kf-before-end 336 --kf-after-start 294 --kf-after-end 336 -o "%scriptname%_fixed.ass"
  del "%scriptname%_tmp.ass"
 )
)

:NSU

:: That python script is fixing the German typographie (for exmaple: „“ instead of "")
if "%german_typographie%" EQU "y" (
 ren "%scriptname%_fixed.ass" "%scriptname%-needfix.ass"
 py -3 tools\fuehre_mich.py "%scriptname%-needfix.ass" "%scriptname%_fixed.ass"
 del "%scriptname%-needfix.ass"
)

:: That python script is fixing italic honorifics
if "%italic_honorifics%" EQU "y" (
 ren "%scriptname%_fixed.ass" "%scriptname%-needfix.ass"
 py -3 tools\funimation_honorifics.py "%scriptname%-needfix.ass" "%scriptname%_fixed.ass"
 del "%scriptname%-needfix.ass"
)

:: Muxing the subtitles and audio
:: You might want to change the "--language" or "--default-duration" here
if "%mux%" EQU "y" (
 mkvmerge -o "%videoname%_final.mkv" "%videoname%_fixed.mkv" "--sub-charset" "0:UTF-8" "--language" "0:zxx" "--track-name" "0:" "--default-track" "0:yes" "%scriptname%_fixed.ass" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "%font%" "--attach-file" "custom\%font%" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "%font2%" "--attach-file" "custom\%font2%"
 del "%videoname%_fixed.mkv"
 del "%scriptname%_fixed.ass"
)

echo Done.
PAUSE
