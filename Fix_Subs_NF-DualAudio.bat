@echo off
:: This script is for fixing German subtitles from NF with DualAudio (timing & font).
:: For "extract=y" you need the following base as a MKV: "Video" + "Audio 1: Gerdub" + "Audio 2: Japdub" + "Sub 1: Type" + "Sub 2: Full"
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
:: Change this values to your liking
set fast=y
set extract=n
set source=srt
set sush=y
set mux=y
set typo=n
set template=template_basic.ass
set font=font1.ttf
set font2=font1i.ttf
REM ######################

:: Extract subtitle from source (only works with .srt)
if "%extract%" EQU "y" (
mkvextract --ui-language en tracks "%~1" 3:"%~n1-01.srt" 4:"%~n1-02.srt"
set videoname=%~n1.mkv
set scriptname=%~n1-01.srt
set scriptnamenew=%~n1-02.srt
goto TTT
)

set /p videoname=Video with japdub and other dubbed track (e.g. Test.mkv): 
set /p scriptname=Type-Subtitle (e.g. Test.srt): 
set /p scriptnamenew=Full-Subtitle (e.g. Test.srt): 

:TTT

if "%fast%" EQU "y" (
goto GGF
)

set /p template=Template (e.g. template.ass): 
set /p font=Normal font (e.g. font.ttf): 
set /p font2=Italic font (e.g. font2.ttf): 
set /p source=srt or ass input (e.g. ass): 
set /p sush=Run sushi (y/n): 
set /p mux=Mux everything together at the end (y/n): 

:GGF

:: A second muxing for setting the correct fps and removing audio delay - you might have to change it for non 23,976fps content
if NOT exist "%videoname%_fixed.mkv" (
 mkvmerge -o "%videoname%_fixed.mkv"  "--default-track" "0:yes"  "--default-duration" "0:24000/1001p" "--fix-bitstream-timing-information" "0:1" "-a" "1,2" "-d" "0" "-S" "-T" "(" "%videoname%" ")" "--track-order" "0:0,0:1,0:2"
)
 
if "%source%" EQU "srt" (
:: That python script is scaling the subtitles and replacing the font
 py -3 audio\prass\prass.py convert-srt "%scriptname%" --encoding utf-8 | py -3 audio\prass\prass.py copy-styles --resolution 1920x1080 --from audio\%template% -o "%scriptname%_srt.ass"
 :: That python script is detecting typeset and making it "/an8" (top)
 py -3 audio\amazon-netflix_typeset_split.py "%scriptname%_srt.ass" "%scriptname%_tmp.ass"
 del "%scriptname%_srt.ass"
  echo Converting srt to ass successful
)

if "%source%" EQU "ass" (
:: That python script is and replacing the font
py -3 audio\prass\prass.py copy-styles --resample --from audio\%template% --to "%scriptname%" -o "%scriptname%_srt.ass"
 :: That python script is detecting typeset and making it "/an8" (top)
 py -3 audio\amazon-netflix_typeset_split.py "%scriptname%_srt.ass" "%scriptname%_tmp.ass"
)

:: This step is important for fixing weird border upscaling with players like mpv
awk.exe "/\[Script Info\]/ { print; print \"ScaledBorderAndShadow: yes\"; next }1" "%scriptname%_tmp.ass" >"%scriptname%_tmp2.ass"
del "%scriptname%_tmp.ass"
ren "%scriptname%_tmp2.ass" "%scriptname%_tmp.ass"
echo Fixing border successful

:: Creating keyframes & fixing timing
if "%sush%" EQU "y" (
 if NOT exist "%videoname%_fixed.mkv_keyframes.txt" (
  echo Generate keyframes...
  ffmpeg -i "%videoname%_fixed.mkv" -f yuv4mpegpipe -vf scale=640:360 -pix_fmt yuv420p -vsync drop - | SCXvid "%videoname%_fixed.mkv_keyframes.txt"
  echo Keyframes completed.
  )
  py -3 audio\prass\prass.py tpp "%scriptname%_tmp.ass" --lead-in 84 --lead-out 84 --gap 210 --overlap 126 --bias 100 --keyframes "%videoname%_fixed.mkv_keyframes.txt" --fps 23.976 --kf-before-start 210 --kf-before-end 294 --kf-after-start 294 --kf-after-end 294    -o "%scriptname%_fixed.ass"
  del "%scriptname%_tmp.ass"
 )
)

:: A loop so it does both subtitles
if not exist "%scriptname%_fixed1.ass" (
 ren "%scriptname%_fixed.ass" "%scriptname%_fixed1.ass"
 del "%scriptname%"
 ren "%scriptnamenew%" "%scriptname%"
 goto GGF
)
del "%scriptname%"

ren "%scriptname%_fixed.ass" "%scriptname%_full.ass"
ren "%scriptname%_fixed1.ass" "%scriptname%_type.ass"

:: That python script is fixing the typographie (for exmaple: „“ instead of "")
if "%typo%" EQU "y" (
ren "%scriptname%_full.ass" "%scriptname%_full-needfix.ass"
py -3 audio\fuehre_mich.py "%scriptname%_full-needfix.ass" "%scriptname%_full.ass"
ren "%scriptname%_type.ass" "%scriptname%_type-needfix.ass"
py -3 audio\fuehre_mich.py "%scriptname%_type-needfix.ass" "%scriptname%_type.ass"
del "%scriptname%_full-needfix.ass"
del "%scriptname%_type-needfix.ass"
)

:: Muxing the subtitles and audio
:: You might want to change the "--language" or "--default-duration" here
if "%mux%" EQU "y" (
  mkvmerge -o "%videoname%_final.mkv"  "--language" "0:jpn" "--default-track" "0:yes" "--default-duration" "0:24000/1001p" "--language" "1:ger" "--default-track" "1:yes" "--language" "2:jpn" "-a" "1,2" "-d" "0" "-S" "-T" "(" "%videoname%_fixed.mkv" ")" "--sub-charset" "0:UTF-8" "--language" "0:ger"  "--track-name" "0:Full"  "--default-track" "0:no" "-s" "0" "-D" "-A" "-T" "(" "%scriptname%_full.ass" ")" "--sub-charset" "0:UTF-8" "--language" "0:gem" "--track-name" "0:Type" "--default-track" "0:yes" "-s" "0" "-D" "-A" "-T" "(" "%scriptname%_type.ass" ")" "--track-order" "0:0,0:1,0:2,1:0,2:0" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "%font%" "--attach-file" "audio\%font%" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "%font2%" "--attach-file" "audio\%font2%"
  del "%videoname%_fixed.mkv"
 )
)

del "%scriptname%_full.ass"
del "%scriptname%_type.ass"

echo Done.
PAUSE
