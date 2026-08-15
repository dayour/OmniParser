@echo off
REM ---------------------------------------------------------------------------
REM Syncs this folder's file_inventory.csv with the central docs copy.
REM
REM   sync.bat            push this folder's inventory up to docs
REM   sync.bat -Pull      refresh this folder's inventory from docs
REM   sync.bat -WhatIf    show what would transfer without copying
REM
REM %~dp0 keeps the path anchored to this file's own folder, so the launcher
REM works no matter which directory it is invoked from.
REM ---------------------------------------------------------------------------
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0docs_robocopy.ps1" %*
exit /b %ERRORLEVEL%
