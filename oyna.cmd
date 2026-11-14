@echo off
rem Oyunu bilgisayarda acar. Cift tiklayin ya da terminalde calistirin.
rem Bastan baslamak icin: oyna.cmd 1
cd /d "%~dp0"
if "%~1"=="" (
  start "" "D:\Araclar\Godot\Godot_v4.7.2-stable_win64.exe" --path .
) else (
  start "" "D:\Araclar\Godot\Godot_v4.7.2-stable_win64.exe" --path . -- --kayitsiz --bolum=%~1
)
