@echo off
:: This script is for putting TV subs from a TV show onto a Blu-ray source with correct timing
REM ######################
setlocal ENABLEDELAYEDEXPANSION
echo.
echo Keep all files and this batch file in the same folder. 
echo Only set the names of them, no directory structure (paths)!
echo Just press enter for detault values.
echo Always use lowercase.
echo.
REM ######################
set template=template_basic.ass
REM ######################
:anew
set /p srcname=TV-Source (e.g. TestTV.mkv): 
set scriptname=%srcname%
echo Leave empty when the subs are already muxed as a .ass and primary subtitle track with the TV version
set /p scriptname=TV-Subtitle (e.g. TestTV.ass): 
set /p dstname=BD-Source (e.g. TestBD.mkv): 
echo.

:: Extract subtitle from source
if "%scriptname%" EQU "%srcname%" (
mkvextract --ui-language en tracks "%srcname%" 2:"%srcname%.ass"
set scriptname=%srcname%.ass
)

:: That python script is and replacing the font
py -3 audio\prass\prass.py copy-styles --resample --from audio\template_clean.ass --to "%scriptname%" -o "%scriptname%_sfx.ass"

:: Comment this out for other languages than "German"
:: That python script is fixing the typographie (for exmaple: „“ instead of "")
:: ren "%scriptname%_sfx.ass" "%scriptname%_sfx-needfix.ass"
:: py -3 audio\fuehre_mich.py "%scriptname%_sfx-needfix.ass" "%scriptname%_sfx.ass"
:: del "%scriptname%_sfx-needfix.ass"


:: Shifting the subtitles
py -2 audio\sushi\sushi.py --src "%srcname%" --src-keyframes auto --dst "%dstname%" --dst-keyframes auto --kf-mode all --max-ts-duration 0.5 --max-ts-distance 1 --script "%scriptname%_sfx.ass" --max-kf-distance 2.5 -o "%scriptname%-sushi.ass"

:: Some additional timing fixing if sushi isn't accurate enough
REM "%scriptname%-sushi.ass" "%scriptname%-sushi2.ass"
REM py -3 audio\prass\prass.py tpp "%scriptname%-sushi2.ass" --lead-in 43 --lead-out 43 --gap 210 --overlap 126 --bias 60 --keyframes "%dstname%.sushi.keyframes.txt" --fps 23.976 --kf-before-start 210 --kf-before-end 294 --kf-after-start 294 --kf-after-end 294 -o "%scriptname%-sushi.ass"

:: Muxing the subtitles with the Blu-ray video (including fonts)
:: You might want to change the "--language" here
mkvmerge -o "%dstname%_fixed.mkv"  "--language" "0:jpn" "--default-track" "0:yes" "--language" "1:jpn" "--default-track" "1:yes" "(" "%dstname%" ")" "--no-audio" "--no-video" "--no-subtitles" "--no-chapters" "(" "%srcname%" ")" "--track-order" "0:0,0:1"
mkvmerge -o "%dstname%_final.mkv" "%dstname%_fixed.mkv" "--language" "0:ger" "--track-name" "0:Subs" "--default-track" "0:yes" "%scriptname%-sushi.ass" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "font.ttf" "--attach-file" "audio\font.ttf" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "font2.ttf" "--attach-file" "audio\font2.ttf"

:: Muxing the subtitles with the Blu-ray video (excluding fonts)
:: You might want to change the "--language" here
REM mkvmerge -o "%dstname%_final.mkv" "%dstname%" "--language" "0:ger" "--track-name" "0:Subs" "--default-track" "0:yes" "%scriptname%-sushi.ass" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "font.ttf" "--attach-file" "audio\font.ttf" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "font2.ttf" "--attach-file" "audio\font2.ttf"

:: Deleting everything that isn't needed anymore
del "%dstname%_fixed.mkv"
del "%srcname%_fixed.mkv.sushi.keyframes.txt"
del "%srcname%.sushi.keyframes.txt"
del "%dstname%.sushi.keyframes.txt"
del "%scriptname%-sushi2.ass"
del "%srcname%_fixed.mkv"
del "%scriptname%_sfx.ass"

echo Done.
goto anew
PAUSE
