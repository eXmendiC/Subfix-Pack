@echo off
:: This script is for easy batch processing.
:: Below are some examples.
:: You have to comment out all "set /p" in the called scripts to make it work silent!
REM #################################
SET srcname=TestTV.mkv
SET dstname=TestBD.mkv
CALL Shift_AudioToBD.bat
REM #################################
SET srcname=TestTV.mkv
SET scriptname=TestTV.ass
SET dstname=TestBD.mkv
CALL Shift_SubtoBD.bat
REM #################################
SET srcname=TestTV2.mkv
SET dstname=TestBD2.mkv
CALL Shift_AudioToBD.bat
REM #################################
SET fast=y
SET extract=n
SET videoname=TestTV2.mkv
SET scriptname=TestTV.ass
CALL Fix_Subs-23.976fps.bat
REM #################################