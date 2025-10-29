@echo off
REM ===============================================
REM UEBA 패치 생성 간편 실행 배치 파일
REM ===============================================

powershell -ExecutionPolicy Bypass -File "%~dp0create_patch.ps1" %*

