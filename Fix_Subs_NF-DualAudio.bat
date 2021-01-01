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
:: Explanation: https://iamscum.wordpress.com/guides/prass/
REM ######################
:: Change this values to your liking
set fast=y
set extract=n
set source=srt
set timefixing=y
set mux=y
set typo=n
set template=template_basic.ass
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

echo Avoid special characters like bracket!
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
set /p timefixing=Run time fixing (y/n): 
set /p mux=Mux everything together at the end (y/n): 

:GGF

:: A second muxing for setting the correct fps and removing audio delay - you might have to change it for non 23,976fps content
if NOT exist "%videoname%_fixed.mkv" (
 mkvmerge -o "%videoname%_fixed.mkv"  "--default-track" "0:yes"  "--default-duration" "0:24000/1001p" "--fix-bitstream-timing-information" "0:1" "-a" "1,2" "-d" "0" "-S" "-T" "(" "%videoname%" ")" "--track-order" "0:0,0:1,0:2"
)
 
if "%source%" EQU "srt" (
:: That python script is scaling the subtitles and replacing the font
 py -3 tools\prass\prass.py convert-srt "%scriptname%" --encoding utf-8 | py -3 tools\prass\prass.py copy-styles --resolution 1920x1080 --from custom\%template% -o "%scriptname%_srt.ass"
 :: That python script is detecting typeset and making it "/an8" (top)
 py -3 tools\amazon-netflix_typeset_split.py "%scriptname%_srt.ass" "%scriptname%_tmp.ass"
 del "%scriptname%_srt.ass"
  echo Converting srt to ass successful
)

if "%source%" EQU "ass" (
:: That python script is and replacing the font
py -3 tools\prass\prass.py copy-styles --resample --from custom\%template% --to "%scriptname%" -o "%scriptname%_srt.ass"
 :: That python script is detecting typeset and making it "/an8" (top)
 py -3 tools\amazon-netflix_typeset_split.py "%scriptname%_srt.ass" "%scriptname%_tmp.ass"
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
  py -3 tools\prass\prass.py tpp "%scriptname%_tmp.ass" --lead-in 128 --lead-out 128 --gap 378 --overlap 210 --bias 80 --keyframes "%videoname%_fixed.mkv_keyframes.txt" --fps 23.976 --kf-before-start 210 --kf-before-end 336 --kf-after-start 294 --kf-after-end 294    -o "%scriptname%_fixed.ass"
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
py -3 tools\fuehre_mich.py "%scriptname%_full-needfix.ass" "%scriptname%_full.ass"
ren "%scriptname%_type.ass" "%scriptname%_type-needfix.ass"
py -3 tools\fuehre_mich.py "%scriptname%_type-needfix.ass" "%scriptname%_type.ass"
del "%scriptname%_full-needfix.ass"
del "%scriptname%_type-needfix.ass"
)

:: Muxing the subtitles and audio
:: You might want to change the "--language" or "--default-duration" here
if "%mux%" EQU "y" (
  mkvmerge -o "%videoname%_final.mkv"  "--language" "0:jpn" "--default-track" "0:yes" "--default-duration" "0:24000/1001p" "--language" "1:ger" "--default-track" "1:yes" "--language" "2:jpn" "-a" "1,2" "-d" "0" "-S" "-T" "(" "%videoname%_fixed.mkv" ")" "--sub-charset" "0:UTF-8" "--language" "0:ger"  "--track-name" "0:Full"  "--default-track" "0:no" "-s" "0" "-D" "-A" "-T" "(" "%scriptname%_full.ass" ")" "--sub-charset" "0:UTF-8" "--language" "0:gem" "--track-name" "0:Type" "--default-track" "0:yes" "-s" "0" "-D" "-A" "-T" "(" "%scriptname%_type.ass" ")" "--track-order" "0:0,0:1,0:2,1:0,2:0" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "%font%" "--attach-file" "custom\%font%" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "%font2%" "--attach-file" "custom\%font2%"
  del "%videoname%_fixed.mkv"
 )
)

del "%scriptname%_full.ass"
del "%scriptname%_type.ass"

echo Done.
PAUSE
