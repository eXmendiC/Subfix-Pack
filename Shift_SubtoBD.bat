@echo off
:: This script is for putting TV/WEB subs from a TV/WEB show onto a Blu-ray source with correct timing
REM ######################
setlocal ENABLEDELAYEDEXPANSION
echo.
echo Keep all files and this batch file in the same folder. 
echo Only set the names of them, no directory structure (paths)!
echo Just press enter for detault values.
echo Always use lowercase.
echo.
REM ######################
:: Explanation: https://iamscum.wordpress.com/guides/sushi/
REM ######################
:: Change this values to your liking
set source=ass
set timefix=n
set typo=n
set template=template_clean.ass
set tvfonts=y
set font=font1.ttf
set font2=font1i.ttf
REM ######################

:anew
echo Avoid special characters like bracket!
set /p srcname=TV-Source (e.g. TestTV.mkv): 
set scriptname=%srcname%
echo Leave empty when the subs are already muxed as a .ass and primary subtitle track with the TV version
set /p scriptname=TV-Subtitle (e.g. TestTV.ass): 
set /p dstname=BD-Source (e.g. TestBD.mkv): 
echo.

:: Extract subtitle from source
if "%scriptname%" EQU "%srcname%" (
 mkvmerge --ui-language en --output "%srcname%_test.mkv" --no-audio --no-video --no-attachments --no-chapters "(" "%srcname%" ")"
 mkvextract --ui-language en tracks "%srcname%_test.mkv" 0:"%srcname%.sub"
 set scriptname=%srcname%.sub
 del "%srcname%_test.mkv"
)

if "%source%" EQU "srt" (
:: That python script is scaling the subtitles and replacing the font
 py -3 tools\prass\prass.py convert-srt "%scriptname%" --encoding utf-8 | py -3 tools\prass\prass.py copy-styles --resolution 1920x1080 --from custom\%template% -o "%scriptname%_srt.ass"
 :: That python script is detecting typeset and making it "/an8" (top)
 py -3 tools\amazon-netflix_typeset_split.py "%scriptname%_srt.ass" "%scriptname%_sfx.ass"
 del "%scriptname%_srt.ass"
)

if "%source%" EQU "ass" (
:: That python script is and replacing the font
py -3 tools\prass\prass.py copy-styles --resample --from custom\%template% --to "%scriptname%" -o "%scriptname%_sfx.ass"
)

:: Cleaning the .ass file
py -3 tools\prass\prass.py cleanup "%scriptname%_sfx.ass" --styles --empty-lines --comments -o "%scriptname%_tmp.ass"
del "%scriptname%_sfx.ass"
:: This step is important for fixing weird border upscaling with players like mpv
awk.exe "/\[Script Info\]/ { print; print \"ScaledBorderAndShadow: yes\"; next }1" "%scriptname%_tmp.ass" >"%scriptname%_sfx.ass"
del "%scriptname%_tmp.ass"


:: That python script is fixing the German typographie (for exmaple: „“ instead of "")
if "%typo%" EQU "y" (
ren "%scriptname%_sfx.ass" "%scriptname%_sfx-needfix.ass"
py -3 tools\fuehre_mich.py "%scriptname%_sfx-needfix.ass" "%scriptname%_sfx.ass"
del "%scriptname%_sfx-needfix.ass"
)

:: Shifting the subtitles
py -2 tools\sushi\sushi.py --src "%srcname%" --src-keyframes auto --dst "%dstname%" --dst-keyframes auto --kf-mode all --window 10 --max-window 30 --sample-rate 12000 --max-ts-duration 0.5 --max-ts-distance 1 --script "%scriptname%_sfx.ass" --max-kf-distance 2.5 -o "%scriptname%-sushi.ass"

:: Some additional timing fixing
if "%timefix%" EQU "y" (
ren "%scriptname%-sushi.ass" "%scriptname%-sushi2.ass"
py -3 tools\prass\prass.py tpp "%scriptname%-sushi2.ass" --lead-in 84 --lead-out 84 --gap 336 --overlap 210 --bias 75 --keyframes "%dstname%.sushi.keyframes.txt" --fps 23.976 --kf-before-start 210 --kf-before-end 336 --kf-after-start 294 --kf-after-end 294 -o "%scriptname%-sushi.ass"
del "%scriptname%-sushi2.ass"
)

:: Muxing the subtitles with the Blu-ray video (including TV fonts)
:: You might want to change the "--language" here
if "%tvfonts%" EQU "y" (
mkvmerge -o "%dstname%_fixed.mkv"  "--language" "0:jpn" "--default-track" "0:yes" "--language" "1:jpn" "--default-track" "1:yes" "(" "%dstname%" ")" "--no-audio" "--no-video" "--no-subtitles" "--no-chapters" "(" "%srcname%" ")" "--track-order" "0:0,0:1"
mkvmerge -o "%dstname%_final.mkv" "%dstname%_fixed.mkv" "--language" "0:ger" "--track-name" "0:Subs" "--default-track" "0:yes" "%scriptname%-sushi.ass" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "%font%" "--attach-file" "custom\%font%" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "%font2%" "--attach-file" "custom\%font2%"
)

:: Muxing the subtitles with the Blu-ray video (excluding TV fonts)
:: You might want to change the "--language" here
if "%tvfonts%" EQU "n" (
mkvmerge -o "%dstname%_final.mkv" "%dstname%" "--language" "0:ger" "--track-name" "0:Subs" "--default-track" "0:yes" "%scriptname%-sushi.ass" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "%font%" "--attach-file" "custom\%font%" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "%font2%" "--attach-file" "custom\%font2%"
)

:: Deleting everything that isn't needed anymore
del "%dstname%_fixed.mkv"
del "%srcname%_fixed.mkv.sushi.keyframes.txt"
del "%srcname%.sushi.keyframes.txt"
del "%dstname%.sushi.keyframes.txt"
del "%srcname%_fixed.mkv"
del "%scriptname%_sfx.ass"
del "%srcname%.sub"

echo Done.
echo.
goto anew
