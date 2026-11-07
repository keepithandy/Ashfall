@echo off
setlocal
set "GODOT_DIR=%USERPROFILE%\Documents\Codex\2026-11-06\new-chat\outputs\Godot"
set "APPDATA=%GODOT_DIR%\userdata"
start "Ashfall Player Preview" "%GODOT_DIR%\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
endlocal
