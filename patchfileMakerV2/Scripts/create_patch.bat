@echo off
REM ===============================================
REM UEBA 패치 생성 간편 실행 배치 파일
REM ===============================================

chcp 65001 >nul
powershell -ExecutionPolicy Bypass -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; $PSDefaultParameterValues['*:Encoding'] = 'utf8'; & '%~dp0create_patch.ps1' %*"

