@echo off
:: This script is for creating a typeset track of a full subbed subtitle
:: Keep in mind that the script isn't 100% accurate and might think some dialogues are typeset
:: It's more optimised for going safe instead of deleting real typeset by accident
REM ######################
setlocal ENABLEDELAYEDEXPANSION
echo.
echo Keep all files and this batch file in the same folder. 
echo Only set the names of them, no directory structure (paths)!
echo Just press enter for detault values.
echo Always use lowercase.
echo.
REM ######################
:: Requirements: WSL version 1 with Ubuntu / Debian / Pengwin
REM ######################
:: Change this values to your liking
set source=ass
set typo=n
set template=template_basic.ass
REM ######################

:: Extract subtitle from source
if /I "%~x1" EQU ".mkv" (
 mkvmerge.exe --ui-language en --output "%~n1_test%~x1" --no-audio --no-video --no-attachments --no-chapters "(" "%~n1%~x1" ")"
 mkvextract --ui-language en tracks "%~n1_test%~x1" 0:"%~n1.sub"
 set srcname=%~n1%~x1
 set scriptname=%~n1.sub
 del "%~n1_test%~x1"
)

if /I "%~x1" EQU ".srt" (
 ren "%~n1%~x1" "%~n1.sub"
)

if /I "%~x1" EQU ".ass" (
 ren "%~n1%~x1" "%~n1.sub"
)

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

:: Cleaning the .ass file
py -3 audio\prass\prass.py cleanup "%scriptname%_sfx.ass" --styles --empty-lines --comments -o "%scriptname%_tmp.ass"
del "%scriptname%_sfx.ass"
:: This step is important for fixing weird border upscaling with players like mpv
awk.exe "/\[Script Info\]/ { print; print \"ScaledBorderAndShadow: yes\"; next }1" "%scriptname%_tmp.ass" >"%scriptname%_sfx.ass"
del "%scriptname%_tmp.ass"


:: That python script is fixing the German typographie (for exmaple: „“ instead of "")
if "%typo%" EQU "y" (
ren "%scriptname%_sfx.ass" "%scriptname%_sfx-needfix.ass"
py -3 audio\fuehre_mich.py "%scriptname%_sfx-needfix.ass" "%scriptname%_sfx.ass"
del "%scriptname%_sfx-needfix.ass"
)

:: Renaming
py -3 audio\prass\prass.py sort "%scriptname%_sfx.ass" --by style -o "%scriptname%-sorted.ass"
del "%scriptname%_sfx.ass" 

:: Remove everything non-typeset (you might have to change and/or add stuff to it)
ren "%scriptname%-sorted.ass" "%scriptname%-type_tmp.ass"
wsl sed -i "/,Default,,/d" "%scriptname%-type_tmp.ass"
wsl sed -i "/,Overlap,,/d" "%scriptname%-type_tmp.ass"
wsl sed -i "/,Italic,,/d" "%scriptname%-type_tmp.ass"
wsl sed -i "/,Internal,,/d" "%scriptname%-type_tmp.ass"
wsl sed -i "/,Top,,/d" "%scriptname%-type_tmp.ass"
wsl sed -i "/,Flashback,,/d" "%scriptname%-type_tmp.ass"
wsl sed -i "/,Flashback Internal,,/d" "%scriptname%-type_tmp.ass"

:: Remove everything unused (again)
py -3 audio\prass\prass.py cleanup "%scriptname%-type_tmp.ass" --styles -o "%scriptname%-type.ZXX.ass"
del "%scriptname%-type_tmp.ass"

:: Deleting everything that isn't needed anymore
del "%~n1.sub"

echo Done.
PAUSE
