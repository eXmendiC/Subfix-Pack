@echo off
:: This script is for replacing main fonts
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
set source=ass
set extract=y
set typo=n
set mux=y
set template=template_basic.ass
set font=font1.ttf
set font2=font1i.ttf
REM ######################

:: Extract subtitle from source
if "%extract%" EQU "y" (
 mkvmerge.exe --ui-language en --output "%~n1_test%~x1" --no-audio --no-video --no-attachments --no-chapters "(" "%~n1%~x1" ")"
 mkvextract --ui-language en tracks "%~n1_test%~x1" 0:"%~n1.sub"
 set srcname=%~n1%~x1
 set scriptname=%~n1.sub
 del "%~n1_test%~x1"
 goto TTT
)

set /p srcname=Source (e.g. TestTV.mkv): 
set scriptname=%srcname%
echo Leave empty when the subs are already muxed as a .ass and primary subtitle track with the TV version
set /p scriptname=Subtitle (e.g. TestTV.ass): 
echo.

:: Extract subtitle from source
if "%scriptname%" EQU "%srcname%" (
 mkvmerge.exe --ui-language en --output "%srcname%_test.mkv" --no-audio --no-video --no-attachments --no-chapters "(" "%srcname%" ")"
 mkvextract --ui-language en tracks "%srcname%_test.mkv" 0:"%srcname%.sub"
 set scriptname=%srcname%.sub
 del "%srcname%_test.mkv"
)

:TTT

if "%source%" EQU "srt" (
:: That python script is scaling the subtitles and replacing the font
 py -3 audio\prass\prass.py convert-srt "%scriptname%" --encoding utf-8 | py -3 audio\prass\prass.py copy-styles --resolution 1920x1080 --from audio\%template% -o "%scriptname%_srt.ass"
 :: That python script is detecting typeset and making it "/an8" (top)
 py -3 audio\amazon-netflix_typeset_split.py "%scriptname%_srt.ass" "%scriptname%_sfx.ass"
 del "%scriptname%_srt.ass"
)

if "%source%" EQU "ass" (
:: That python script is and replacing the font
py -3 audio\prass\prass.py copy-styles --resample --from audio\%template% --to "%scriptname%" -o "%scriptname%_sfx.ass"
)

:: This step is important for fixing weird border upscaling with players like mpv
awk.exe "/\[Script Info\]/ { print; print \"ScaledBorderAndShadow: yes\"; next }1" "%scriptname%_sfx.ass" >"%scriptname%_tmp.ass"
del "%scriptname%_sfx.ass"
ren "%scriptname%_tmp.ass" "%scriptname%_sfx.ass"


:: That python script is fixing the German typographie (for exmaple: „“ instead of "")
if "%typo%" EQU "y" (
ren "%scriptname%_sfx.ass" "%scriptname%_sfx-needfix.ass"
py -3 audio\fuehre_mich.py "%scriptname%_sfx-needfix.ass" "%scriptname%_sfx.ass"
del "%scriptname%_sfx-needfix.ass"
)

:: Renaming
ren "%scriptname%_sfx.ass" "%scriptname%-newfont.ass"

:: Muxing the subtitles with the video
:: You might want to change the "--language" here
if "%mux%" EQU "y" (
mkvmerge -o "%srcname%_final.mkv" "%srcname%" "--language" "0:eng" "--track-name" "0:Subs" "--default-track" "0:yes" "%scriptname%-newfont.ass" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "%font%" "--attach-file" "audio\%font%" "--attachment-mime-type" "application/vnd.ms-opentype" "--attachment-name" "%font2%" "--attach-file" "audio\%font2%"
)

:: Deleting everything that isn't needed anymore
del "%srcname%.sub"
del "%~n1.sub"

echo Done.
PAUSE
