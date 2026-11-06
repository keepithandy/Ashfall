@echo off
setlocal
set "GODOT_DIR=%USERPROFILE%\Documents\Codex\2026-11-06\new-chat\outputs\Godot"
if exist "%~dp0..\Godot\Godot_v4.7.2-stable_win64.exe" set "GODOT_DIR=%~dp0..\Godot"
set "APPDATA=%GODOT_DIR%\userdata"
if not exist "%APPDATA%" mkdir "%APPDATA%"
start "Ashfall" "%GODOT_DIR%\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
endlocal
