@echo off
:: This script is for fixing German & English subtitles from AMZ (timing & font) + 2nd video (HEVC).
:: For "extract=y" doesn't exist here
:: For other languages than German & English the script needs a bit tweaking (see the comments below)
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
set source=srt
set timefixing=y
set mux=y
set typo=y
set template=template_basic.ass
set font=font1.ttf
set font2=font1i.ttf
REM ######################

set /p videoname=Video (e.g. Test.mkv): 
set /p videoname_hevc=Video (e.g. Test2.mkv): 
set /p scriptname=GER-Subtitle (e.g. Test_de-de.srt): 
set /p scriptnamenew=ENG-Subtitle (e.g. Test_en-gb.srt): 

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
 mkvmerge -o "%videoname%_fixed.mkv"  "--default-track" "0:yes"  "--default-duration" "0:24000/1001p" "--fix-bitstream-timing-information" "0:1" "-a" "1" "-d" "0" "-S" "-T" "(" "%videoname%" ")" "--track-order" "0:0,0:1"
)

if NOT exist "%videoname_hevc%_fixed.mkv" (
 mkvmerge -o "%videoname_hevc%_fixed.mkv"  "--default-track" "0:yes"  "--default-duration" "0:24000/1001p" "--fix-bitstream-timing-information" "0:1" "-a" "1" "-d" "0" "-S" "-T" "(" "%videoname_hevc%" ")" "--track-order" "0:0,0:1"
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
if "%timefixing%" EQU "y" (
 if NOT exist "%videoname%_fixed.mkv_keyframes.txt" (
  echo Generate keyframes...
  ffmpeg -i "%videoname%_fixed.mkv" -f yuv4mpegpipe -vf scale=640:360 -pix_fmt yuv420p -vsync drop - | SCXvid "%videoname%_fixed.mkv_keyframes.txt"
  echo Keyframes completed.
  )
  py -3 audio\prass\prass.py tpp "%scriptname%_tmp.ass" --lead-in 84 --lead-out 84 --gap 462 --overlap 252 --bias 80 --keyframes "%videoname%_fixed.mkv_keyframes.txt" --fps 23.976 --kf-before-start 210 --kf-before-end 294 --kf-after-start 294 --kf-after-end 294    -o "%scriptname%_fixed.ass"
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

ren "%scriptname%_fixed.ass" "%scriptname%_eng.ass"
ren "%scriptname%_fixed1.ass" "%scriptname%_ger.ass"

:: That python script is fixing the German typographie (for exmaple: „“ instead of "")
if "%typo%" EQU "y" (
ren "%scriptname%_ger.ass" "%scriptname%_ger-needfix.ass"
py -3 audio\fuehre_mich.py "%scriptname%_ger-needfix.ass" "%scriptname%_ger.ass"
del "%scriptname%_ger-needfix.ass"
)

:: Muxing the subtitles and audio
:: You might want to change the "--language" or "--default-duration" here
if "%mux%" EQU "y" (
  mkvmerge -o "%videoname%_final.mkv"  "--language" "0:jpn" "--default-track" "0:yes" "--default-duration" "0:24000/1001p" "--language" "1:jpn" "--default-track" "1:yes" "-a" "1" "-d" "0" "-S" "-T" "(" "%videoname%_fixed.mkv" ")" "--sub-charset" "0:UTF-8" "--language" "0:ger"  "--track-name" "0:Deutsch"  "--default-track" "0:yes" "-s" "0" "-D" "-A" "-T" "(" "%scriptname%_ger.ass" ")" "--sub-charset" "0:UTF-8" "--language" "0:eng" "--track-name" "0:English" "--default-track" "0:no" "-s" "0" "-D" "-A" "-T" "(" "%scriptname%_eng.ass" ")" "--track-order" "0:0,0:1,1:0,2:0" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "%font%" "--attach-file" "audio\%font%" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "%font2%" "--attach-file" "audio\%font2%"
  mkvmerge -o "%videoname_hevc%_final.mkv"  "--language" "0:jpn" "--default-track" "0:yes" "--default-duration" "0:24000/1001p" "--language" "1:jpn" "--default-track" "1:yes" "-a" "1" "-d" "0" "-S" "-T" "(" "%videoname_hevc%_fixed.mkv" ")" "--sub-charset" "0:UTF-8" "--language" "0:ger"  "--track-name" "0:Deutsch"  "--default-track" "0:yes" "-s" "0" "-D" "-A" "-T" "(" "%scriptname%_ger.ass" ")" "--sub-charset" "0:UTF-8" "--language" "0:eng" "--track-name" "0:English" "--default-track" "0:no" "-s" "0" "-D" "-A" "-T" "(" "%scriptname%_eng.ass" ")" "--track-order" "0:0,0:1,1:0,2:0" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "%font%" "--attach-file" "audio\%font%" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "%font2%" "--attach-file" "audio\%font2%"
  del "%videoname%_fixed.mkv"
  del "%ideoname_hevc%_fixed.mkv"
 )
)

del "%scriptname%_eng.ass"
del "%scriptname%_ger.ass"

echo Done.
PAUSE
